# Jobber API Ruby client

A client for the Jobber GraphQL API. It needs nothing but the standard library.

## Available methods

### Credentials

Generate the URL for Jobber users to authorize the app:

```ruby
url = Jbr.oauth_url_for redirect_uri:, state:
url # => 'https://api.getjobber.com/api/oauth/authorize?state=...&redirect_uri=...'
```

Create credentials with a code and a redirect URI:

```ruby
oauth = Jbr.create_oauth code:, redirect_uri:
```

Initialize with existing credentials:

```ruby
oauth = Jbr.oauth_for access_token:, refresh_token:, expires_at:, account_id:
```

Access OAuth attributes:

```ruby
oauth.access_token # => 'eyJhbGciOiJIUzI1NiJ'
oauth.refresh_token # => 'ea02775958c5fca28d'
oauth.expires_at # => 2026-05-22 14:32:53
oauth.account_id # => 'Z2lkOi8vSm9iYmV'
```

Revoke credentials:

```ruby
oauth.delete
```

### Requests

Create a Jobber request, finding or creating a Client with a matching phone number:

```ruby
request = oauth.requests.create first_name: 'Jane', last_name: 'Doe', phone: '5553335555',
  email: 'jane@example.com', title: 'New Plumber Lead', instructions: 'Needs new faucet'
request.id # => 'Z2lkOi8vSm9iYmVyL'
request.client_id # => 'MwMTU0Mg'
```

### Quotes

Fetch a quote from Jobber:

```ruby
quote = oauth.quotes.find 'Z2lkOi8vS'
quote.id # => 'Z2lkOi8vS'
quote.request_id # => 'Z2lkOi8vSm9iYmVyL'
```

### Jobs

Fetch a job from Jobber:

```ruby
job = oauth.jobs.find 'Njc5MTk5'
job.id # => 'Z2lkOi8vS'
job.quote_id # => 'Z2lkOi8vS'
job.scheduled_at # => 2026-05-14 23:02:52
job.completed_at # => 2026-05-18 11:36:13
```

### Invoices

Fetch a non-draft invoice from Jobber:

```ruby
invoice = oauth.invoices.find 'MjU3ODA0'
invoice.id # => 'MjU3ODA0'
invoice.job_id # => 'Z2lkOi8vS'
invoice.total # => '40.30'
invoice.issued_at # => 2026-05-22 12:12:53
invoice.completed_at # => 2026-05-22 14:32:53
```

### Visits

Fetch the visits scheduled from now on, oldest first. Jobber is asked for a page at a time,
and only once the page before it runs out, so `first` costs one request where `to_a` costs
as many as the account has pages:

```ruby
visits = oauth.visits.upcoming # => an Enumerator, nothing fetched yet
visit = visits.first
visit.id # => 'Z2lkOi8vS'
visit.title # => 'Furnace tune-up'
visit.job_id # => 'Z2lkOi8vS'
visit.address # => { street: '1 Main St', city: 'Raleigh', state: 'NC', zip: '27601',
              #      latitude: 35.77, longitude: -78.63 }
visit.starts_at # => 2026-08-09 14:00:00
visit.ends_at # => 2026-08-09 16:00:00
visit.all_day? # => false
visit.client_confirmed? # => true
```

### Events

Parse the payload of a Jobber event webhook:

```ruby
event = Jbr::Event.new data: { webHookEvent: { topic: 'JOB_CREATE', appId: 'app-1',
  accountId: 'account-1', itemId: 'job-1', occurredAt: '2026-05-22T15:46:33Z' } }
event.account_id # => 'account-1'
event.item_id # => 'job-1'
```

## Available mocks

Use these methods to mock request to Jobber when testing an app:

### Credentials

Mock successfully creating and revoking credentials:

```ruby
Jbr.mock
```

Mock an error when creating credentials:

```ruby
Jbr.mock.oauth_error = 'Flow rejected'
```

Mock a custom redirect URL:

```ruby
Jbr.mock.oauth_url = 'https://example.com'
```

### Requests

Mock successfully creating a request:

```ruby
Jbr.mock.request = { id: 'request-01', client_id: 'client-01' }
```

### Quotes

Mock successfully fetching a quote:

```ruby
Jbr.mock.quote = { id: 'quote-01', request_id: 'request-01' }
```

### Jobs

Mock successfully fetching a job:

```ruby
Jbr.mock.job = { id: 'job-01', quote_id: 'quote-01', scheduled_at: Date.tomorrow.noon }
```

### Visits

Mock successfully fetching upcoming visits:

```ruby
Jbr.mock.visits = [ { id: 'visit-01', title: 'Furnace tune-up', job_id: 'job-01',
  address: { street: '1 Main St', city: 'Raleigh', state: 'NC', zip: '27601' },
  starts_at: Date.tomorrow.noon, ends_at: Date.tomorrow.end_of_day,
  all_day: false, client_confirmed: true } ]
```

### Invoices

Mock successfully fetching an invoice:

```ruby
Jbr.mock.invoice = { id: 'invoice-01', job_id: 'job-01', total: 19.99, issued_at: Date.yesterday.noon }
```
