require 'test_helper'

# The mock layer answers without a network, so nothing here stubs a request.
class MockTest < Minitest::Test
  # Turning mocking on is what an app does once, in its own test helper.
  def setup = Jbr.mock

  def test_the_authorize_url_is_whatever_the_app_asked_for
    Jbr.mock.oauth_url = 'https://example.com/authorize'

    assert_equal 'https://example.com/authorize', Jbr.oauth_url_for(redirect_uri: 'https://x.test')
  end

  def test_credentials_are_created_and_revoked_without_a_network
    credentials = Jbr.create_oauth code: 'code', redirect_uri: 'https://x.test'

    assert_equal 'mock-token', credentials.access_token
    assert_equal 'account-01', credentials.account_id
    assert_nil credentials.delete
  end

  def test_a_rejected_flow_raises_the_message_the_app_set
    Jbr.mock.oauth_error = 'Flow rejected'

    error = assert_raises(Jbr::Error) { Jbr.create_oauth code: 'code', redirect_uri: 'https://x' }
    assert_equal 'Flow rejected', error.message
  ensure
    Jbr.mock.oauth_error = nil
  end

  def test_a_request_is_whatever_the_app_asked_for
    Jbr.mock.request = { id: 'request-01', client_id: 'client-01' }

    request = credentials.requests.create title: 'New Plumber Lead'

    assert_equal 'request-01', request.id
    assert_equal 'client-01', request.client_id
  end

  def test_a_quote_is_whatever_the_app_asked_for
    Jbr.mock.quote = { id: 'quote-01', request_id: 'request-01' }

    quote = credentials.quotes.find 'anything'

    assert_equal 'quote-01', quote.id
    assert_equal 'request-01', quote.request_id
  end

  def test_a_job_is_whatever_the_app_asked_for
    scheduled_at = Time.utc 2026, 5, 14
    Jbr.mock.job = { id: 'job-01', quote_id: 'quote-01', scheduled_at: scheduled_at }

    job = credentials.jobs.find 'anything'

    assert_equal 'job-01', job.id
    assert_equal 'quote-01', job.quote_id
    assert_equal scheduled_at, job.scheduled_at
    assert_nil job.completed_at
  end

  def test_an_invoice_is_whatever_the_app_asked_for
    issued_at = Time.utc 2026, 5, 22
    Jbr.mock.invoice = { id: 'invoice-01', job_id: 'job-01', total: 19.99, issued_at: issued_at }

    invoice = credentials.invoices.find 'anything'

    assert_equal 'invoice-01', invoice.id
    assert_equal 'job-01', invoice.job_id
    assert_equal 19.99, invoice.total
    assert_equal issued_at, invoice.issued_at
    assert_nil invoice.completed_at
  end

  def test_visits_are_whatever_the_app_asked_for
    starts_at = Time.utc 2026, 8, 9
    Jbr.mock.visits = [ { id: 'visit-01', title: 'Tune-up', job_id: 'job-01',
                          starts_at: starts_at, address: { street: '1 Main St' },
    } ]

    visit = credentials.visits.upcoming.first

    assert_equal 'visit-01', visit.id
    assert_equal 'Tune-up', visit.title
    assert_equal 'job-01', visit.job_id
    assert_equal({ street: '1 Main St' }, visit.address)
    assert_equal starts_at, visit.starts_at
    assert_nil visit.ends_at
  end

private

  def credentials = Jbr.oauth_for access_token: 'mock-token'
end
