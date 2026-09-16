module GraphQL
  # An error raised when a GraphQL request fails.
  class Error < StandardError
    # @param message [String] what the API said went wrong.
    # @param codes [Array<String>] the `extensions.code` it named each refusal by, where it named
    #   any: what a caller tells one kind of refusal from another by, without reading prose.
    def initialize(message = nil, codes: [])
      super message
      @codes = codes
    end

    # @return [Array<String>] every code the API named the refusal by, empty where it named none.
    attr_reader :codes
  end
end
