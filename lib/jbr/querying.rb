module Jbr
  # What credentials do with a statement: post it to Jobber, refresh a stale token once, and
  # raise every refusal as a {Error} so a caller rescues one class.
  module Querying
    # Where every query and mutation is posted.
    ENDPOINT = 'https://api.getjobber.com/api/graphql'

    # The version of the schema every statement is written against.
    HEADERS = { 'X-JOBBER-GRAPHQL-VERSION' => '2026-04-22' }

    # How Jobber says the grant does not cover what was asked for: `An object of type User was
    # hidden due to permissions`. It codes this one not at all, so the words are the only signal
    # there is, and it names the type in them. An app granted its scopes before a reader existed
    # would break on every query carrying that reader; this way it carries on a field short.
    HIDDEN = /hidden due to permissions/

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
    # @return [Hash] data Jobber answered: empty where the credentials are dead, and short of
    #   whatever the grant does not cover, which Jobber hides rather than answers.
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
      raise Error, error.message unless error.message.match? HIDDEN

      Jbr.logger.warn 'Jobber hid what this app is not granted. Tick the scope for the type it ' \
                      "names and have the account authorize again. #{error.message}"
      error.data.to_h
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
