## [Unreleased]

- [Feature] The README says which Developer Center object each reader needs ticked. Jobber
  files a visit under Scheduled Items -- one object covering visits, assessments, tasks and
  calendar events -- and there is no Visits scope of its own.

- [Feature] `account.visits.create` books a stop to go and look at work nobody has priced. It
  takes the words `leads.create` takes plus `starts_at:`, `ends_at:` and `technicians:`, opens
  the client and the property where Jobber has none, and files all of it in the one
  `requestCreate`: Jobber hangs the assessment off the request it opens with it. What comes
  back is the assessment Jobber stored, naming the request as its lead. Jobber has no source
  for a request, so `source:` is dropped, and `ends_at:` may be nil for a stop booked to a day.

  `starts_at:` must know its zone. Jobber takes a date, a local time and the zone they are in,
  not a moment in UTC, and a bare `Time` names an offset rather than a zone -- so one is
  refused, with `Jbr::Error`, before a client is opened.

- [Breaking change] `account.visits` is every stop booked, not only a job's. Jobber calls the
  stop booked to look at work before there is a job an assessment and hangs it off the request,
  so `visit.lead` answers that request and `visit.job` is nil there; `for_jobs` and `for_leads`
  narrow to one kind, by Jobber rather than here. The list is read from `scheduledItems` rather
  than `visits`, which has three consequences worth reading twice:

  - **A schedule is read by the window.** `scheduledItems` takes a required `occursWithin`, so
    `account.visits` with nothing narrowing it raises `Jbr::Error` where it used to walk every
    visit there was.
  - **An open end reaches a year.** `occursWithin` takes two moments and no nil, so
    `upcoming` and `past` with no duration are bounded at a year rather than left open.
  - **Unassigned work is in.** `scheduledItems` answers assigned work only unless told
    otherwise, so `schedulingAspects: [ALL]` is always sent. A list that did not send it would
    quietly drop every stop nobody is on yet.

  `account.visits.find` still answers a stop of a job alone: Jobber files an assessment under a
  lookup of its own and this gem does not reach for it. Events, tasks and reminders share the
  list and are read past, Jobber's filter taking one kind and not two.

- [Feature] `account.technicians` walks the account's users a page at a time, each a
  `Jbr::Technician` reading `id`, `name` and `surname` off the `name` node Jobber answers a
  user with. Reading one needs the Users scope, which an app granted before this
  release does not have: Jobber refuses a query selecting a user outright rather than leaving
  the field empty, so an app that asks for a technician re-authorizes first.

- [Feature] `visit.technicians` is whoever a visit is booked for, and `includes(:technicians)`
  is what asks for them -- nothing brings them back unbidden, for the scope above and because
  Jobber prices them on every row that carries them.

- [Feature] `account.visits.between(from, to).assigned_to(technician)` is one technician's
  week. `VisitFilterAttributes` takes an `assignedTo`, so the technician joins the window in
  the one filter Jobber is sent: nobody else's visits are answered, paged or paid for, and the
  crew is not read unless `includes(:technicians)` asks, which means `assigned_to` needs no
  Users scope. Both narrowings land in the same filter, so either order asks the same
  thing. `Jbr.mock.technicians` mocks the crew, and a mocked visit takes a `technicians:` of
  its own.

## [4.0.0] - 2026-09-09

- [Breaking change] `Jbr::Account` is the gateway, and reads in the vocabulary the `company` gem
  names. It replaces `Jbr::OAuth` and the `Jbr.oauth_for`, `Jbr.create_oauth` and
  `Jbr.oauth_url_for` entry points: `Jbr::Account.new credentials`, `Jbr::Account.create code:,
  redirect_uri:`, `Jbr::Account.url_for redirect_uri:, state:`, and `Jbr::Account.client_secret`.
  `#account` is `#business`, answering a `Company::Business` whose `phone` is the ten digits to
  dial rather than the string Jobber holds
