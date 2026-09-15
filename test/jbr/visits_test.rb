require 'test_helper'

class VisitsTest < Minitest::Test
  def test_a_visit_carries_its_times_and_the_job_it_belongs_to
    stub_visit({ 'title' => 'Tune-up', 'allDay' => true, 'clientConfirmed' => false,
                 'job' => { 'id' => 'job-01' }, 'startAt' => '2026-08-09T14:00:00Z',
                 'endAt' => '2026-08-09T16:00:00Z', })

    visit = self.visit

    assert_equal 'visit-01', visit.id
    assert_equal 'Tune-up', visit.description
    assert_equal 'job-01', visit.job.id
    assert_nil visit.lead
    assert_equal Time.utc(2026, 8, 9, 14), visit.starts_at
    assert_equal Time.utc(2026, 8, 9, 16), visit.ends_at
    assert visit.anytime?
    refute visit.confirmed?
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include?('... on Visit { clientConfirmed job { id } }') &&
        request.body.include?('... on Assessment { clientConfirmed request { id } }')
    end
  end

  # An assessment is the stop booked to go and look at work before there is a job: it names the
  # request it was booked against, which the vocabulary reads as the lead.
  def test_a_visit_booked_against_a_request_belongs_to_that_lead_and_to_no_job
    stub_visit({ 'request' => { 'id' => 'request-01' }, 'title' => 'Quote the roof' },
      kind: 'Assessment')

    visit = self.visit

    assert_equal 'request-01', visit.lead.id
    assert_nil visit.job
    assert_equal 'Quote the roof', visit.description
  end

  # An hour blocked out is booked time: the pro is not free, whatever it is they are doing. It
  # names no job, no lead and often nowhere, and it is a visit all the same.
  def test_an_hour_blocked_out_is_booked_time_and_says_so_by_naming_nothing
    stub_visit({ 'title' => 'Team meeting' }, kind: 'Event')

    assert_equal 'Team meeting', visit.description
    assert_nil visit.job
    assert_nil visit.lead
    assert_nil visit.location
  end

  # Jobber answers a field it holds nothing for with an empty string as readily as with null,
  # and a caller that validates presence needs the two to arrive as the same nothing.
  def test_a_moment_left_empty_is_no_moment_rather_than_an_empty_string
    stub_visit({ 'endAt' => '' })

    assert_nil visit.ends_at
  end

  def test_a_visit_of_no_job_belongs_nowhere
    stub_visit({})

    assert_nil visit.job
  end

private

  def stub_visit(node, kind: 'Visit')
    booked = { '__typename' => kind, 'id' => 'visit-01', 'startAt' => '2026-08-09T14:00:00Z' }
    nodes = [ booked.merge(node) ]
    stub_graphql 'scheduledItems' => { 'nodes' => nodes,
                                       'pageInfo' => { 'hasNextPage' => false }, }
  end

  def visit = account.visits.upcoming.first
end
