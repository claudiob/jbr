module Jbr
  class URL
    def self.for(params = {})
      uri = URI 'https://api.getjobber.com/api/oauth/authorize'
      uri.query ||= params.merge(response_type: 'code', client_id: client_id).to_query
      uri.to_s
    end

  private

    def self.client_id = ENV['JOBBER_CLIENT_ID']
  end
end
