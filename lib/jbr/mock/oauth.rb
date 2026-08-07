module Jbr
  # Credentials that answer from {Jbr.mock} instead of Jobber.
  class Mock::OAuth < OAuth
    # The mocked resources these credentials read and write.
    def invoices = Mock::Invoice.new(oauth: self)
    def jobs = Mock::Job.new(oauth: self)
    def quotes = Mock::Quote.new(oauth: self)
    def requests = Mock::Request.new(oauth: self)
    def account = Mock::Account.new oauth: self
    def visits = Mock::Visit.new(oauth: self)

    # Revoking a mocked token asks nobody.
    def delete; end

    # @return [Hash] canned credentials, unless the app asked for a refusal.
    def self.post(_)
      raise Error, Jbr.mock.oauth_error if Jbr.mock.oauth_error

      { access_token: 'mock-token', refresh_token: 'mock-token', expires_at: (Time.now + 3600) }
    end
  end
end
