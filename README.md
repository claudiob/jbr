# Jobber API Ruby client

## Available methods

### Credentials

Generate the URL for Jobber users to authorize the app:

```ruby
url = Jbr.oauth_url_for redirect_uri:, state:
url # => 'https://api.getjobber.com/api/oauth/authorize?state=...&redirect_uri=...'

Create credentials with a code and a redirect URI:

```ruby
oauth = Jbr.create_oauth code:, redirect_uri:
```

Initialize with existing credentials:

```ruby
oauth = Jbr.oauth_for access_token:, refresh_token, expires_at:, account_id:
```

Access OAuth attributes:

```
oauth.access_token # => 'eyJhbGciOiJIUzI1NiJ'
oauth.refresh_token # => 'ea02775958c5fca28d'
oauth.expires_at # => 2026-05-22 14:32:53
oauth.account_id # => 'Z2lkOi8vSm9iYmV'
````

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
Jbr.mock.oauth_url_for = 'https://example.com'
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

### Invoices

Mock successfully fetching an invoice:

```ruby
Jbr.mock.invoice = { id: 'invoice-01', job_id: 'job-01', total: 19.99, issued_at: Date.yesterday.noon }
```
