module GraphQL
  # An error raised when a GraphQL request fails.
  class Error < StandardError
    # @param message [String] what the API said went wrong.
    # @param data [Hash, nil] what it answered alongside, where it answered anything: an API that
    #   refuses one field of a query and fulfils the rest sends both at once.
    def initialize(message = nil, data: nil)
      super message
      @data = data
    end

    # @return [Hash, nil] what came back beside the refusal, nil where nothing did.
    attr_reader :data
  end
end
