module Jbr
  class Client < Resource
    LOOKUP = <<~GRAPHQL.freeze
      query($searchTerm: String!) {
        clientPhones(first: 1, searchTerm: $searchTerm) { nodes {
          client { id updatedAt clientProperties { nodes { id address { street city province postalCode } }} }
        } }
      }
    GRAPHQL

    CREATE = <<~GRAPHQL.freeze
      mutation($input: ClientCreateInput!) {
        clientCreate(input: $input) {
          client { id clientProperties(first: 1) { nodes { id } } }
          userErrors { message }
        }
      }
    GRAPHQL

    CREATE_PROPERTY = <<~GRAPHQL.freeze
      mutation propertyCreateMutation($clientId: EncodedId!, $input: PropertyCreateInput!) {
        propertyCreate(clientId: $clientId, input: $input) {
          properties { id }
          userErrors { message }
        }
      }
    GRAPHQL

    attr_reader :property_id

    # Create a client instance with the provided attributes.
    # @return [Client] itself
    # @param params [Hash] the attributes of the client
    # @option params [String] :first_name the client’s first name
    # @option params [String] :last_name the client’s last name
    # @option params [String] :phone the client’s phone number
    # @option params [<String, nil>] :email the client’s email address
    def create_with(params = {})
      self.tap { @create_params = params }
    end

    def find_or_create_by(phone:)
      find_by_phone(phone) || create
      self
    end

  private

    def find_by_phone(phone)
      output = @oauth.query LOOKUP, variables: { searchTerm: phone }
      recent = (output.dig('clientPhones', 'nodes') || []).max_by do |clients|
        clients.dig('client', 'updatedAt') || ''
      end
      return unless recent

      @id = recent.dig 'client', 'id'

      properties = recent.dig('client', 'clientProperties', 'nodes') || []
      existing_property = properties.find do |property|
        extract_address_from(@create_params[:address]).stringify_keys == property['address']
      end
      @property_id = if existing_property
        existing_property['id']
      else
        property = @oauth.query CREATE_PROPERTY, variables: { clientId: @id, input: { properties: [ { address: extract_address_from(@create_params[:address]) }] } }
        (property&.dig('propertyCreate', 'properties')&.first || {})['id']
      end
      true
    end

    def create
      output = @oauth.query CREATE, variables: { input: input }
      @id = output.dig 'clientCreate', 'client', 'id'

      properties = output.dig 'clientCreate', 'client', 'clientProperties', 'nodes'
      @property_id = (properties.first || {})['id']
    end

    def input
      { firstName: @create_params[:first_name],
        lastName: @create_params[:last_name],
        properties: ([{ address: extract_address_from(@create_params[:address]) }] if @create_params[:address].present?),
        phones: [{ number: @create_params[:phone], primary: true }],
        emails: ([{ address: @create_params[:email], primary: true }] if @create_params[:email].present?)
      }.compact
    end

    def extract_address_from(fields = {})
      {
        street1: fields[:street], city: fields[:city],
        province: fields[:state], postalCode: fields[:zip]
      }.compact
    end
  end
end
