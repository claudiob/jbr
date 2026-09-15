require 'test_helper'

# A schedule is read to know who is where, so a stop says where it is. Jobber hangs the property
# off each kind of scheduled item rather than off what they share, so it is asked for inside the
# fragments and costs nothing until a caller asks.
class VisitLocationsTest < Minitest::Test
  ADDRESS = { 'street1' => '1 Main St', 'postalCode' => '27601' }

  # Where a stop is, is asked for inside each kind: a scheduled item names no property itself.
  def test_where_a_stop_is_comes_back_where_a_caller_asked_for_it
    stub_visit({ 'property' => property })

    visit = account.visits.upcoming.includes(location: :customer).first

    assert_equal '1 Main St', visit.location.street
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include?('... on Visit { clientConfirmed job { id } property {') &&
        request.body.include?('... on Assessment { clientConfirmed request { id } property {') &&
        # twice and no more: a scheduled item itself has no property to answer with
        request.body.scan('property {').size == 2
    end
  end

  # Nothing is fetched unasked: a page costs what it carries.
  def test_where_a_stop_is_costs_nothing_until_it_is_asked_for
    stub_visit({})

    visit

    assert_requested(:post, JobberStubs::GRAPHQL_URL) { |request| !request.body.include? 'property' }
  end

  def test_a_visit_looked_up_on_its_own_says_where_it_is_too
    stub_graphql 'visit' => { 'id' => 'visit-01', 'property' => property }

    visit = account.visits.includes(:location).find 'visit-01'

    assert_equal '1 Main St', visit.location.street
    assert_requested(:post, JobberStubs::GRAPHQL_URL) do |request|
      request.body.include? 'visit(id: $id) { id title startAt endAt allDay clientConfirmed ' \
                            'job { id } property {'
    end
  end

private

  def property = { 'id' => 'property-01', 'address' => ADDRESS }

  def stub_visit(node, kind: 'Visit')
    nodes = [ { '__typename' => kind, 'id' => 'visit-01' }.merge(node) ]
    stub_graphql 'scheduledItems' => { 'nodes' => nodes,
                                       'pageInfo' => { 'hasNextPage' => false }, }
  end

  def visit = account.visits.upcoming.first
end
