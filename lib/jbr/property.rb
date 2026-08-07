module Jbr
  # Where the work happens: one address on a client's file.
  class Property < Resource
    # The mutation that adds a property to a client already on file.
    CREATE = <<~GRAPHQL
      mutation propertyCreateMutation($clientId: EncodedId!, $input: PropertyCreateInput!) {
        propertyCreate(clientId: $clientId, input: $input) {
          properties { id }
          userErrors { message }
        }
      }
    GRAPHQL

    # What Jobber calls each address field, against what a caller passes.
    FIELDS = { street1: :street, city: :city, province: :state, postalCode: :zip }

    # The fields a match is made on. City and state are written but never matched:
    # Jobber holds whatever was typed, so "NC" and "North Carolina" -- or "Winston Salem"
    # and "Winston-Salem" -- would read as two homes. The ZIP already places the home.
    MATCHED = %i[street1 postalCode]

    # The address as Jobber takes it, from the fields a caller passes.
    # @param fields [Hash] any of :street, :city, :state and :zip.
    # @return [Hash] the address, without the fields the caller left out.
    def self.address_from(fields = {})
      FIELDS.to_h { |jobber, ours| [ jobber, fields[ours] ] }.compact
    end

    # The address fields a caller passes, from the address as Jobber holds it.
    # @param address [Hash, nil] the address Jobber answered, if it answered one.
    # @return [Hash] any of :street, :city, :state and :zip, without the ones Jobber left out.
    def self.fields_from(address)
      FIELDS.to_h { |jobber, ours| [ ours, (address || {})[jobber.to_s] ] }.compact
    end

    # Reach the property at an address, adding one when none of the client's matches.
    # @param client_id [String] the client the property belongs to.
    # @param address [Hash] the fields the work happens at.
    # @param existing [Array<Hash>] the properties already on the client's file.
    # @return [String, nil] the property ID.
    def find_or_create_for(client_id:, address:, existing: [])
      wanted = self.class.address_from address
      match = existing.find { |property| same_address? wanted, property['address'] }
      return match['id'] if match

      output = @oauth.query CREATE, variables: {
        clientId: client_id, input: { properties: [ { address: wanted } ] },
      }
      (output&.dig('propertyCreate', 'properties')&.first || {})['id']
    end

  private

    # Field by field, because Jobber answers every field it was asked for, nil included,
    # while a caller's address carries only what they had -- an absent field and a nil
    # one are the same address. All of {MATCHED} has to agree: a home with no street
    # parsed must not match the one house on the client's file that does have one.
    def same_address?(wanted, address)
      MATCHED.all? { |field| wanted[field] == (address || {})[field.to_s] }
    end
  end
end
