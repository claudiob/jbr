module Jbr
  # Credentials for one Jobber account, and the gateway to all they read or write.
  class Account < Company::Account
    include Querying, Refreshing
    extend Authorizing

    # The query that reads the business behind the credentials, by the keys the vocabulary reads.
    BUSINESS = "{ account { #{Company::Business.node_keys.join ' '} } }"

    # Answers from {Jbr.mock} instead of Jobber once an app under test has touched it.
    # @param credentials [Hash] see {#initialize}.
    # @return [Account] credentials, mocked where the app asked for that.
    def self.new(credentials = {})
      Jbr.mocked? && self == Account ? Mock::Account.new(credentials) : super
    end

    # @param credentials [Hash] the tokens, their expiry, the account, when it went bad, and
    #   the `store:` these are kept in, where processes share them. See {Refreshing}.
    def initialize(credentials = {})
      @access_token = credentials[:access_token]
      @refresh_token = credentials[:refresh_token]
      @expires_at = credentials[:expires_at]
      @invalid_at = credentials[:invalid_at]
      @account_id = credentials[:account_id]
      @store = credentials[:store]
    end

    # The credentials as Jobber last gave them, plus the moment a refusal to refresh landed.
    attr_reader :access_token, :refresh_token, :expires_at, :invalid_at

    # @return [String, nil] ID of the account these credentials reach.
    attr_accessor :account_id

    # @return [Company::Business] business the credentials belong to, read from Jobber.
    def business = Company::Business.new node: query(BUSINESS).fetch('account', {})

    # @return [Jobs] jobs of the business.
    def jobs = Jobs.new account: self

    # @return [Visits] visits of the business.
    def visits = Visits.new account: self

    # @return [Technicians] users of the business, which reading costs the `read_users` scope.
    def technicians = Technicians.new account: self

    # @return [Quotes] quotes of the business, which Jobber alone lists.
    def quotes = Quotes.new account: self

    # @return [Leads] leads of the business.
    def leads = Leads.new account: self

    # @return [Invoices] invoices of the business, which Jobber alone answers for.
    def invoices = Invoices.new account: self
  end
end
