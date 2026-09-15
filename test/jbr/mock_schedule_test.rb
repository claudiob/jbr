require 'test_helper'

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
    assert_equal %w[visit-01], credentials.visits.upcoming.assigned_to(grace).ids
  end

  # A mocked visit says which kind it is by what it hangs off, the way a real one does.
  def test_the_kinds_of_visit_are_told_apart_by_what_each_hangs_off
    Jbr.mock.visits = [ { id: 'visit-01', starts_at: Time.now + 3600, job: { id: 'job-01' } },
                        { id: 'visit-02', starts_at: Time.now + 7200,
                          lead: { id: 'request-01' }, }, ]

    week = credentials.visits.upcoming

    assert_equal %w[visit-01], week.for_jobs.ids
    assert_equal %w[visit-02], week.for_leads.ids
    assert_equal 'request-01', week.for_leads.first.lead.id
  end

private

  def credentials = Jbr::Account.new access_token: 'mock-token'
end