- [Breaking change] `#requests` is `#leads`, and `leads.create` takes its keywords by name
  as the vocabulary names them (`name:`, `surname:`, `phone:`, `email:`, `address:`,
  `description:` for the title, `notes:` for the instructions, and a `source:` Jobber has no
  field for) and
  answers a `Jbr::Lead` with `id` and `customer` rather than the collection that filed it.
  `Quote#request_id` is `#lead`, a `Jbr::Lead`; `Invoice#job_id` is `#job`, a `Jbr::Job`;
  `Invoice#total`, `#issued_at` and `#completed_at` are `#amount`, a `BigDecimal`, and
  `#fulfilled_at`, the moment the work was finished or the bill issued where the work never was
- [Breaking change] A job reads `#amount` as a `BigDecimal` where it read `#total` as a Float,
  answers the quote it was won with as `#quote` -- a `Jbr::Quote` with `id` and `amount`,
  nil where there was none -- in place of `#quote_id` and `#quote_total`, its title as
  `#description` and its instructions as `#notes`. `#summary` is gone with `#name`: a caller sums a job up from its lines and
  its description. `Job#title`, `#status` and `#client`, `Visit#title`, `#name`, `#job_id`
  and `#client`, are gone, and `Visit#client_confirmed?` is `#confirmed?`, `#all_day?` is `#anytime?`
- [Breaking change] `includes` takes `:lines`, `:location` and `location: :customer` where it
  took `:line_items`, `:property`, `:client` and `property: :client`, and only on jobs: a visit
  happens where its job does, so it answers `#job` and no `#location` or `includes` of its own. A
  job answers `#lines` and `#location`, and a location `#customer`. `Location#address` and `#state` are gone,
  as are `Customer#first_name` and `#company_name`: `#name` answers the first name, or the
  business's name where a person has none. `Jbr::LineItem`, `Jbr::Property`, `Jbr::Client` and
  `Jbr::Request` are `Jbr::Line`, `Jbr::Location`, `Jbr::Customer` and `Jbr::Lead`
- [Breaking change] `Jbr.mock` takes `business` and `lead` where it took `account` and `request`,
  and every slot reads by the vocabulary's keys: `description`, `amount`, `quote`,
  `lines`, `location`, `customer`, `confirmed`, `lead`, `job`. A mock collection
  answers the vocabulary's own kinds built from those hashes, so `Jbr::Mock::Job` and its
  siblings are gone; `Jbr.mock = nil` hands the accounts back to Jobber
- [Breaking change] `Jbr::Retriable` is `Jbr::Throttled`, a `Company::Throttled` rather than a
  `Jbr::Error`, so one rescue retries a refusal for rate from any platform; its `#cost`,
  `#available`, `#maximum` and `#restore_rate` are gone and the numbers stay in the message.
  `Jbr::Error` descends from `Company::Error`
- [Fix] An `includes` chained after `past` or `upcoming` keeps the window it was asked on. It
  used to rebuild the list without the filter, so `account.jobs.past(1.year).includes(:lines)`
  walked every job the account ever had
- [Fix] A mutation Jobber takes but will not act on raises `Jbr::Error` with the reasons Jobber
  gave. It answers those with a 200 and the messages under the mutation's own `userErrors`,
  which nothing read, so a client Jobber refused to open came back with a nil ID and the
  request filed against nobody
- [Change] Every selection Jobber is asked for is generated from the keys the vocabulary reads
  wherever Jobber's shape is flat, so a kind gaining a reader asks for it without a query
  written by hand

## [3.13.0] - 2026-08-31

- [New] `Jbr::LineItem#id`, `#description` and `#amount`, beside the `#quantity` and `#name` a
  line already answered. The ID is how an app tells a line it has seen before from a new one,
  the description is what the line says beyond what it is called, and the amount is what
  Jobber calls `totalPrice`. Every query that lists lines now asks for all five, and a mocked
  line answers whatever a test names for each

