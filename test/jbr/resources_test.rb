require 'test_helper'

class ResourcesTest < Minitest::Test
  def test_a_quote_carries_the_lead_it_answers
    stub_graphql 'quote' => { 'id' => 'quote-01', 'request' => { 'id' => 'request-01' } }

    quote = account.quotes.find 'quote-01'

    assert_equal 'quote-01', quote.id
    assert_equal 'request-01', quote.lead.id
  end

  def test_a_missing_quote_is_nil
    stub_graphql 'quote' => nil

    assert_nil account.quotes.find('quote-01')
  end

  def test_a_job_carries_its_quote_and_its_times
    stub_graphql 'job' => { 'id' => 'job-01', 'quote' => { 'id' => 'quote-01' },
                            'startAt' => '2026-05-14T23:02:52Z',
                            'completedAt' => '2026-05-18T11:36:13Z',
    }

    job = account.jobs.find 'job-01'

    assert_equal 'quote-01', job.quote.id
    assert_nil job.quote.amount
    assert_equal Time.utc(2026, 5, 14, 23, 2, 52), job.scheduled_at
    assert_equal Time.utc(2026, 5, 18, 11, 36, 13), job.completed_at
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include? 'job(id: $id) { id title instructions total createdAt startAt ' \
                            'completedAt quote { id amounts { total } } }'
    end
  end

  def test_an_unscheduled_job_has_no_times
    stub_graphql 'job' => { 'id' => 'job-01', 'startAt' => nil, 'completedAt' => nil }

    job = account.jobs.find 'job-01'

    assert_nil job.scheduled_at
    assert_nil job.completed_at
  end

  def test_a_missing_job_is_nil
    stub_graphql 'job' => nil

    assert_nil account.jobs.find('job-01')
  end
end
