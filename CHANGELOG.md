## [2.1.0] - 2026-08-07

- [New] Fetch the visits an account has scheduled from now on, with oauth.visits.upcoming.
  It answers an Enumerator, so a page is read only once the one before it runs out

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
