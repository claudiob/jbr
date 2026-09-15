require 'test_helper'

# Jobber names a user in a node of its own and narrows nothing by one, so a technician's week
# is the window asked for as it always was and the visits they are on kept out of the answer.
class TechniciansTest < Minitest::Test
  def test_the_crew_reads_by_the_names_the_vocabulary_gives_it
    stub_graphql 'users' => { 'nodes' => [ grace, alan ], 'pageInfo' => { 'hasNextPage' => false } }

    technician = account.technicians.first

    assert_equal 'user-01', technician.id
    assert_equal 'Grace', technician.name
    assert_equal 'Hopper', technician.surname
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include? 'users(first: 20, after: $after, filter: $filter)'
    end
  end

  # Nothing asks Jobber who is on a visit unbidden: an app never granted `read_users` has the
  # whole query refused rather than the field left empty.
  def test_who_is_on_a_visit_is_asked_for_only_where_a_caller_asked
    stub_visits

    account.visits.upcoming.first

    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      !request.body.include? 'assignedUsers'
    end
  end

  def test_a_visit_names_whoever_it_is_booked_for_where_the_query_asked
    stub_visits

    visit = account.visits.includes(:technicians).first

    assert_equal %w[user-01], visit.technicians.map(&:id)
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include? 'assignedUsers(first: 10) { nodes { id name { first last } } }'
    end
  end

  # Jobber takes the technician in the same filter as the window, so nobody else's visits are
  # answered: the narrowing costs a filter key rather than a page of rows to throw away.
  def test_one_technicians_week_is_asked_of_jobber_rather_than_sifted_here
    stub_visits

    account.visits.upcoming(1.week).assigned_to(technician(grace)).ids

    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      filter = JSON.parse(request.body).dig 'variables', 'filter'
      filter['assignedTo'] == 'user-01' && filter['startAt'].key?('after') &&
        !request.body.include?('assignedUsers')
    end
  end

  # The two narrowings land in the one filter, so either order asks Jobber the same thing.
  def test_a_technician_and_a_window_narrow_the_same_filter_in_either_order
    stub_visits

    account.visits.assigned_to(technician(alan)).upcoming(1.week).ids

    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      filter = JSON.parse(request.body).dig 'variables', 'filter'
      filter['assignedTo'] == 'user-02' && filter['startAt'].key?('after')
    end
  end

private

  def grace = { 'id' => 'user-01', 'name' => { 'first' => 'Grace', 'last' => 'Hopper' } }

  def alan = { 'id' => 'user-02', 'name' => { 'first' => 'Alan', 'last' => 'Turing' } }

  def technician(node) = Jbr::Technician.new node: node

  def stub_visits
    nodes = [ { 'id' => 'visit-01', 'assignedUsers' => { 'nodes' => [ grace ] } },
              { 'id' => 'visit-02', 'assignedUsers' => { 'nodes' => [ alan ] } }, ]
    stub_graphql 'visits' => { 'nodes' => nodes, 'pageInfo' => { 'hasNextPage' => false } }
  end
end
