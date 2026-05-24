module Jbr
  class Mock::OAuth < OAuth
    def invoices = Mock::Invoice.new(oauth: self)
    def jobs = Mock::Job.new(oauth: self)
    def quotes = Mock::Quote.new(oauth: self)
    def requests = Mock::Request.new(oauth: self)
    def account = Mock::Account.new oauth: self

    def delete; end

  private

    def self.post(_)
      raise Error, error: Jbr.mock.oauth_error if Jbr.mock.oauth_error

      { access_token: 'mock-token', refresh_token: 'mock-token', expires_at: (Time.current + 3600) }
    end
  end
end
