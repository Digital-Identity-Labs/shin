# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2023-04-16
This release greatly expands the functionality of Shin by adding Metadata, Service, Attributes and
Assertion queries.

### New Features
* SAML2 assertions simulating attribute release to specified SPs for a user, via `Shin.Assertion`
* Attributes released to specified SPs for a user, as Maps, via `Shin.Attributes`
* Metadata can be downloaded and Metadata Providers reset, using `Shin.Metadata`
* Services can be restarted and their status checked with `Shin.Service`
* Simplified versions of new query functions added to top-level `Shin` module.
* LiveBook examples added and available from Readme on Github.
* IdPs now have a `:retries` option to set maximum HTTP retries
* A simple, flat report for Service status - `Shin.Reports.ServicesInfo`

## Fixes
* Fixes and improvements to HTTP content types.

### Changed
* Code of Conduct and Changelog have been added.
* HTTP client library is now `Req`
* New endpoints available in IdP structs
* Updates to documentation
* Updated dependencies

## [0.1.0] - 2023-04-11
Initial release

[0.2.0]: https://github.com/Digital-Identity-Labs/shin/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Digital-Identity-Labs/shin/compare/releases/tag/0.1.0
