# Change Log
This file contains all the notable changes done to the Ballerina HTTP package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to 
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- [Fix the limitation of not supporting different API resources with same end URL Template](https://github.com/ballerina-platform/ballerina-standard-library/issues/1095)
- [Fix dispatching failure when same path param identifiers exist in a different order](https://github.com/ballerina-platform/ballerina-standard-library/issues/342)
- [Respond with 500 response when nil is returned in the presence of the http:Caller as a resource argument](https://github.com/ballerina-platform/ballerina-standard-library/issues/1524)
- [Fix HTTP 'Content-Type' header value overriding while setting the payload for request and response](https://github.com/ballerina-platform/ballerina-standard-library/issues/920)
- [Http compiler-plugin should validate header value type](https://github.com/ballerina-platform/ballerina-standard-library/issues/1480)
- [Allow only the error? as return type when http:Caller is present as resource function arg](https://github.com/ballerina-platform/ballerina-standard-library/issues/1519)
- [Fix missing error of invalid inbound request parameter for forward() method](https://github.com/ballerina-platform/ballerina-standard-library/issues/311)

## [1.1.0-beta.1] - 2021-05-06

### Added
- [Add contextually expected type inference support for client remote methods](https://github.com/ballerina-platform/ballerina-standard-library/issues/1371)

### Changed
- [Change configuration parameters of listeners and clients to included record parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/1325)
- Update Netty transport framework version to 4.1.63-Final
- [Mark the HTTP client classes as isolated](https://github.com/ballerina-platform/ballerina-standard-library/issues/1397)

## [1.1.0-alpha8] - 2021-04-22

### Added
- [Implement compiler plugin to validate HTTP service](https://github.com/ballerina-platform/ballerina-standard-library/issues/1102)

## [1.1.0-alpha6] - 2021-04-02

### Added
- [Add enrich header APIs for auth client handlers](https://github.com/ballerina-platform/ballerina-standard-library/issues/584)

### Changed
- Remove usages of `checkpanic` for type narrowing
- Update Stream return type with nil
- Update unused variables with inferred type including error
- Revert "Remove codecov.yml File"
