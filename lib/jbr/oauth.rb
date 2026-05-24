module Jbr
  class OAuth
    DISCONNECT_MUTATION = <<~GRAPHQL.freeze
      mutation Disconnect {
        appDisconnect {
          app { name author }
          userErrors { message }
        }
      }
    GRAPHQL

    def initialize(credentials = {})
      @access_token = credentials[:access_token]
      @refresh_token = credentials[:refresh_token]
      @expires_at = credentials[:expires_at]
      @account_id = credentials[:account_id]
      @invalid_at = credentials[:invalid_at]
    end

    attr_reader :access_token, :refresh_token, :expires_at, :invalid_at
    attr_accessor :account_id

    def account = Account.new oauth: self
    def clients = Client.new oauth: self
    def invoices = Invoice.new oauth: self
    def jobs = Job.new oauth: self
    def quotes = Quote.new oauth: self
    def requests = Request.new oauth: self

    def query(statement, variables: {})
      client.query statement, variables: variables
    rescue GraphQL::Unauthorized => e
      refresh ? retry : {}
    end

    # Delete a token. If the token is invalid, do nothing.
    def delete
      client.query DISCONNECT_MUTATION
    rescue GraphQL::Unauthorized => e
    end

    def self.create(code:, redirect_uri:)
      credentials = post code: code, redirect_uri: redirect_uri, grant_type: 'authorization_code'
      new(credentials).tap { |oauth| oauth.account_id = oauth.account.id }
    end

  private

    def refresh
      output = self.class.post refresh_token: @refresh_token, grant_type: 'refresh_token'
      @access_token = output[:access_token]
      @refresh_token = output[:refresh_token]
      @expires_at = output[:expires_at]
    rescue Error => e
      @invalid_at = Time.current
      false
    end

    def self.post(params = {})
      uri = URI 'https://api.getjobber.com/api/oauth/token'
      response = Net::HTTP.post_form uri, params.merge(client_id: client_id, client_secret: client_secret)
      raise Error, response.body unless response.is_a? Net::HTTPSuccess
      output = JSON.parse(response.body)
      { access_token: output['access_token'], refresh_token: output['refresh_token'],
        expires_at: (Time.current + output.fetch('expires_in', 3600).to_i) }
    end

    def self.client_id = ENV['JOBBER_CLIENT_ID']

    def self.client_secret = ENV['JOBBER_CLIENT_SECRET']

    def client
      GraphQL::Client.new endpoint: 'https://api.getjobber.com/api/graphql', token: @access_token, headers: headers
    end

    def headers = { 'X-JOBBER-GRAPHQL-VERSION' => '2026-04-22' }
  end
end