## [3.12.0] - 2026-08-28

- [New] `Jbr::Account#name` and `#phone`, beside the `#id` it already answered. An app storing
  which account it is connected to had nothing to show for it but a GID; the three are read in
  one query the first time any of them is asked for. `Jbr.mock.account` names all three for a
  test, and answers `account-01` for the ID where an app names none

## [3.11.0] - 2026-08-19

- [New] `Jbr::Property#latitude` and `#longitude`, reading the two the address already carried.
  Every property query has asked Jobber for its `coordinates` for some time and `#address` has
  answered them, but a caller wanting one had to open the hash -- and a mocked property answered
  nothing for the whole address, so under `Jbr.mock` there was no way to reach them at all

## [3.8.0] - 2026-08-18

- [New] `Jbr::Retriable`, a `Jbr::Error` for a query Jobber refused over what it costs rather
  than over anything about the query. Every refusal read alike before, so an app had nothing to
  branch on: the one worth asking again a moment later looked exactly like the one that will
  say the same thing forever. It carries what Jobber reported it with — `cost`, `available`,
  `maximum` and `restore_rate` — so a caller can tell a bucket that needed a second from a
  query too big to ever fit in it

## [3.7.2] - 2026-08-17

- [Change] Jobber's token endpoint answers in prose, so that is all this reads. 3.7.1 kept a
  branch for the OAuth 2 `invalid_grant` in a JSON body, guarded by a rescue for a body that
  would not parse — and every failure body Jobber has ever been seen to send is prose, so the
  rescue was the path and the branch it protected had never once been taken. Both are gone

## [3.7.1] - 2026-08-17

- [Fix] A refresh token Jobber will not take gives the credentials up, as it always should
  have. Jobber answers that one in prose and with a 401 — `The provided refresh token is not
  valid.` — where this gem only recognised the OAuth 2 `invalid_grant` in a JSON body, so it
  read a dead grant as a bad moment: `invalid_at` was never set, the error escaped to the
  caller, and an app that persists what it is told kept an authentication that could never work
  again and retried it forever
- [Change] Read the body rather than the status, deliberately. Jobber answers 401 to an app
  whose own client id and secret are wrong just as readily, and giving credentials up over that
  would disconnect every account at once over one misconfigured app

## [3.7.0] - 2026-08-17

- [New] `store:`, for credentials several processes hold copies of. A queue of workers each
  building its own `oauth_for` used to refresh a hundred times over when the access token
  expired, each spending a refresh token the first had already spent — and Jobber calls a
  spent one a dead grant, so all but one of them would mark the credentials invalid and the
  whole connection would be discarded. With a store the refresh happens under the app's own
  lock, against the credentials as they are at that moment, and a holder that finds the token
  already replaced adopts it without asking Jobber anything
- [New] `Jbr::Visits#find`, reaching one visit by the ID Jobber files it under, the way jobs
  already could. An app importing many of them can walk the account for IDs alone and then
  fetch each visit on its own
- [Change] The refresh moved to `Jbr::Refreshing`, which is what `OAuth` includes to do it

## [3.6.2] - 2026-08-17

- [Change] Nothing in this gem sleeps any more. 3.6.0 waited out a refusal for cost and asked
  again, and 3.2.0 spaced every request 0.12s from the one before — both of which put a worker
  to sleep, often with a transaction open around it. A caller asking from a background job has
  a queue that will bring the whole job back later, and that is worth more than a held worker,
  so a refusal is raised and the decision is the caller's. `Jbr::Throttle` and
  `GraphQL::Throttled` go with the waiting; the numbers a refusal reports stay in its message
- [Fix] A mocked `find` answers with the job on `Jbr.mock.jobs` filed under that ID, falling
  back to `Jbr.mock.job` as before. An app that lists jobs and then looks one of them up — one
  request for the IDs, then one job at a time — used to get whichever single job it had mocked,
  whatever ID it asked for
