module Jbr
  # What an app under test wants Jobber to answer, by the vocabulary's names.
  class Mock
    # The canned answers, each read by the matching mock collection.
    attr_accessor :business, :quote, :job, :invoice, :lead, :jobs, :visits, :technicians,
      :oauth_url, :oauth_error
  end

  class << self
    # Touching it once turns every account over to its mock counterpart.
    # @return [Mock] answers this process gives, created on first use.
    def mock = @mock ||= Mock.new

    # @return [Boolean] whether an app under test has switched Jobber off.
    def mocked? = !@mock.nil?

    # Set to nil, hands the accounts back to Jobber.
    # @return [Mock, nil] answers this process gives.
    attr_writer :mock
  end
end
