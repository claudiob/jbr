# Jobber API Ruby client

A client for the Jobber GraphQL API, answering in the vocabulary the
[company](https://github.com/claudiob/company) gem names: an account opens the business its
credentials belong to and the records the business holds, and each record reads by the same
names on Jobber as on any other platform.

## How to install

To install on your system, run

    gem install jbr

To use inside a bundled Ruby project, add this line to the `Gemfile`:

    gem 'jbr', '~> 4.0'

Semantic Versioning promises that `~> major.minor` never crosses a breaking change, so the pin
takes every 4.x release and stops short of 5.0.

## Available methods

### Credentials

Generate the URL for Jobber users to authorize the app:

```ruby
url = Jbr::Account.url_for redirect_uri:, state:
url # => 'https://api.getjobber.com/api/oauth/authorize?state=...&redirect_uri=...'
```

Create an account with the code Jobber sends back and the URI it sent it to:

```ruby
account = Jbr::Account.create code:, redirect_uri:
```

Open an account with credentials already on file:

```ruby
account = Jbr::Account.new access_token:, refresh_token:, expires_at:, account_id:
```

Where several processes hold copies of the same credentials, a queue of workers each building
its own, hand over a `store:` as well, and only one of them will ever spend the refresh token:

```ruby
account = Jbr::Account.new account_id:, invalid_at:, store: credentials
```

The store is anything answering two methods. `exclusively` takes whatever lock the app keeps
over those credentials and yields them *as they are right now*, read inside that lock; `write`
records the ones Jobber handed back:

```ruby
def exclusively = with_lock { yield tokens }   # Active Record, in an app that has it

def write(account) = update tokens: { access_token: account.access_token, ... }
```

An expired access token is then refreshed once. Every other holder takes the lock, finds a
token that is no longer the one it tried, adopts it, and asks Jobber nothing. Without a store
each of them would spend a refresh token the first has already spent, and Jobber would call
every one of those a dead grant.

`exclusively` has to be exclusive against every **process** sharing the credentials, not just
every thread: a `Mutex` satisfies this interface and fixes nothing on a fleet of workers.

Read the credentials as Jobber last gave them:

```ruby
account.access_token # => 'eyJhbGciOiJIUzI1NiJ'
account.refresh_token # => 'ea02775958c5fca28d'
account.expires_at # => 2026-05-22 14:32:53
account.account_id # => 'Z2lkOi8vSm9iYmV'
```

Read the business they belong to:

```ruby
business = account.business
business.id # => 'Z2lkOi8vSm9iYmV'
business.name # => 'Acme Plumbing'
business.phone # => '7044597540', the ten digits to dial, or nil where none can be
```

Revoke the credentials:

```ruby
account.delete
```

Credentials go bad only when Jobber says so of the grant itself, `The provided refresh token
is not valid.`, which sets `invalid_at` and answers queries with nothing. Anything else that
goes wrong raises `Jbr::Error` instead: a 500, a rate limit, and the 401 Jobber answers an app
whose own client id and secret are wrong, which is every account's grant at once rather than
this one's:

```ruby
account.invalid_at # => 2026-08-13 11:02:41, or nil while the credentials are good
account.query '{ ok }' # => {} once they are refused, raises Jbr::Error where Jobber had trouble
```

The app's own client ID and secret are read from `JOBBER_CLIENT_ID` and `JOBBER_CLIENT_SECRET`
in the environment, and `Jbr::Account.client_secret` answers the one to check a webhook with.

### Scopes

Jobber has no scope parameter: an app is granted what its Developer Center page ticks, and a
query selecting anything it was not granted is refused whole rather than answered with the one
field empty. So a scope left unticked is not a nil somewhere, it is every query that touches it
failing. What each reader here needs:

| What a caller asks for | Object to tick |
| --- | --- |
| `account.jobs`, `job.lines` | Jobs |
| `job.location`, `location.customer`, `visit.job` | Jobs and Clients |
| `account.visits`, `assigned_to` | Scheduled Items |
| `account.technicians`, `visit.technicians`, `includes(:technicians)` | Users |
| `account.quotes` | Quotes |
| `account.invoices` | Invoices |
| `account.leads.create` | Requests and Clients, both writing |

Jobber files a visit under **Scheduled Items**, which is one object covering visits,
assessments, tasks and calendar events -- so there is no scope to add for the kinds of booked
time this gem does not read yet.

`assigned_to` is the one worth knowing: narrowing to a technician needs no Users, because
Jobber does the narrowing and no user is ever selected. Reading *who* is on a visit is what
needs it.

The mapping above is read off what each query selects, not published by Jobber, so an app that
is refused has one more object to tick than this table knows about. The names are the ones the
Developer Center shows beside the checkboxes.

An app that asks for what it was never granted is not left broken. Jobber answers
`An object of type User was hidden due to permissions` and hides the object, so a reader added
after an account authorized would otherwise take down every query carrying it:

```ruby
Jbr.logger = Rails.logger # standard error until an app names somewhere better
account.technicians.to_a # => [], with a line in the log naming the type to tick the scope for
account.visits.upcoming(1.week).includes(:technicians).to_a # => the week, with nobody on it
```

What Jobber hides is the object and not the query, so whatever came back beside it is kept: a
list that asked for one thing too many still answers everything else it asked for. Jobber codes
this refusal not at all, so the words are the only signal there is -- and only those words are
carried on from. Anything else still raises: an empty list is a poor place to hide a fault.

### Leads

File a request on the account's board, against the client answering to the phone and the
property at the address, opening either where Jobber has none:

```ruby
lead = account.leads.create name: 'Jane', surname: 'Doe', phone: '5553335555',
  email: 'jane@example.com', description: 'New Plumber Lead', notes: 'Needs new faucet',
  source: nil, # Jobber has no source for a request, so this one is dropped
  address: { street: '1 Main St', city: 'Raleigh', state: 'NC', zip: '27601' }
lead.id # => 'Z2lkOi8vSm9iYmVyL'
lead.customer.id # => 'MwMTU0Mg', the client the request was opened against
```

A mutation Jobber takes but will not act on, a phone it calls invalid or an email it already
holds, raises `Jbr::Error` with what Jobber said.

### Quotes

Fetch a quote from Jobber, and the lead it answers:

```ruby
quote = account.quotes.find 'Z2lkOi8vS'
quote.id # => 'Z2lkOi8vS'
quote.lead.id # => 'Z2lkOi8vSm9iYmVyL', the request the quote answers, or nil where none
```

### Jobs

Fetch a job from Jobber by the ID it is filed under:

```ruby
job = account.jobs.find 'Njc5MTk5'
job.id # => 'Z2lkOi8vS'
job.quote.id # => 'Z2lkOi8vS', the quote the job was won with, or nil where none was
job.quote.amount # => 240.0, in dollars, as a BigDecimal
job.amount # => 260.0
job.notes # => 'Ring the doorbell twice', what Jobber calls the instructions
job.created_at # => 2026-05-10 09:15:00
job.scheduled_at # => 2026-05-14 23:02:52
job.completed_at # => 2026-05-18 11:36:13
```

Or walk the account's jobs, oldest first. Either half of the schedule takes how much of it
you meant, a duration measured from the same now the half is split at, and a walk that stops
at a boundary reads only the pages up to it. Jobber is asked for a page at a time, and only
once the page before it runs out, so `first` costs one request where `to_a` costs as many as
the account has pages. A walk is priced by what its pages carry, and a long one can be refused
for it: see [Rate limits](#rate-limits).

```ruby
account.jobs # => an Enumerable of every job, nothing fetched yet
account.jobs.past # => the ones dated before now, nothing fetched yet
account.jobs.upcoming # => the ones dated from now on, nothing fetched yet
account.jobs.past(1.year) # => only as far back as a year, which is fewer pages to read
account.jobs.past.ids # => %w[Z2lkOi8vS ...], every page of them, and nothing else about them
```

### Lines

What the work actually was, where the title is only what somebody called it. Asked for the
same way as anything nested, since a page costs what it carries:

```ruby
job = account.jobs.includes(:lines).find 'Njc5MTk5'

job.description # => 'Fix the sink', the title somebody typed on the job
job.lines.map(&:name) # => ['Bathroom Faucet Installation', 'Change Toilet Valve']

line = job.lines.first
line.id # => 'Njc5MjAw', the ID Jobber files the line by
line.quantity # => 3, whole where Jobber's own Float has nothing after the point, and 3.5
              #    where it has: `3 Faucets`, or `3.5 Hours` for what was really billed
line.name # => 'Bathroom Faucet Installation'
line.description # => 'Replace washers and reseat', what the line says beyond its name
line.amount # => 285.0, what the line comes to, which Jobber calls totalPrice
```

Every line Jobber holds is in the list, up to twenty of them, in the order it holds them. Ask
for nothing and nothing arrives, so `account.jobs.first.lines` is empty where the query never
named them.

### Invoices

Fetch a non-draft invoice from Jobber:

```ruby
invoice = account.invoices.find 'MjU3ODA0'
invoice.id # => 'MjU3ODA0'
invoice.job.id # => 'Z2lkOi8vS', the job the invoice bills, or nil where none
invoice.amount # => 40.30, in dollars, as a BigDecimal
invoice.fulfilled_at # => 2026-05-22 14:32:53, when the job was finished, or the invoice issued
```

### Visits

A visit is any booked time: somebody is out somewhere for an hour. A stop of a job is one. So is
an *assessment*, the stop booked to go and look at work before there is a job, which Jobber hangs
off the request -- the lead. So is an event or a task, an hour blocked out against nothing at all.
All of them are scheduled items, all of them mean the pro is not free, and all are read from one
list. Jobber has exactly four kinds -- a visit, an assessment, an event and a task -- so none is
read past. A reminder is named by the filter's enum and is not a scheduled item at all, so it
cannot come back.

Where a stop is, is asked for: Jobber hangs the property off each kind rather than off what they
share, and prices it per row, so `includes(:location)` is what turns it on.

```ruby
account.visits.upcoming(3.months) # => only as far ahead as three months
account.visits.upcoming.ids # => %w[Z2lkOi8vS ...], every page of them, and nothing else

visit = account.visits.upcoming(1.week).first
visit.id # => 'Z2lkOi8vS'
visit.description # => 'Furnace tune-up', or nil where nobody titled it
visit.starts_at # => 2026-08-09 14:00:00
visit.ends_at # => 2026-08-09 16:00:00
visit.anytime? # => false
visit.confirmed? # => true, which Jobber alone asks a client
visit.location # => where the stop is, where `includes(:location)` asked
visit.job # => the job the stop belongs to, or nil where no job was booked for it
visit.lead # => the request it was booked against, or nil where no lead was booked for it
```

Either kind alone is one question rather than two, asked of Jobber rather than sifted here:

```ruby
account.visits.upcoming(1.week).for_jobs  # => only the stops of jobs
account.visits.upcoming(1.week).for_leads # => only the assessments
```

**A schedule is read by the window.** Jobber will not list a scheduled item without one, so
`account.visits` with nothing narrowing it raises rather than walking every visit there ever
was. `between`, `upcoming` and `past` all supply one. Jobber's window also takes two moments
and no nil, so `upcoming` and `past` with no duration -- which on a list of jobs means as far
as there is -- reach a year here, and no further.

Book one to go and look at work nobody has priced, against the client answering to the phone
and the property at the address, opening either where Jobber has none:

```ruby
monday = Time.find_zone('America/New_York').local(2026, 9, 21, 13)
visit = account.visits.create name: 'Jane', surname: 'Doe', phone: '5553335555',
  email: 'jane@example.com', address: { street: '1 Main St', city: 'Newark', zip: '07102' },
  description: 'Look at the roof', notes: 'Ring twice', source: 'Website',
  starts_at: monday, ends_at: monday + 1.hour, technicians: [technician]

visit.id # => 'Z2lkOi8vSm9iYmVyL0Fzc2Vzc21lbnQv', the assessment Jobber filed
visit.lead.id # => 'Z2lkOi8vSm9iYmVyL1JlcXVlc3Qv', the request it hangs off
```

One mutation files the lead, the hour and the crew, and what comes back is what Jobber stored
rather than what it was asked for. Jobber has no source for a request, so `source:` is dropped.
`ends_at:` may be nil, for a stop booked to a day rather than an hour.

**`starts_at:` has to know its zone.** Jobber books in the words of whoever is going -- a date,
a local time, and the zone they are in -- rather than the moment in UTC those come to. A bare
`Time` names an offset, and an offset is not a zone: the same one stands for several, and none
of them says when the clocks go back. So hand over a `Time.zone` moment; a `Time` is refused
before anything is opened.

### The schedule

Jobber calls a technician a user, and reading one needs the Users scope. Without it
Jobber refuses the whole query rather than the one field, so nothing asks who is on a visit
unless a caller does. Narrowing *to* a technician needs no such scope -- only reading one back:

```ruby
technician = account.technicians.first
technician.id, technician.name, technician.surname # => 'Z2lkOi8vVXNlc', 'Grace', 'Hopper'

account.visits.includes(:technicians).upcoming.first.technicians # => [#<Jbr::Technician>, ...]
```

One technician's week is the visits in it narrowed to them:

```ruby
monday = Date.today.beginning_of_week.in_time_zone
account.visits.between(monday, monday + 1.week).assigned_to(technician).each do |visit|
  visit.starts_at, visit.ends_at, visit.job.id
end
```

Jobber narrows a list of visits by who is on it, so `assigned_to` puts the technician into the
same filter as the window: nobody else's visits are answered, paged or paid for, and the crew
is not read at all unless `includes(:technicians)` asks. The two narrowings land in the one
filter, so a caller may ask for the week and the technician in either order.

`assigned_to` therefore needs no Users scope. Reading *who* is on a visit does.

A visit is still not all Jobber schedules. A task, an event and the two kinds of reminder sit
on the same calendar and are read past unread, because Jobber's filter takes one kind and not
two, so both the kinds that are visits are asked for and the rest let go as they arrive.

One thing worth knowing about that list: `scheduledItems` answers assigned work only unless it
is told otherwise, so every window carries `includeUnassigned: true` -- without it a week is
quietly missing every stop nobody has been put on yet. It carries `includeUnscheduled: false`
in the same breath, because asking for unassigned work through `schedulingAspects: [ALL]` is
answered with unscheduled work as well: requests filed and never booked, with no hour to
occupy and no place in any window.

### Locations and customers

Jobber prices a query by what it brings back, so nothing nested comes back unless it is
asked for. Chain `includes` the way Active Record does, on jobs; a visit happens where its job
does, so it names the job and nothing else:

```ruby
job = account.jobs.includes(location: :customer).find 'Z2lkOi8vSm9i'

job.location.id # => 'Z2lkOi8vS'
job.location.street # => '1 Main St'
job.location.city # => 'Raleigh'
job.location.zip # => '27601'
job.location.latitude # => 35.77
job.location.longitude # => -78.63

job.location.customer.name # => 'Jane', or the business's name where the client is one.
                           #    Never an empty string: a blank first name falls through
job.location.customer.surname # => 'Doe'
job.location.customer.email # => 'jane@example.com'
job.location.customer.phone # => '5553335555', the ten digits to dial, or nil
```

Ask for nothing and nothing arrives: `account.jobs.first.location` is nil where the query
never named one.

### Rate limits

Jobber holds an app to two limits at once: 2,500 requests every five minutes, and a bucket of
query cost that drains as it is asked and refills at a rate it reports. This gem does nothing
about either. It never sleeps, and it never asks a second time. What it does is say exactly
what happened, so the caller can decide:

```
Throttled (cost 1885, 1254 of 10000 available, restoring 500/s)
```

That one is a `Jbr::Throttled`, a `Company::Throttled` for a refusal worth asking again: 631 points
short of a query the bucket holds five times over, which a second would have refilled. A cost
above what the bucket holds when full is worth nothing but a smaller query. Either way the
decision belongs to whoever called: from a background job, letting it fail so the queue brings
it back is better than a worker asleep holding a transaction open.

Every connection the gem asks for is bounded, to keep a query on the affordable side of that:
twenty lines to a job, ten technicians to a visit, and twenty jobs, visits or technicians to a
page, whichever kinds the page holds. Who is on a visit is priced on top of every row that
carries it, so `includes(:technicians)` costs more per page -- which is why narrowing to one
technician does not use it.

`ids` is the cheap way to walk an account. It asks for the ID and nothing else, which prices
a row at a fraction of a record and buys a hundred of them to a page. Reach for it where each
record is then read on its own with `find`, one background job at a time:

```ruby
account.jobs.past.ids.each { |id| ImportJob.perform_later id }
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

Touch `Jbr.mock` once, in an app's test helper, and every `Jbr::Account` answers from it
instead of Jobber. Each slot takes a Hash by the vocabulary's names.

### Credentials

Mock successfully creating and revoking credentials:

```ruby
Jbr.mock
```

Mock an error when creating credentials:

```ruby
Jbr.mock.oauth_error = 'Flow rejected'
```

Mock a custom authorize URL:

```ruby
Jbr.mock.oauth_url = 'https://example.com'
```

Mock the business the credentials belong to. Left unset, its ID is `account-01`:

```ruby
Jbr.mock.business = { id: 'account-01', name: 'Acme Plumbing', phone: '(704) 459-7540' }
```

### Leads

Mock successfully filing a lead:

```ruby
Jbr.mock.lead = { id: 'request-01', customer: { id: 'client-01' } }
```

### Quotes

Mock successfully fetching a quote:

```ruby
Jbr.mock.quote = { id: 'quote-01', lead: { id: 'request-01' } }
```

### Jobs

Mock successfully fetching a job by ID:

```ruby
Jbr.mock.job = { id: 'job-01', quote: { id: 'quote-01' }, scheduled_at: Date.tomorrow.noon }
```

Mock the jobs the account has. The mock dates nothing it was handed: what answers to
`past` and to `upcoming` is whatever `scheduled_at` the app gave each one, and `find` answers
the one listed under the ID asked for:

```ruby
Jbr.mock.jobs = [ { id: 'job-01', description: 'Furnace tune-up', notes: 'Ring twice',
  amount: 260.0, quote: { id: 'quote-01', amount: 240.0 }, created_at: Date.yesterday.noon,
  scheduled_at: Date.yesterday.noon, completed_at: Date.today.noon,
  lines: [ { quantity: 3.0, name: 'Bathroom Faucet Installation' }, { name: 'Trip fee' } ],
  location: { id: 'property-01', street: '1 Main St',
    customer: { id: 'client-01', name: 'Acme Property Management' } } } ]

account.jobs.past.first.lines.map(&:name) # => ['Bathroom Faucet Installation', 'Trip fee']
```

### Visits

Mock the visits the account has, dated by `starts_at`:

```ruby
Jbr.mock.visits = [ { id: 'visit-01', description: 'Furnace tune-up',
  location: { id: 'property-01', street: '1 Main St',
    customer: { id: 'client-01', name: 'Jane' } },
  starts_at: Date.tomorrow.noon, ends_at: Date.tomorrow.end_of_day,
  anytime: false, confirmed: true,
  technicians: [ { id: 'user-01', name: 'Grace', surname: 'Hopper' } ] } ]
```

### Technicians

Mock the crew the account has:

```ruby
Jbr.mock.technicians = [ { id: 'user-01', name: 'Grace', surname: 'Hopper' } ]
```

A mocked `visits.create` reaches nobody and answers the hour and the crew it was handed, with
`Jbr.mock.lead` for the lead it hangs off. It refuses a moment naming no zone exactly as Jobber
does, so a suite cannot pass on a booking that could not be made.

### Invoices

Mock successfully fetching an invoice:

```ruby
Jbr.mock.invoice = { id: 'invoice-01', job: { id: 'job-01' }, amount: 19.99,
  issued_at: Date.yesterday.noon }
```