- [Change] Without the request spacing, an app walking many pages is on its own about Jobber's
  other limit, 2,500 requests every five minutes. Nothing here has come close to it: the
  spacing was insurance against a walk that no longer exists

## [3.6.1] - 2026-08-17

- [Fix] 3.6.0 shipped without the two files it added, `graphql/throttled` and `jbr/asking`, so
  requiring the gem raised `LoadError` and nothing worked at all. The gem's file list comes
  from `git ls-files` and the release commit never added them. 3.6.0 is yanked

## [3.6.0] - 2026-08-17

- [Fix] A refusal for cost the bucket can recover from is waited out and asked again, up to
  four times, rather than raised. A walk of many pages drains the bucket faster than it
  refills and gets `Throttled (cost 1885, 1254 of 10000 available, restoring 500/s)` — 631
  points short of a query the bucket holds five times over. The refusal prices the query, so
  the throttle already knows the shortfall: 1.26 seconds at 500 a second, and the same
  question is answered
- [Change] Only a query costing more than the bucket *ever* holds is given up on, since
  waiting cannot help it. Where Jobber names no ceiling, one wait is tried rather than the
  worst assumed
- [New] `GraphQL::Throttled`, a `GraphQL::Error` for a query refused over what it costs rather
  than over anything about the query. It never leaves the gem — a caller still sees
  `Jbr::Error` — but it is what tells the two refusals apart inside it
- [Change] What credentials do when they ask Jobber something is `Jbr::Asking`, mixed into
  `Jbr::OAuth`, which was over a hundred lines with the retry in it

## [3.5.1] - 2026-08-17

- [Change] A line item is how many of what, and nothing else. `description` was answered and
  read out in `to_s` alongside the quantity and the name, and no caller ever wanted it — so it
  is not asked of Jobber any more, which is a smaller query as well as a smaller class.
  `quantified` goes with it: it existed only to be the half of `to_s` without a description,
  and `to_s` is that on its own now. A job's summary is `line_items.to_sentence`, since
  `to_sentence` reads each line's own string form

## [3.5.0] - 2026-08-17

- [Fix] A walk of jobs carrying their line items was refused outright: `Throttled`. Jobber
  prices a query by the page it asks for and prices an *unbounded* connection at its own
  maximum, so `lineItems` on a page of 40 jobs was charged as though every job carried the
  largest job's worth of lines. The connection is bounded at 20 now, and a page of jobs is 20
  rather than 40 — half the page is half the query, and a walk loses nothing by reading twice
  as many. A job with more than 20 lines is summarized by its first 20
- [Fix] Jobber's own failures reach a caller as `Jbr::Error`, which is what this gem has
  always said they would. `GraphQL::Error` was escaping instead, so an app that rescued
  `Jbr::Error` — as the README tells it to — was not catching a throttle, a 500 or an
  unreadable answer, and had its own job blow up rather than hearing that Jobber said no
- [Fix] A refusal for cost says what the cost was: `Throttled (cost 12400, 9500 of 10000
  available, restoring 500/s)` rather than `Throttled`. Without the numbers there is no
  telling a query too big to ever run from a bucket that needed another second
- [Change] A refused query prices the next one. Jobber reports the bucket when it says no as
  readily as when it answers, and the throttle was only reading it on the way through — so a
  walk that hit the ceiling then asked again immediately, at the same size, and was refused
  again

## [3.4.0] - 2026-08-17

- [New] `line_items` on a job: what the work actually was, where the title is only what
  somebody called it. Each is a `Jbr::LineItem` answering `quantity`, `name` and
  `description`, and reading as `3 Bathroom Faucet Installation (Professional installation
  of a new bathroom faucet)` — without the parenthesis where nobody described it, and as the
  name alone where Jobber holds no quantity either. `quantified` is the first half of that on
  its own, how many of what. A quantity reads whole where Jobber's own Float has nothing
  after the point and keeps its fraction where it has, so a line is `3 Faucets` or `3.5
  Hours` as billed. Every line Jobber holds is answered, in the order it holds them
