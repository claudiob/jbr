require 'test_helper'
require 'active_support/core_ext/time/zones'

# The mock answers a schedule the way Jobber does: narrowed to a window, to a technician, and
# to one kind of stop, with the same code a real list runs.
class MockScheduleTest < Minitest::Test
  def setup = Jbr.mock

  def teardown = Jbr.mock = nil

  def test_technicians_are_whatever_the_app_asked_for
    Jbr.mock.technicians = [ { id: 'user-01', name: 'Grace', surname: 'Hopper' } ]
    Jbr.mock.visits = [ { id: 'visit-01', starts_at: Time.now + 3600,
                          technicians: [ { id: 'user-01' } ], },
                        { id: 'visit-02', starts_at: Time.now + 7200 }, ]

    grace = credentials.technicians.first

    assert_equal %w[user-01], credentials.technicians.ids
    assert_equal 'Grace', grace.name
    assert_equal 'Hopper', grace.surname
    assert_equal %w[visit-01], credentials.visits.upcoming.of(grace.id).ids
  end

  # A mocked visit says which kind it is by what it hangs off, the way a real one does.
  def test_the_kinds_of_visit_are_told_apart_by_what_each_hangs_off
    Jbr.mock.visits = [ { id: 'visit-01', starts_at: Time.now + 3600, job: { id: 'job-01' },
                          location: { id: 'property-01', street: '1 Main St' }, },
                        { id: 'visit-02', starts_at: Time.now + 7200,
                          lead: { id: 'request-01' }, }, ]

    week = credentials.visits.upcoming

    assert_equal %w[visit-01], week.for_jobs.ids
    assert_equal %w[visit-02], week.for_leads.ids
    assert_equal 'request-01', week.for_leads.first.lead.id
    assert_equal '1 Main St', week.for_jobs.first.location.street
    assert_nil week.for_leads.first.location
  end

  # Booking one reaches nobody: the app already said what its lead is.
  def test_a_stop_is_booked_from_what_the_app_listed_rather_than_from_jobber
    Jbr.mock.lead = { id: 'request-01' }
    starts_at = Time.find_zone('America/New_York').local(2026, 9, 21, 13)

    visit = credentials.visits.create name: 'Jane', surname: 'Doe', phone: '5553335555',
      email: nil, address: {}, description: 'Look at the roof', notes: nil, source: nil,
      starts_at: starts_at, ends_at: starts_at + 3600,
      technicians: [ Jbr::Technician.new(node: { 'id' => 'user-01' }) ]

    assert_equal 'visit-01', visit.id
    assert_equal starts_at, visit.starts_at
    assert_equal 'request-01', visit.lead.id
    assert_equal %w[user-01], visit.technicians.map(&:id)
  end

  # What Jobber refuses, the mock refuses, or a suite passes on a booking that cannot be made.
  def test_a_mocked_booking_refuses_the_moment_jobber_would_refuse
    error = assert_raises(Jbr::Error) do
      credentials.visits.create name: 'Jane', surname: nil, phone: '5553335555', email: nil,
        address: {}, description: 'Look at the roof', notes: nil, source: nil,
        starts_at: Time.utc(2026, 9, 21, 17), ends_at: nil, technicians: []
    end

    assert_includes error.message, 'named zone'
  end

private

  def credentials = Jbr::Account.new access_token: 'mock-token'
end
