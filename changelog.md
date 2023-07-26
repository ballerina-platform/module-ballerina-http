
# Change Log
This file contains all the notable changes done to the Ballerina HTTP package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to 
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- [Fix exception when return type of `createInterceptors` function is an array type](https://github.com/ballerina-platform/ballerina-standard-library/issues/4649)

### Added

- [Add open record support for query parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/4541)

## [2.9.0] - 2023-06-30

### Added

- [Add query,header and path parameter runtime support for Ballerina builtin types](https://github.com/ballerina-platform/ballerina-standard-library/issues/4526)

### Fixed

- [Fix parsing query parameters fail when curly braces are provided](https://github.com/ballerina-platform/ballerina-standard-library/issues/4565)
- [Address CVE-2023-34462 netty Vulnerability](https://github.com/ballerina-platform/ballerina-standard-library/issues/4599)

### Changed

- [Removed listener level interceptors](https://github.com/ballerina-platform/ballerina-standard-library/issues/4420)
- [Improved default error format and message](https://github.com/ballerina-platform/ballerina-standard-library/issues/3961)
- [Move status code errors to `httpscerr` module](https://github.com/ballerina-platform/ballerina-standard-library/issues/4535)

## [2.8.0] - 2023-06-01

### Added

- [Add constraint validation for path, query and header parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/4371)
- [Expose `http:Request` in the response interceptor path](https://github.com/ballerina-platform/ballerina-standard-library/issues/3964)
- [Allow configuring an interceptor pipeline with a single interceptor](https://github.com/ballerina-platform/ballerina-standard-library/issues/3969)
- [Add runtime support for type referenced type in path parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/4372)
- [Add finite type support for query, header and path parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/4374)
- [Support for service level interceptors using `http:InterceptableService`](https://github.com/ballerina-platform/ballerina-standard-library/issues/4401)
- [Allow changing initial window size value for client and the server](https://github.com/ballerina-platform/ballerina-standard-library/issues/490)

### Changed

- [Replace the `regex` module usages with the `lang.regexp` library](https://github.com/ballerina-platform/ballerina-standard-library/issues/4275)

## [2.7.0] - 2023-04-10

### Fixed

- [Fix server push not working with nghttp2 HTTP/2 client](https://github.com/ballerina-platform/ballerina-standard-library/issues/3077)
- [Fix the issue - Errors occur at the SSL Connection creation are hidden](https://github.com/ballerina-platform/ballerina-standard-library/issues/3862)
- [Fix integrate JWT information into `http:RequestContext`](https://github.com/ballerina-platform/ballerina-standard-library/issues/3408)
- [Fix header binding failed with 500 for header record param](https://github.com/ballerina-platform/ballerina-standard-library/issues/4168)
- [TypeReference kind return types gives compile time error in resource functions](https://github.com/ballerina-platform/ballerina-standard-library/issues/4043)
- [HTTP compiler plugin validation for return-types not working properly for record types](https://github.com/ballerina-platform/ballerina-standard-library/issues/3651)
- [HTTP compiler does not report error for returning record with object](https://github.com/ballerina-platform/ballerina-standard-library/issues/4045)
- [HTTP compiler does not report error for invalid path param](https://github.com/ballerina-platform/ballerina-standard-library/issues/4239)
- [Returning 500 when the upstream server is unavailable](https://github.com/ballerina-platform/ballerina-standard-library/issues/2929)
- [Encoded url path with special characters is not working as expected](https://github.com/ballerina-platform/ballerina-standard-library/issues/4033)
- [Make panic behavior consistent with interceptor and non-interceptor services](https://github.com/ballerina-platform/ballerina-standard-library/issues/4250)
- [Fix H2 client connection brake when ALPN resolved to H2](https://github.com/ballerina-platform/ballerina-standard-library/issues/3561)

### Added
- [Make @http:Payload annotation optional for post, put and patch](https://github.com/ballerina-platform/ballerina-standard-library/issues/3276)
- [Introduce new HTTP status code error structure](https://github.com/ballerina-platform/ballerina-standard-library/issues/4101)
- [Support for allowing tuple type in the resource return type](https://github.com/ballerina-platform/ballerina-standard-library/issues/3091)
- [Rewrite compiler plugin to resolve inconsistencies](https://github.com/ballerina-platform/ballerina-standard-library/issues/4152)
- [Add basic path parameter support for client resource methods](https://github.com/ballerina-platform/ballerina-standard-library/issues/4240)

## [2.6.0] - 2023-02-20

### Fixed

- [Fix unnecessary warnings in native-image build](https://github.com/ballerina-platform/ballerina-standard-library/issues/3861)
- [Fix union types getting restricted by compiler plugin](https://github.com/ballerina-platform/ballerina-standard-library/issues/3929)
- [Fix data binding doesn't work for `application/x-www-form-urlencoded`](https://github.com/ballerina-platform/ballerina-standard-library/issues/3979)
- [Multipart boundary is disturbed by the Content-type param value with Double quotes](https://github.com/ballerina-platform/ballerina-standard-library/issues/4083)

### Added

- [Add http/1.1 as the ALPN extension when communicating over HTTP/1.1](https://github.com/ballerina-platform/ballerina-standard-library/issues/3766)
- [Added support for `enum` query params](https://github.com/ballerina-platform/ballerina-standard-library/issues/3924)
- [Introduce `getWithType()` method on request context objects](https://github.com/ballerina-platform/ballerina-standard-library/issues/3090)
- [Introduce `hasKey()` and `keys()` methods on request context objects](https://github.com/ballerina-platform/ballerina-standard-library/issues/4070)

## [2.5.2] - 2022-12-22

### Fixed

- [Application killed due to a panic has the exit code 0](https://github.com/ballerina-platform/ballerina-standard-library/issues/3796)
- [Binary payload retrieved from the `http:Request` has different content-length than the original payload](https://github.com/ballerina-platform/ballerina-standard-library/issues/3662)
- [Address CVE-2022-41915 netty Vulnerability](https://github.com/ballerina-platform/ballerina-standard-library/issues/3833)

## [2.5.1] - 2022-12-01

### Fixed

- [Fix HTTP client creating more than one TCP connection](https://github.com/ballerina-platform/ballerina-standard-library/issues/3720)
- [Fix issues with HTTP/2 listener stop](https://github.com/ballerina-platform/ballerina-standard-library/issues/3553)

## [2.5.0] - 2022-11-29

### Added
- [Kill the application when a resource function panics](https://github.com/ballerina-platform/ballerina-standard-library/issues/2714)
- [Add a grace period for graceful stop of the listener](https://github.com/ballerina-platform/ballerina-standard-library/issues/3277)
- [Add missing HTTP status codes](https://github.com/ballerina-platform/ballerina-standard-library/issues/3393)
- [Make socket configuration configurable in both ListenerConfig and Client config](https://github.com/ballerina-platform/ballerina-standard-library/issues/3246)
- [Populate HATEOAS link's types field based on the resource return type](https://github.com/ballerina-platform/ballerina-standard-library/issues/3404)
- [Add defaultable param support for query parameter](https://github.com/ballerina-platform/ballerina-standard-library/issues/1683)

### Changed
- [Reduce Listener default timeout to 60s and Client default timeout to 30s](https://github.com/ballerina-platform/ballerina-standard-library/issues/3278)
- [API Docs Updated](https://github.com/ballerina-platform/ballerina-standard-library/issues/3463)
- [Improve data binding mime type match](https://github.com/ballerina-platform/ballerina-standard-library/issues/3542)
- [Mark client resource methods as isolated](https://github.com/ballerina-platform/ballerina-standard-library/issues/3705)

### Fixed
- [Fix dispatching logic issue due to double slash in basePath](https://github.com/ballerina-platform/ballerina-standard-library/issues/3543)
- [Fix stacklessConnectionClosed exception while calling backend with well known certs](https://github.com/ballerina-platform/ballerina-standard-library/issues/3507)
- [Compilation failure when creating HTTP service](https://github.com/ballerina-platform/ballerina-standard-library/issues/3590)
- [NPE when a request is sent to a non-existent path while Prometheus Metrics are enabled](https://github.com/ballerina-platform/ballerina-standard-library/issues/3605)
- [H2 client request hangs when ALPN resolved to H1](https://github.com/ballerina-platform/ballerina-standard-library/issues/3650)

## [2.4.0] - 2022-09-08

### Added
- [Implement immediateStop in HTTP listener](https://github.com/ballerina-platform/ballerina-standard-library/issues/1794)
- [Add initial support for HATEOAS](https://github.com/ballerina-platform/ballerina-standard-library/issues/2391)
- [Add IP address to both local and remote addresses](https://github.com/ballerina-platform/ballerina-standard-library/issues/3085)
- [Add proxy support for HTTP2 client](https://github.com/ballerina-platform/module-ballerina-http/pull/1128)
- [Make http2 the default transport in http](https://github.com/ballerina-platform/ballerina-standard-library/issues/454)
- [Add support for client resource methods in HTTP client](https://github.com/ballerina-platform/ballerina-standard-library/issues/3102)
- [Add constraint validation to HTTP payload binding](https://github.com/ballerina-platform/ballerina-standard-library/issues/3108)

### Changed
- [Update default response status as HTTP 201 for POST resources](https://github.com/ballerina-platform/ballerina-standard-library/issues/2469)

### Fixed
- [User-Agent header is set to a default value or empty in http post request](https://github.com/ballerina-platform/ballerina-standard-library/issues/3283)

## [2.3.0] - 2022-05-30

### Added
- [Introduce response and response error interceptors](https://github.com/ballerina-platform/ballerina-standard-library/issues/2684)
- [Allow records to be annotated with @http:Header](https://github.com/ballerina-platform/ballerina-standard-library/issues/2699)
- [Add basic type support for header params in addition to `string`, `string[]`](https://github.com/ballerina-platform/ballerina-standard-library/issues/2807)
- [Allow HTTP caller to respond `error`](https://github.com/ballerina-platform/ballerina-standard-library/issues/2832)
- [Allow HTTP caller to respond `StatusCodeResponse`](https://github.com/ballerina-platform/ballerina-standard-library/issues/2853)
- [Introduce `DefaultErrorInterceptor`](https://github.com/ballerina-platform/ballerina-standard-library/issues/2669)
- [Support `anydata` in service data binding](https://github.com/ballerina-platform/ballerina-standard-library/issues/2530)
- [Support `anydata` in client data binding](https://github.com/ballerina-platform/ballerina-standard-library/issues/2036)
- [Add union type support service data binding](https://github.com/ballerina-platform/ballerina-standard-library/issues/2701)
- [Add union type support client data binding](https://github.com/ballerina-platform/ballerina-standard-library/issues/2883)
- [Add common constants for HTTP status-code responses](https://github.com/ballerina-platform/ballerina-standard-library/issues/1540)
- [Add code-actions to generate interceptor method template](https://github.com/ballerina-platform/ballerina-standard-library/issues/2664)
- [Add OpenAPI definition field in `@http:ServiceConfig`](https://github.com/ballerina-platform/ballerina-standard-library/issues/2881)
- [Introduce new HTTP error types](https://github.com/ballerina-platform/ballerina-standard-library/issues/2845)

### Changed
- [Append the scheme of the HTTP client URL based on the client configurations](https://github.com/ballerina-platform/ballerina-standard-library/issues/2816)
- [Refactor auth-desugar respond with DefaultErrorInterceptor](https://github.com/ballerina-platform/ballerina-standard-library/issues/2823)
- [Hide subtypes of http:Client](https://github.com/ballerina-platform/ballerina-standard-library/issues/504)

### Fixed
- [Validate record field types for resource input params](https://github.com/ballerina-platform/ballerina-standard-library/issues/2862)

## [2.2.1] - 2022-03-02

### Added
- [Add code-actions to generate payload and header parameter templates](https://github.com/ballerina-platform/ballerina-standard-library/issues/2642)
- [Add code-actions to add content-type and cache configuration for response](https://github.com/ballerina-platform/ballerina-standard-library/issues/2662)
- [Allow readonly intersection type for resource signature params and return type](https://github.com/ballerina-platform/ballerina-standard-library/issues/2610)

## [2.2.0] - 2022-02-01

### Added
- [Implement Typed `headers` for HTTP response](https://github.com/ballerina-platform/ballerina-standard-library/issues/2563)
- [Add map<string> data binding support for application/www-x-form-urlencoded](https://github.com/ballerina-platform/ballerina-standard-library/issues/2526)
- [Add compiler validation for payload annotation usage](https://github.com/ballerina-platform/ballerina-standard-library/issues/2561)
- [Add support to provide inline request/response body with `x-form-urlencoded` content](https://github.com/ballerina-platform/ballerina-standard-library/issues/2596)

## [2.1.0] - 2021-12-14

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
- [Provide a better way to send with `application/x-www-form-urlencoded`](https://github.com/ballerina-platform/ballerina-standard-library/issues/1705)

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
