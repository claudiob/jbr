require 'test_helper'

# A scope is ticked in the Developer Center and granted by whoever authorizes the app, so an app
# that adds a reader has customers holding credentials from before that reader existed.
class UngrantedTest < Minitest::Test
  # Jobber hides the object and says so in words, coding this refusal not at all. Where the
  # hidden one was all that was asked for, nothing is left to answer with.
  def test_what_the_grant_does_not_cover_is_hidden_rather_than_answered
    stub_hidden data: nil
    logged = StringIO.new
    Jbr.logger = Logger.new logged

    assert_empty account.technicians.to_a
    assert_includes logged.string, 'Tick the scope for the type it names'
    assert_includes logged.string, 'An object of type User was hidden due to permissions'
  ensure
    Jbr.logger = nil
  end

  # It hides the object, not the query, so a list that asked for one thing too many keeps
  # everything else it asked for: the week arrives, the crew on it does not.
  def test_what_came_back_beside_the_hidden_object_is_kept
    stub_hidden data: { 'scheduledItems' => {
      'nodes' => [ { 'id' => 'visit-01', 'title' => 'Tune-up',
                     'startAt' => '2026-08-09T14:00:00Z', 'assignedUsers' => nil } ],
      'pageInfo' => { 'hasNextPage' => false },
    } }

    visits = account.visits.upcoming.includes(:technicians).to_a

    assert_equal %w[visit-01], visits.map(&:id)
    assert_empty visits.sole.technicians
  end

  # A refusal of any other kind is not one to carry on from: an empty list is a poor place to
  # hide a fault, being indistinguishable from a list that is empty.
  def test_a_refusal_of_any_other_kind_still_raises
    stub_graphql_failure status: 200, body: {
      errors: [ { message: 'Field is not defined' } ], data: nil,
    }.to_json

    error = assert_raises(Jbr::Error) { account.technicians.to_a }

    assert_includes error.message, 'Field is not defined'
  end

private

  # Jobber hiding a user, in the words it uses and with whatever it answered alongside.
  def stub_hidden(data:)
    stub_graphql_failure status: 200, body: {
      errors: [ { message: 'An object of type User was hidden due to permissions',
                  path: %w[users nodes] } ],
      data: data,
    }.to_json
  end
end