- [New] `includes(:line_items)`, which is how they are asked for. Nothing nested arrives
  unasked, so the import walks that never read a line item pay nothing for them
- [New] `summary` on a job: its lines as a sentence of how many of what, `3 Bathroom Faucet
  Installation and 2 Change Toilet Valve`. What the work was, where `title` is only what
  somebody called it — and `name` again where the job has no lines, or where the query never
  asked for them, so it is never nil and never empty

## [3.3.0] - 2026-08-13

- [Fix] Credentials are given up only when Jobber says the grant itself is no good. Any
  refusal at all used to set `invalid_at` -- a 500, a rate limit, an unreadable body -- so
  a moment of trouble at Jobber's end read as a dead token, and an app acting on that could
  revoke one that still worked. Only an `invalid_grant` Jobber names counts now; everything
  else raises `Jbr::Error` for the caller to retry, which is what trouble deserves
- [New] `Jbr::Refused`, a `Jbr::Error` for the grant being no good rather than for the
  answer failing to arrive. Rescue it to tell the two apart
- [Change] The token endpoint moved to `Jbr::Token`. `Jbr::OAuth.post` still answers it
  unchanged, and so do `Jbr::OAuth.client_id` and `Jbr::OAuth.client_secret`

## [3.2.0] - 2026-08-13

- [New] Wait rather than be refused. Jobber holds an app to two limits at once -- 2,500
  requests every five minutes, and a bucket of query cost that drains as it is asked --
  and a walk of many pages could reach either. Every request now spaces itself 0.12s from
  the one before, which is the count spread evenly over the window, and reads the bucket
  Jobber reports beside the data to wait longer where the next page cannot be paid for.
  A request that follows no other waits for nothing, so a single lookup is as quick as it
  was: only a walk long enough to be a problem is slowed, and only as much as it must be

## [3.1.0] - 2026-08-13

- [Fix] An answer Jobber left empty now reads as no answer rather than as an empty string.
  `client.name` and `job.name` fall through a blank first name or a blank title instead of
  handing one back, so a caller that validates presence is not handed `""` to store. A job
  with no title still answers the ID it is filed under; a client with neither a first name
  nor a company name answers nil
- [New] A visit answers `name` as a job does -- its title, or the ID Jobber files it under
  where nobody titled it. Both read it from `Jbr::Named`, so a record Jobber lets go
  untitled is named the same way wherever it appears
- [Fix] A blank address field does not come back from `property.address`, and is not sent
  when a property is opened. Street, city, state and ZIP are absent rather than empty
- [Fix] A blank timestamp reads as no time. `Time.iso8601` raises on an empty string, so a
  visit or job Jobber dated with one used to take the whole walk down with it
- [Change] Depend on Active Support, for `blank?`, `present?`, `presence` and
  `compact_blank`. Two of its files are required, not the whole library: telling an empty
  answer from a missing one was being done by hand, and being done inconsistently

## [3.0.0] - 2026-08-13

- [Breaking change] `oauth.visits` and `oauth.jobs` answer the whole collection rather than
  one record: each is an Enumerable of every visit or job on the account, oldest first, read
  a page at a time only as far as it is walked. `oauth.visits.upcoming` still answers the
  ones dated from now on, `.past` answers the ones dated before now, and both split the
  schedule at the moment they are asked rather than per page, so nothing crosses the
  boundary unseen. `oauth.jobs.find(id)` is unchanged
- [Breaking change] A visit or a job answers `client` and `property` as objects rather than
  hashes: `visit.client.phone` and `visit.property.street` where `visit.client[:phone]` and
  `visit.property[:street]` used to read. A property answers `client` too, so the person a
  place sits on the file of comes back with the place
