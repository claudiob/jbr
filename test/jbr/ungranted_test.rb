require 'test_helper'

# A scope is ticked in the Developer Center and granted by whoever authorizes the app, so an app
# that adds a reader has customers holding credentials from before that reader existed.
class UngrantedTest < Minitest::Test
  # A scope the app was never granted refuses the whole statement, not the one field, so an app
  # holding credentials from before a reader existed would break on every query carrying it.
  # It answers nothing instead, and says so where somebody will read it.
  def test_what_the_grant_does_not_cover_answers_nothing_and_says_so
    stub_graphql_failure status: 200, body: {
      errors: [ { message: 'Not authorized to read users',
                  extensions: { code: 'UNAUTHORIZED' } } ],
    }.to_json
    logged = StringIO.new
    Jbr.logger = Logger.new logged

    assert_empty account.technicians.to_a
    assert_includes logged.string, 'not granted what it asked for'
    assert_includes logged.string, 'Not authorized to read users'
  ensure
    Jbr.logger = nil
  end

  # A refusal nobody recognises is not one to carry on from: answering nothing there would hide
  # a fault behind an empty list.
  def test_a_refusal_of_any_other_kind_still_raises
    stub_graphql_failure status: 200, body: {
      errors: [ { message: 'Field is not defined', extensions: { code: 'undefinedField' } } ],
    }.to_json

    error = assert_raises(Jbr::Error) { account.technicians.to_a }

    assert_includes error.message, 'Field is not defined'
  end
end
