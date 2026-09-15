require 'test_helper'

# The mock dates nothing it was handed: what an app calls upcoming or past is what it said.
class MockCollectionsTest < Minitest::Test
  def setup = Jbr.mock

  def teardown = Jbr.mock = nil

  def test_visits_are_whatever_the_app_asked_for
    starts_at = Time.now + 3600
    Jbr.mock.visits = [ { id: 'visit-02', description: 'Fixed it', starts_at: Time.now - 3600 },
                        { id: 'visit-01', description: 'Tune-up', starts_at: starts_at,
                          anytime: true, confirmed: false, job: { id: 'job-01' }, }, ]

    visit = credentials.visits.upcoming.first

    assert_equal 'visit-01', visit.id
    assert_equal 'Tune-up', visit.description
    assert_equal 'job-01', visit.job.id
    assert visit.anytime?
    refute visit.confirmed?
    assert_equal starts_at, visit.starts_at
    # One the app dated before now answers to past instead, and both answer to neither twice
    assert_equal %w[visit-02], credentials.visits.past.map(&:id)
    assert_equal %w[visit-02 visit-01], credentials.visits.ids
    # And a lookup answers the one listed under that ID, or nothing
    assert_equal 'Fixed it', credentials.visits.find('visit-02').description
    assert_nil credentials.visits.find('visit-99')
  end

  def test_jobs_are_whatever_the_app_asked_for
    scheduled_at = Time.now + 3600
    created_at = Time.now - 86_400
    Jbr.mock.jobs = [ { id: 'job-02', scheduled_at: Time.now - 3600 },
                      { id: 'job-01', quote: { id: 'quote-01', amount: 240.0 },
                        scheduled_at: scheduled_at,
                        description: 'Tune-up', notes: 'Ring twice',
                        amount: 260.0, created_at: created_at,
                        lines: [ { quantity: 3.0, name: 'Faucet' }, { name: 'Trip fee' } ],
                        location: { id: 'property-01' }, }, ]

    job = credentials.jobs.includes(:lines, location: :customer).upcoming.first

    assert_equal 'job-01', job.id
    assert_equal [ 'Faucet', 'Trip fee' ], job.lines.map(&:name)
    assert_equal [ 3, nil ], job.lines.map(&:quantity)
    assert_equal 'Ring twice', job.notes
    assert_equal 'quote-01', job.quote.id
    assert_equal 260, job.amount
    assert_equal 240, job.quote.amount
    assert_equal created_at, job.created_at
    assert_equal scheduled_at, job.scheduled_at
    assert_equal 'property-01', job.location.id
    assert_nil job.location.customer
    assert_nil job.completed_at
    # The one the app left untitled summarizes as its ID, since something has to name it
    assert_equal 'job-02', credentials.jobs.past.first.id
    assert_equal %w[job-02], credentials.jobs.past.ids
    # And a window narrows the half further: the one dated an hour ago is not in the last minute
    assert_empty credentials.jobs.past(60).ids
    assert_equal %w[job-02 job-01], credentials.jobs.map(&:id)
    # A lookup answers the one listed under that ID
    assert_equal 'Ring twice', credentials.jobs.find('job-01').notes
  end

  def test_a_list_mocked_as_failing_fails_where_it_is_walked_and_not_where_it_is_looked_up
    Jbr.mock.jobs = Enumerator.new { raise Jbr::Throttled, 'Throttled' }
    Jbr.mock.job = { id: 'job-01' }

    jobs = credentials.jobs.past

    assert_raises(Jbr::Throttled) { jobs.ids }
    assert_equal 'job-01', credentials.jobs.find('job-01').id
  end

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

private

  def credentials = Jbr::Account.new access_token: 'mock-token'
end
