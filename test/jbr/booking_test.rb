require 'test_helper'
require 'active_support/core_ext/time/zones'

# Jobber files the stop booked to go and look at work as an assessment on the request it is
# opened with, so one mutation files the lead, the hour and the crew.
class BookingTest < Minitest::Test
  ADDRESS = { street: '1 Main St', city: 'Newark', state: 'NJ', zip: '07102' }

  # The address as Jobber echoes it back on a property.
  STORED = { 'street1' => '1 Main St', 'city' => 'Newark', 'postalCode' => '07102' }

  def setup
    stub_graphql 'clientPhones' => { 'nodes' => [ { 'client' => {
      'id' => 'client-01', 'updatedAt' => '2026-06-01',
      'clientProperties' => { 'nodes' => [ { 'id' => 'property-01', 'address' => STORED } ] },
    } } ] }
    stub_request(:post, GRAPHQL_URL).with(body: /requestCreate/).to_return body: { data: {
      'requestCreate' => { 'request' => {
        'id' => 'request-01', 'client' => { 'id' => 'client-01' },
        'assessment' => { 'id' => 'assessment-01', 'title' => 'Look at the roof',
                          'startAt' => '2026-09-21T17:00:00Z',
                          'endAt' => '2026-09-21T18:00:00Z', 'allDay' => false, },
      } },
    } }.to_json
  end

  def test_booking_a_stop_answers_the_assessment_jobber_stored_and_the_lead_it_hangs_off
    visit = book

    assert_equal 'assessment-01', visit.id
    assert_equal 'Look at the roof', visit.description
    assert_equal Time.utc(2026, 9, 21, 17), visit.starts_at
    assert_equal Time.utc(2026, 9, 21, 18), visit.ends_at
    refute visit.anytime?
    assert_equal 'request-01', visit.lead.id
    assert_equal 'client-01', visit.lead.customer.id
    assert_nil visit.job
  end

  # Jobber books in the words of whoever is going: a date, a time, and the zone they are in,
  # rather than the moment in UTC that the two of them come to.
  def test_the_hour_is_sent_as_a_local_date_a_local_time_and_the_zone_it_is_in
    book

    assert_requested(:post, GRAPHQL_URL) do |request|
      schedule = booked_in request
      schedule && schedule['startAt'] == { 'date' => '2026-09-21', 'time' => '13:00:00',
                                           'timezone' => 'America/New_York' } &&
        schedule['endAt']['time'] == '14:00:00' &&
        schedule['teamMemberIdsToAssign'] == [ 'user-01' ]
    end
  end

  # A bare Time names an offset and no zone, and an offset is not a zone: the same one stands
  # for several, and none of them says when the clocks go back.
  def test_a_moment_that_names_no_zone_is_refused_before_a_client_is_opened
    error = assert_raises(Jbr::Error) { book starts_at: Time.utc(2026, 9, 21, 17) }

    assert_includes error.message, 'named zone'
    assert_not_requested :post, GRAPHQL_URL
  end

  # A stop booked for a day rather than an hour has no end to send.
  def test_a_stop_booked_for_no_particular_hour_sends_no_end
    book ends_at: nil

    assert_requested(:post, GRAPHQL_URL) do |request|
      schedule = booked_in request
      schedule && !schedule.key?('endAt')
    end
  end

private

  # The hour a request was booked for, where the request booked one at all.
  def booked_in(request)
    JSON.parse(request.body).dig 'variables', 'input', 'assessment', 'schedule'
  end

  def book(starts_at: Time.find_zone('America/New_York').local(2026, 9, 21, 13), ends_at: :hour)
    account.visits.create name: 'Jane', surname: 'Doe', phone: '5553335555',
      email: 'jane@example.com', address: ADDRESS, description: 'Look at the roof',
      notes: 'Ring twice', source: 'Website', starts_at: starts_at,
      ends_at: (ends_at == :hour ? starts_at + 1.hour : ends_at),
      technicians: [ Jbr::Technician.new(node: { 'id' => 'user-01' }) ]
  end
end
