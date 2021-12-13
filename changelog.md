# Change Log
This file contains all the notable changes done to the Ballerina HTTP package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to 
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [Introduce interceptors at service level](https://github.com/ballerina-platform/ballerina-standard-library/issues/2447)

### Fixed
- [Fix parseHeader() to support multiple header values](https://github.com/ballerina-platform/ballerina-standard-library/issues/2403)
- [Fix HTTP caching failure when using the last-modified header as the validator](https://github.com/ballerina-platform/ballerina-standard-library/issues/2402)
- [Fix HTTP caching failure after the initial Max Age expiry](https://github.com/ballerina-platform/ballerina-standard-library/issues/2435)
- [Mark HTTP Caller as Isolated](https://github.com/ballerina-platform/ballerina-standard-library/issues/2451)

### Changed
- [Rename RequestContext add function to set](https://github.com/ballerina-platform/ballerina-standard-library/issues/2414)
- [Only allow default path in interceptors engaged at listener level](https://github.com/ballerina-platform/ballerina-standard-library/issues/2452)

## [2.0.1] - 2021-11-20

### Added
- [Introduce request and request error interceptors](https://github.com/ballerina-platform/ballerina-standard-library/issues/2062)

### Fixed
- [Rename Link header name to link](https://github.com/ballerina-platform/ballerina-standard-library/issues/2135)
- [Relax the data-binding restriction for no content status codes](https://github.com/ballerina-platform/ballerina-standard-library/issues/2294)
- [Fix unused variable warning in the package](https://github.com/ballerina-platform/ballerina-standard-library/issues/2384)
- [Fix initiating auth handlers per each request](https://github.com/ballerina-platform/ballerina-standard-library/issues/2394)

### Changed
- [Remove the logs printed from the listeners](https://github.com/ballerina-platform/ballerina-standard-library/issues/2040)
- [Change the runtime execution based on the isolation status](https://github.com/ballerina-platform/ballerina-standard-library/issues/2383)
- [Mark HTTP Service type as distinct](https://github.com/ballerina-platform/ballerina-standard-library/issues/2398)
- [Change the Listener.getConfig() API to return InferredListenerConfiguration](https://github.com/ballerina-platform/ballerina-standard-library/issues/2399)

## [2.0.0] - 2021-10-10

### Added
- [Enable HTTP trace and access log support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1073)
- [Add HATEOS link support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1637)
- [Introduce http:CacheConfig annotation to the resource signature](https://github.com/ballerina-platform/ballerina-standard-library/issues/1533)
- [Add service specific media-type prefix support in http:ServiceConfig annotation](https://github.com/ballerina-platform/ballerina-standard-library/issues/1620)
- [Add support for Map Json as query parameter](https://github.com/ballerina-platform/ballerina-standard-library/issues/1670)
- [Add OAuth2 JWT bearer grant type support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1788)
- [Add authorization with JWTs with multiple scopes](https://github.com/ballerina-platform/ballerina-standard-library/issues/1801)
- [Add support to overwrite the scopes config by resource annotation](https://github.com/ballerina-platform/ballerina-standard-library/issues/973)
- [Introduce introspection resource method to get generated OpenAPI document of the service](https://github.com/ballerina-platform/ballerina-standard-library/issues/1616)
- [Introduce service config treatNilableAsOptional for query and header params](https://github.com/ballerina-platform/ballerina-standard-library/issues/1928)
- [Add support to URL with empty scheme in http:Client](https://github.com/ballerina-platform/ballerina-standard-library/issues/1986)

### Fixed
- [Fix incorrect behaviour of client with mtls](https://github.com/ballerina-platform/ballerina-standard-library/issues/1708)
- [Fix multiple clients created for same route not using respective config](https://github.com/ballerina-platform/ballerina-standard-library/issues/1727)
- [Fix not applying of resource auth annotations for some resources](https://github.com/ballerina-platform/ballerina-standard-library/issues/1838)
- [Fix SSL test failure due to remote address being null](https://github.com/ballerina-platform/ballerina-standard-library/issues/315)
- [Return error when trying to access the payload after responding](https://github.com/ballerina-platform/ballerina-standard-library/issues/514)
- [Fix incorrect compiler error positions for resource](https://github.com/ballerina-platform/ballerina-standard-library/issues/523)
- [Fix performance issue with observability metrics for unique URLs](https://github.com/ballerina-platform/ballerina-standard-library/issues/1630)
- [Fix support for parameter token with escape characters](https://github.com/ballerina-platform/ballerina-standard-library/issues/1925)

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
