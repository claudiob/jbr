module Jbr
  class Request < Resource
    CREATE = <<~GRAPHQL.freeze
      mutation($input: RequestCreateInput!) {
        requestCreate(input: $input) { request { id property { id } } userErrors { message } }
      }
    GRAPHQL

    attr_reader :client_id

    # Create a lead in Jobber associated to a new or existing client, matched by phone.
    # @return [String] the ID of the newly created lead.
    # @param params [Hash] the attributes of the lead
    # @option params [String] :first_name the client’s first name
    # @option params [String] :last_name the client’s last name
    # @option params [String] :phone the client’s phone number
    # @option params [<String, nil>] :email the client’s email address
    # @option params [String] :title the reason why the lead is created
    # @option params [String] :instructions a comment about the lead
    def create(params = {})
      client = @oauth.clients.create_with(params).find_or_create_by(phone: params[:phone])
      @client_id = client.id
      @property_id = client.property_id

      input = {
        clientId: @client_id, title: params[:title], propertyId: @property_id,
        assessment: { instructions: params[:instructions] }
      }
      output = @oauth.query CREATE, variables: { input: input }
      @id = output.dig 'requestCreate', 'request', 'id'
      self
    end
  end
end
