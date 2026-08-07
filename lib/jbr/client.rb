module Jbr
  # A person a Jobber user works for, and the property the work happens at.
  class Client < Resource
    # The query that finds a client by phone, with the properties already on file.
    LOOKUP = <<~GRAPHQL
      query($searchTerm: String!) {
        clientPhones(first: 1, searchTerm: $searchTerm) { nodes {
          client { id updatedAt clientProperties { nodes { id address { #{Property::SELECTION} } }} }
        } }
      }
    GRAPHQL

    # The mutation that opens a client, with a first property when an address is given.
    CREATE = <<~GRAPHQL
      mutation($input: ClientCreateInput!) {
        clientCreate(input: $input) {
          client { id clientProperties(first: 1) { nodes { id } } }
          userErrors { message }
        }
      }
    GRAPHQL

    # @return [String, nil] the property the work happens at.
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

    # Reach the client behind a phone number, opening one if Jobber has none.
    # @param phone [String] the number to match on.
    # @return [Client] itself.
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
      @property_id = Property.new(oauth: @oauth).find_or_create_for client_id: @id,
        address: @create_params[:address],
        existing: recent.dig('client', 'clientProperties', 'nodes') || []
      true
    end

    def create
      output = @oauth.query CREATE, variables: { input: input }
      @id = output.dig 'clientCreate', 'client', 'id'

      properties = output.dig('clientCreate', 'client', 'clientProperties', 'nodes') || []
      @property_id = (properties.first || {})['id']
    end

    def input
      address, email = @create_params[:address], @create_params[:email]
      { firstName: @create_params[:first_name],
        lastName: @create_params[:last_name],
        properties: ([ { address: Property.address_from(address) } ] if present?(address)),
        phones: [ { number: @create_params[:phone], primary: true } ],
        emails: ([ { address: email, primary: true } ] if present?(email)),
      }.compact
    end

    def present?(value) = !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
  end
end