- [Breaking change] Nothing nested is fetched unless it is asked for. Chain `includes` the
  way Active Record does -- `oauth.visits.includes(:client, property: :client)` -- and only
  what it names is added to the query. Jobber prices a query by what it brings back, so a
  caller who wants the visit alone is no longer charged for the client and the place
- [New] Fetch jobs the way visits are fetched. A job carries `name`, `title`,
  `instructions`, `status`, `total`, `quote_id`, `quote_total`, `created_at`, `scheduled_at`
  and `completed_at`, and its client and property come back with `includes`. `name` is the
  title, or the ID Jobber files the job under where nobody titled it, so it is never nil
- [New] A client answers `name`: their first name, or the name of the business where the
  client is a business. Jobber files nobody without one or the other, so it is never nil.
  `first_name`, `last_name`, `company_name`, `email` and `phone` read individually
- [New] Mock the jobs an account has with `Jbr.mock.jobs`, beside `Jbr.mock.visits`

## [2.4.0] - 2026-08-08

- [Breaking change] A visit answers `property` -- the ID Jobber files the place under, beside
  the address fields -- rather than `property_id` and `address` apart. It reads the way
  `client` already did, so a caller unpacks both the same way

## [2.3.0] - 2026-08-07

- [Breaking change] A client's phone is the number Jobber holds as reachable rather than
  the string on the record: the primary before the rest, one that takes texts before one
  that does not, and the first of those the North American plan recognizes, ten digits
  without the country code. A client with no such number now answers nil

## [2.2.0] - 2026-08-07

- [New] Carry the client a visit is for -- id, first name, last name, phone and email --
  and the ID of the property it happens at, so an app can file a visit against the people
  and places it already knows

## [2.1.0] - 2026-08-07

- [New] Fetch the visits an account has scheduled from now on, with oauth.visits.upcoming.
  Each carries its job, its times, whether it takes the whole day, whether the client
  confirmed it, and the address of the property it happens at, in the same fields
  Jbr::Property takes. It answers an Enumerator, so a page is read only once the one
  before it runs out
- [New] Read a property's latitude and longitude, beside its street rather than under a
  hash of their own. Every query that reads a property asks for them

## [2.0.0] - 2026-08-07

- [Fix] Require nothing but the standard library: to_query, present?, pluck,
  stringify_keys and Time.current were ActiveSupport calls the gemspec never declared,
  so `require 'jbr'` raised outside Rails
- [Fix] Reuse the property already on a client's file instead of adding a duplicate on
  every request: the lookup read the address as `street`, while the comparison built it
  as `street1`, so it never matched. The match is made on street and ZIP; city and state
  are written but not matched, since Jobber holds whatever was typed
- [Fix] Client#create no longer raises when Jobber answers without clientProperties
- [Feature] Test every line, with SimpleCov failing the suite below 100% coverage
- [Change] Extract Jbr::Property from Jbr::Client
- [Change] Remove the unused Jbr::Configuration class

## [1.2.0] - 2026-06-09

- [New] Create a Property with a Request if needed

## [1.1.0] - 2026-05-27

- [New] Add Jbr::Event.params_for

## [1.0.8] - 2026-05-26

- [New] Add Jbr::OAuth.client_id and Jbr::OAuth.client_secret

## [1.0.7] - 2026-05-26

- [New] Add Jbr::Event to parse webhook payloads

## [1.0.6] - 2026-05-24

- [Change] Return mock.oauth_error as the message of Jbr::Error

## [1.0.5] - 2026-05-24

- [Feature] Add mocks to help apps test Jobber integration

## [1.0.3] - 2026-05-22

- [Fix] Jobber returns invoice.issuedDate as a time, not as a date

## [1.0.2] - 2026-05-22

- [Fix] Ensure .find returns nil if the Jobber resource is not found

## [1.0.0] - 2026-05-15

- Initial release: OAuth, Request, Client, Quote, Job, Invoice, Account classes
