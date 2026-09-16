module Jbr
  # What a list of visits writes. Jobber files the stop booked to go and look at work as an
  # assessment on the request it is opened with, so one mutation files the lead, the hour and
  # the crew, and answers the stop as Jobber stored it rather than as it was asked for.
  module Booking
    # The mutation that opens a request with an assessment booked on it.
    CREATE = <<~GRAPHQL
      mutation($input: RequestCreateInput!) {
        requestCreate(input: $input) {
          request { id client { id } assessment { id title startAt endAt allDay } }
          userErrors { message }
        }
      }
    GRAPHQL

    # Books a stop against the client answering to the phone and the property at the address,
    # opening either where Jobber has none. Jobber has no source for a request, so that one is
    # dropped, and it takes the hour in the technician's own words, so `starts_at:` must know
    # the zone it is in: a bare Time names no zone and is refused.
    # @return [Visit] stop as Jobber booked it, naming the lead it was booked against.
    def create(name:, surname:, phone:, email:, address:, description:, notes:, source:,
      starts_at:, ends_at:, technicians:)
      booking = schedule starts_at, ends_at, technicians
      customer = Customers.new(account: @account).find_or_create_by phone: phone, name: name,
        surname: surname, email: email, address: address
      property = Locations.new(account: @account).find_or_create_for customer, address
      booked @account.query(CREATE, variables: { input: {
        clientId: customer.id, propertyId: property, title: description,
        assessment: { instructions: notes, schedule: booking },
      } })
    end

  private

    def booked(output)
      request = output.dig 'requestCreate', 'request'
      lead = { 'id' => request['id'], 'client' => request['client'] }
      Visit.new node: request.fetch('assessment').merge('request' => lead)
    end

    def schedule(starts_at, ends_at, technicians)
      { startAt: moment(starts_at), endAt: (moment(ends_at) if ends_at),
        teamMemberIdsToAssign: technicians.map(&:id), }.compact
    end

    def moment(at)
      { date: at.strftime('%Y-%m-%d'), time: at.strftime('%H:%M:%S'), timezone: zone_of(at) }
    end

    def zone_of(at)
      return at.time_zone.tzinfo.name if at.respond_to? :time_zone

      raise Error, "Jobber books #{at} in a named zone: hand over a Time.zone moment, not a Time"
    end
  end
end
