require 'test_helper'
require 'active_support/core_ext/integer/time'

# Half a schedule is as much of it as the account holds, unless the caller says how much of it
# they meant: the next three months of visits, or the last year of jobs.
class WindowsTest < Minitest::Test
  def test_the_next_three_months_of_visits_are_bounded_at_both_ends
    stub_scheduled_items

    account.visits.upcoming(3.months).to_a

    assert_asked_within Time.now, Time.now + 3.months
  end

  # Jobber answers assigned work unless told otherwise, and is answered with unscheduled work
  # the moment it is: both knobs go with every window, or a week is wrong in one direction or
  # the other.
  def test_a_window_asks_for_unassigned_work_and_not_for_unscheduled
    stub_scheduled_items

    account.visits.upcoming(1.week).to_a

    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      filter = JSON.parse(request.body).dig 'variables', 'filter'
      filter['includeUnassigned'] == true && filter['includeUnscheduled'] == false
    end
  end

  # Jobber's window takes two moments and no nil, so a half nobody measured cannot be left
  # open the way a list of jobs can: it reaches a year and says so.
  def test_a_visit_window_nobody_measured_reaches_a_year_rather_than_no_end_at_all
    stub_scheduled_items

    account.visits.upcoming.to_a

    assert_asked_within Time.now, Time.now + 1.year
  end

  def test_the_last_year_of_jobs_is_bounded_at_both_ends
    stub_graphql 'jobs' => { 'nodes' => [], 'pageInfo' => { 'hasNextPage' => false } }

    account.jobs.past(1.year).to_a

    assert_asked_about after: Time.now - 1.year, before: Time.now
  end

  def test_a_half_nobody_measured_is_open_at_its_far_end
    stub_graphql 'jobs' => { 'nodes' => [], 'pageInfo' => { 'hasNextPage' => false } }

    account.jobs.past.to_a

    assert_asked_about before: Time.now
  end

private

  def stub_scheduled_items
    stub_graphql 'scheduledItems' => { 'nodes' => [], 'pageInfo' => { 'hasNextPage' => false } }
  end

  # The two ends of the window a schedule was asked for, to the minute.
  def assert_asked_within(opens, closes)
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      window = JSON.parse(request.body).dig 'variables', 'filter', 'occursWithin'
      near?(window['startAt'], opens) && near?(window['endAt'], closes)
    end
  end

  # The two ends of the stretch the query asked about, to the minute, where a nil end is one
  # it named at all.
  def assert_asked_about(after: nil, before: nil)
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      bounds = JSON.parse(request.body).dig 'variables', 'filter', 'startAt'
      near?(bounds['after'], after) && near?(bounds['before'], before)
    end
  end

  def near?(asked, expected)
    return asked.nil? if expected.nil?

    (Time.iso8601(asked) - expected).abs < 60
  end
end
