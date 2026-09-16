require 'json'
require 'net/http'

# A minimal GraphQL client used to talk to third-party APIs.
module GraphQL
  # An HTTP wrapper that posts queries to a GraphQL endpoint and returns the `data` payload.
  class Client
    # @param endpoint [String] the GraphQL endpoint URL.
    # @param token [String] the bearer access token used to authorize the request.
    # @param headers [Hash] any extra headers required by the API (e.g. a version pin).
    def initialize(endpoint:, token:, headers: {})
      @endpoint = URI endpoint
      @token = token
      @headers = headers
    end

    # @param query [String] the GraphQL query string.
    # @param variables [Hash] the variables to interpolate into the query.
    # @return [Hash] the `data` portion of the GraphQL response.
    def query(query, variables: {})
      response = Net::HTTP.post @endpoint, { query:, variables: }.to_json, request_headers
      raise Unauthorized, response.body if response.code == '401'
      raise Error, response.body unless response.is_a? Net::HTTPSuccess
      body = JSON.parse(response.body)
      raise refusal_for(body) if body['errors'].present?
      body.fetch('data')
    end

  private

    def refusal_for(body)
      cost = body['extensions'].to_h['cost'].to_h
      available = cost['throttleStatus'].to_h['currentlyAvailable']
      coded = body['errors'].any? { |error| error.to_h.dig('extensions', 'code') == 'THROTTLED' }
      priced = available && cost['requestedQueryCost'].to_f > available.to_f

      (coded || priced ? Throttled : Error).new refusal(body), data: body['data']
    end

    def refusal(body)
      message = body['errors'].map { |error| error['message'] }.join '; '
      cost = body['extensions'].to_h['cost'].to_h
      status = cost['throttleStatus'].to_h
      return message if status.empty?

      "#{message} (cost #{cost['requestedQueryCost']}, #{status['currentlyAvailable']} of " \
        "#{status['maximumAvailable']} available, restoring #{status['restoreRate']}/s)"
    end

    def request_headers
      { 'Authorization' => "Bearer #{@token}", 'Content-Type' => 'application/json' }.merge @headers
    end
  end
end
