module Jbr
  class Mock::URL < URL
    def self.for(_)
      Jbr.mock.oauth_url
    end
  end
end
