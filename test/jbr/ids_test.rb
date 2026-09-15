require 'test_helper'

# Reading an account as nothing but the IDs Jobber files its records under: the question to
# ask where every record is then read on its own, and the cheapest one there is to walk with.
class IdsTest < Minitest::Test
  def test_a_page_of_visit_ids_carries_nothing_else_and_is_five_times_the_size
    stub_graphql 'scheduledItems' => {
      'nodes' => [ { '__typename' => 'Visit', 'id' => 'visit-01' } ],
      'pageInfo' => { 'hasNextPage' => false },
    }

    assert_equal %w[visit-01], account.visits.upcoming.ids
    # Told the kind, to know a visit from an event, and nothing of the job each belongs to
    assert_requested(:post, JobberStubs::GRAPHQL_URL, times: 1) do |request|
      query = JSON.parse(request.body)['query']
      window = JSON.parse(request.body).dig 'variables', 'filter', 'occursWithin'

      query.include?('scheduledItems(first: 100') && query.include?('nodes { id }') &&
        !query.include?('job') && window.keys.sort == %w[endAt startAt]
    end
  end

  def test_a_page_of_job_ids_carries_nothing_else_and_is_five_times_the_size
    stub_graphql 'jobs' => { 'nodes' => [ { 'id' => 'job-01' } ],
                             'pageInfo' => { 'hasNextPage' => false },
    }

    assert_equal %w[job-01], account.jobs.includes(:lines).past.ids
    # Asked for the lines a job is made of, and told about none of them
    assert_asked_for 'jobs(first: 100', without: 'lineItems', dated: 'before'
  end

private

  # The one query it took, the page it asked for, what it left out, and the half of the
  # schedule it was still narrowed to.
  def assert_asked_for(page, without:, dated:)
    assert_requested(:post, JobberStubs::GRAPHQL_URL, times: 1) do |request|
      query = JSON.parse(request.body)['query']
      boundary = JSON.parse(request.body).dig 'variables', 'filter', 'startAt'

      query.include?(page) && query.include?('nodes { id }') &&
        !query.include?(without) && boundary.keys == [ dated ]
    end
  end
end
