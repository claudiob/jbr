require 'test_helper'

# Jobber is asked for a page at a time, and only once the page before it runs out, so `first`
# costs one request where `to_a` costs as many as the account has pages.
class PagesTest < Minitest::Test
  # Jobber lists a scheduled item by the window it falls in and refuses to list one without,
  # so a walk of every visit there ever was is a question it will not take.
  def test_a_schedule_with_no_window_is_one_jobber_will_not_list
    error = assert_raises(Jbr::Error) { account.visits.to_a }

    assert_includes error.message, 'window'
    assert_not_requested :post, JobberStubs::GRAPHQL_URL
  end

  def test_every_page_of_visits_is_read
    fetched = stub_two_pages

    assert_equal %w[visit-01 visit-02], account.visits.upcoming.map(&:id)
    assert_requested fetched, times: 2
  end

  def test_a_page_is_read_only_once_the_one_before_it_runs_out
    fetched = stub_two_pages

    assert_equal 'visit-01', account.visits.upcoming.first.id
    assert_requested fetched, times: 1
  end

  def test_the_visits_of_dead_credentials_are_none
    stub_graphql_failure status: 401
    stub_refusal_to_refresh

    assert_empty account.visits.upcoming.to_a
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
    node = { '__typename' => 'Visit', 'id' => id }
    { data: { 'scheduledItems' => { 'nodes' => [ node ], 'pageInfo' => page_info } } }.to_json
  end
end
