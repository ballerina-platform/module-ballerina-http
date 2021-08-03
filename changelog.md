# Change Log
This file contains all the notable changes done to the Ballerina HTTP package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to 
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## Added
- [Enable HTTP trace and access log support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1073)
- [Add HATEOS link support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1637)
- [Introduce http:CacheConfig annotation to the resource signature](https://github.com/ballerina-platform/ballerina-standard-library/issues/1533)
- [Introduce anydata as an outbound req/resp data types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1719)

## [1.1.0-beta.2] - 2021-07-07

### Fixed
- [Fix the limitation of not supporting different API resources with same end URL Template](https://github.com/ballerina-platform/ballerina-standard-library/issues/1095)
- [Fix dispatching failure when same path param identifiers exist in a different order](https://github.com/ballerina-platform/ballerina-standard-library/issues/342)
- [Respond with 500 response when nil is returned in the presence of the http:Caller as a resource argument](https://github.com/ballerina-platform/ballerina-standard-library/issues/1524)
- [Fix HTTP 'Content-Type' header value overriding while setting the payload for request and response](https://github.com/ballerina-platform/ballerina-standard-library/issues/920)
- [Http compiler-plugin should validate header value type](https://github.com/ballerina-platform/ballerina-standard-library/issues/1480)
- [Allow only the error? as return type when http:Caller is present as resource function arg](https://github.com/ballerina-platform/ballerina-standard-library/issues/1519)
- [Fix missing error of invalid inbound request parameter for forward() method](https://github.com/ballerina-platform/ballerina-standard-library/issues/311)
- [Fix HTTP Circuit Breaker failure when status codes are not provided in the configuration](https://github.com/ballerina-platform/ballerina-standard-library/issues/339)
- [Fix HTTP FailOver client failure when status codes are overridden by an empty array](https://github.com/ballerina-platform/ballerina-standard-library/issues/1598)
- [Fix already built incompatible payload thrown error](https://github.com/ballerina-platform/ballerina-standard-library/issues/1600) 
- [Optional Types Not Supported in HTTP Client Request Operation Target Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/1433)

### Changed
- Rename `http:ListenerLdapUserStoreBasicAuthProvider` as `http:ListenerLdapUserStoreBasicAuthHandler`

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
