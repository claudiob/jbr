module Jbr
  # What an app under test wants Jobber to answer.
  class Mock
    # The canned answers, each read by the matching Mock resource.
    attr_accessor :quote, :job, :invoice, :request, :visits, :oauth_url, :oauth_error
  end
end
