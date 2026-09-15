module Jbr
  # Credentials that answer from {Jbr.mock} instead of Jobber.
  class Mock::Account < Account
    # @return [Company::Business] business the app named, under `account-01` where it named
    #   no ID.
    def business = Company::Business.new node: { id: 'account-01' }.merge(Jbr.mock.business.to_h)

    # @return [Mock::Jobs] jobs the app listed.
    def jobs = Mock::Jobs.new account: self

    # @return [Mock::Visits] visits the app listed.
    def visits = Mock::Visits.new account: self

    # @return [Mock::Technicians] technicians the app listed.
    def technicians = Mock::Technicians.new account: self

    # @return [Mock::Quotes] the one quote the app named.
    def quotes = Mock::Quotes.new

    # @return [Mock::Leads] the one lead the app named.
    def leads = Mock::Leads.new

    # @return [Mock::Invoices] the one invoice the app named.
    def invoices = Mock::Invoices.new

    # Revoking a mocked token asks nobody.
    def delete; end

    # @return [Hash] canned credentials, unless the app asked for a refusal.
    def self.post(_)
      raise Error, Jbr.mock.oauth_error if Jbr.mock.oauth_error

      { access_token: 'mock-token', refresh_token: 'mock-token', expires_at: Time.now + 3600 }
    end
  end
end
