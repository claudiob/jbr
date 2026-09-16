module Jbr
  # What credentials do with a statement: post it to Jobber, refresh a stale token once, and
  # raise every refusal as a {Error} so a caller rescues one class.
  module Querying
    # Where every query and mutation is posted.
    ENDPOINT = 'https://api.getjobber.com/api/graphql'

    # The version of the schema every statement is written against.
    HEADERS = { 'X-JOBBER-GRAPHQL-VERSION' => '2026-04-22' }

    # How Jobber names a refusal to answer for what the grant does not cover. It refuses the
    # whole statement rather than leaving the one field empty, so an app granted its scopes
    # before a reader existed would break on every query carrying that reader. Answering nothing
    # keeps it working, a field short and saying so. Anything Jobber names otherwise still
    # raises: a refusal nobody recognises is not one to carry on from.
    UNGRANTED = %w[UNAUTHORIZED FORBIDDEN INSUFFICIENT_SCOPE].freeze

    # The mutation that revokes the app on the account.
    DISCONNECT = <<~GRAPHQL
      mutation Disconnect {
        appDisconnect {
          app { name author }
          userErrors { message }
        }
      }
    GRAPHQL

    # Nothing here ever sleeps: where Jobber holds the app to a limit it says so, and a caller
    # asking from a background job has a queue that will bring the whole job back later.
    # @param statement [String] query or mutation to run.
    # @param variables [Hash] what the statement takes.
    # @return [Hash] data Jobber answered, or empty where the credentials are dead or the grant
    #   does not cover what was asked for.
    # @raise [Throttled] where Jobber refused the statement for what it costs.
    # @raise [Error] where Jobber refused the statement, or took a mutation and would not act.
    def query(statement, variables: {})
      data = client.query statement, variables: variables
      refusals = user_errors(data).map { |error| error['message'] }
      raise Error, refusals.join('; ') if refusals.any?

      data
    rescue GraphQL::Unauthorized
      refresh ? retry : {}
    rescue GraphQL::Throttled => error
      raise Throttled, error.message
    rescue GraphQL::Error => error
      raise Error, error.message if (error.codes & UNGRANTED).empty?

      Jbr.logger.warn "Jobber answered nothing: the app is not granted what it asked for. " \
                      "Tick the scope it names and have the account authorize again. #{error.message}"
      {}
    end

    # Revoke the credentials on the account. Dead ones have nothing left to revoke.
    def delete
      client.query DISCONNECT
    rescue GraphQL::Unauthorized
    end

  private

    def client = GraphQL::Client.new endpoint: ENDPOINT, token: @access_token, headers: HEADERS

    def user_errors(data)
      fields = data.each_value.select { |field| field.is_a? Hash }
      fields.flat_map { |field| Array(field['userErrors']) }
    end
  end
end
