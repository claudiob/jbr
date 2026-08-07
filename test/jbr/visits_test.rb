require 'test_helper'

class VisitsTest < Minitest::Test
  def test_a_visit_carries_its_job_its_address_and_its_times
    address = { 'street1' => '1 Main St', 'city' => 'Raleigh', 'province' => 'NC',
      'postalCode' => '27601',
    }
    node = { 'id' => 'visit-01', 'title' => 'Tune-up', 'job' => { 'id' => 'job-01' },
      'property' => { 'address' => address },
      'startAt' => '2026-08-09T14:00:00Z', 'endAt' => '2026-08-09T16:00:00Z',
    }
    stub_graphql 'visits' => { 'nodes' => [ node ], 'pageInfo' => { 'hasNextPage' => false } }

    visit = oauth.visits.upcoming.first

    assert_equal 'visit-01', visit.id
    assert_equal 'Tune-up', visit.title
    assert_equal 'job-01', visit.job_id
    assert_equal({ street: '1 Main St', city: 'Raleigh', state: 'NC', zip: '27601' },
      visit.address)
    assert_equal Time.utc(2026, 8, 9, 14), visit.starts_at
    assert_equal Time.utc(2026, 8, 9, 16), visit.ends_at
  end

  def test_a_visit_with_no_property_has_no_address
    node = { 'id' => 'visit-01', 'property' => nil }
    stub_graphql 'visits' => { 'nodes' => [ node ], 'pageInfo' => { 'hasNextPage' => false } }

    assert_empty oauth.visits.upcoming.first.address
  end

  def test_an_unscheduled_visit_has_no_job_and_no_times
    node = { 'id' => 'visit-01', 'startAt' => nil, 'endAt' => nil }
    stub_graphql 'visits' => { 'nodes' => [ node ], 'pageInfo' => { 'hasNextPage' => false } }

    visit = oauth.visits.upcoming.first

    assert_nil visit.job_id
    assert_nil visit.starts_at
    assert_nil visit.ends_at
  end

  def test_every_page_of_visits_is_read
    fetched = stub_two_pages

    assert_equal %w[visit-01 visit-02], oauth.visits.upcoming.map(&:id)
    assert_requested fetched, times: 2
  end

  def test_a_page_is_read_only_once_the_one_before_it_runs_out
    fetched = stub_two_pages

    assert_equal 'visit-01', oauth.visits.upcoming.first.id
    assert_requested fetched, times: 1
  end

  def test_the_visits_of_dead_credentials_are_none
    stub_graphql_failure status: 401
    stub_request(:post, JobberStubs::TOKEN_URL).to_return status: 401

    assert_empty oauth.visits.upcoming.to_a
  end

private

  # Two pages of one visit each, the second answered only when the first runs out.
  def stub_two_pages
    stub_request(:post, JobberStubs::GRAPHQL_URL).to_return(
      { body: page_with('visit-01', 'hasNextPage' => true, 'endCursor' => 'cursor-01') },
      { body: page_with('visit-02', 'hasNextPage' => false) },
    )
  end

  def page_with(id, page_info)
    { data: { 'visits' => { 'nodes' => [ { 'id' => id } ], 'pageInfo' => page_info } } }.to_json
  end
end
