module Jbr
  module Mocking
    def mock
      @mock ||= Jbr::Mock.new
    end

    def create_oauth(params = {})
      (@mock ? Mock::OAuth : OAuth).create **params
    end

    def oauth_url_for(params = {})
      (@mock ? Mock::URL : URL).for **params
    end

    def oauth_for(params = {})
      (@mock ? Mock::OAuth : OAuth).new params
    end
  end

  extend Mocking
end