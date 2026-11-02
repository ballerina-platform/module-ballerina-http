# Specification: Ballerina HTTP Library

_Owners_: @shafreenAnfar @TharmiganK @ayeshLK @chamil321  
_Reviewers_: @shafreenAnfar @bhashinee @TharmiganK @ldclakmal  
_Created_: 2021/12/23  
_Updated_: 2026/11/02  
_Edition_: Swan Lake  

## Introduction

This is the specification for the HTTP standard library of the [Ballerina language](https://ballerina.io/), which provides the HTTP listener, service and client functionality used to produce and consume HTTP APIs.

This specification is the contract of the library. It defines the observable behaviour of the library: the configuration it accepts, how it processes requests and responses, the errors it returns, and what it rejects at compile time. A behaviour of the implementation that differs from this specification is a bug in the implementation. A behaviour that this specification does not define is a gap in the specification, and is also reported as a bug. Signatures and per-symbol documentation are part of the [API documentation](https://central.ballerina.io/ballerina/http/latest), and usage examples are part of [Ballerina by Example](https://ballerina.io/learn/by-example/). Neither is repeated here.

The released versions of the specification can be found under the relevant GitHub tag. Changes to the specification follow the proposal process described in the [library development process](https://github.com/ballerina-platform/ballerina-library/blob/main/docs/library-development-process.md). If you have any feedback or suggestions about the library, start a discussion via a [GitHub issue](https://github.com/ballerina-platform/ballerina-library/issues) or in the [Discord server](https://discord.gg/ballerinalang).

### Notation

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY and OPTIONAL in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174) when, and only when, they appear in all capitals. Sentences that state behaviour in the present tense are also normative. Examples, notes and the overview are informative. Behaviour marked as _unspecified_ MUST NOT be relied upon.

Durations are in seconds and sizes are in bytes unless stated otherwise. Status codes are written as `<code> <reason phrase>`, e.g. `404 Not Found`. Types are written without the `http:` prefix when they belong to this library.

## Contents

- [1. Overview](#1-overview)
- [2. Terminology](#2-terminology)
- [3. Listener](#3-listener)
    - [3.1. Description](#31-description)
    - [3.2. Configuration](#32-configuration)
    - [3.3. Lifecycle](#33-lifecycle)
    - [3.4. HTTP versions and connections](#34-http-versions-and-connections)
    - [3.5. Request limits](#35-request-limits)
    - [3.6. Default listener](#36-default-listener)
- [4. Service](#4-service)
    - [4.1. Description](#41-description)
    - [4.2. Base path](#42-base-path)
    - [4.3. Compile-time validation](#43-compile-time-validation)
    - [4.4. Service configuration](#44-service-configuration)
    - [4.5. Service contract](#45-service-contract)
    - [4.6. OpenAPI resources](#46-openapi-resources)
- [5. Resources](#5-resources)
    - [5.1. Description](#51-description)
    - [5.2. Accessors](#52-accessors)
    - [5.3. Resource paths](#53-resource-paths)
    - [5.4. Resource configuration](#54-resource-configuration)
- [6. Request dispatching](#6-request-dispatching)
    - [6.1. Service selection](#61-service-selection)
    - [6.2. Matrix parameters](#62-matrix-parameters)
    - [6.3. Resource selection](#63-resource-selection)
    - [6.4. Automatic OPTIONS responses](#64-automatic-options-responses)
    - [6.5. Path parameter binding](#65-path-parameter-binding)
    - [6.6. CORS](#66-cors)
    - [6.7. Dispatching errors](#67-dispatching-errors)
- [7. Resource parameters](#7-resource-parameters)
    - [7.1. Parameter classification](#71-parameter-classification)
    - [7.2. Special parameters](#72-special-parameters)
    - [7.3. Names](#73-names)
    - [7.4. Query parameters](#74-query-parameters)
    - [7.5. Header parameters](#75-header-parameters)
    - [7.6. Payload parameter](#76-payload-parameter)
    - [7.7. Compile-time validation](#77-compile-time-validation)
- [8. Responses](#8-responses)
    - [8.1. Return types](#81-return-types)
    - [8.2. Status codes](#82-status-codes)
    - [8.3. Content type and serialization](#83-content-type-and-serialization)
    - [8.4. Status code responses](#84-status-code-responses)
    - [8.5. Responding with a caller](#85-responding-with-a-caller)
    - [8.6. Server-sent events](#86-server-sent-events)
    - [8.7. Response caching headers](#87-response-caching-headers)
    - [8.8. Links](#88-links)
    - [8.9. Compile-time validation](#89-compile-time-validation)
- [9. Interceptors](#9-interceptors)
    - [9.1. Description](#91-description)
    - [9.2. Interceptor types](#92-interceptor-types)
    - [9.3. Engaging interceptors](#93-engaging-interceptors)
    - [9.4. Request context](#94-request-context)
    - [9.5. Execution](#95-execution)
    - [9.6. Compile-time validation](#96-compile-time-validation)
- [10. Error handling](#10-error-handling)
    - [10.1. Status codes of errors](#101-status-codes-of-errors)
    - [10.2. Default error response](#102-default-error-response)
    - [10.3. Panics](#103-panics)
- [11. Client](#11-client)
    - [11.1. Description](#111-description)
    - [11.2. Initialization](#112-initialization)
    - [11.3. Configuration](#113-configuration)
    - [11.4. Feature composition](#114-feature-composition)
    - [11.5. Caching](#115-caching)
    - [11.6. Redirects](#116-redirects)
    - [11.7. Cookies](#117-cookies)
    - [11.8. Proxy](#118-proxy)
    - [11.9. Response limits](#119-response-limits)
    - [11.10. Sending requests](#1110-sending-requests)
    - [11.11. Response data binding](#1111-response-data-binding)
    - [11.12. Status code client](#1112-status-code-client)
    - [11.13. Client errors](#1113-client-errors)
- [12. Resiliency](#12-resiliency)
    - [12.1. Retry](#121-retry)
    - [12.2. Circuit breaker](#122-circuit-breaker)
    - [12.3. Load balance client](#123-load-balance-client)
    - [12.4. Failover client](#124-failover-client)
- [13. Message body streaming and back-pressure](#13-message-body-streaming-and-back-pressure)
- [14. Observability](#14-observability)
    - [14.1. Trace logs](#141-trace-logs)
    - [14.2. Access logs](#142-access-logs)
    - [14.3. Log rotation](#143-log-rotation)
- [15. Authentication and authorization](#15-authentication-and-authorization)
    - [15.1. Declarative listener authentication](#151-declarative-listener-authentication)
    - [15.2. Imperative listener authentication](#152-imperative-listener-authentication)
    - [15.3. Client authentication](#153-client-authentication)
- [16. TLS](#16-tls)
    - [16.1. Common configuration](#161-common-configuration)
    - [16.2. Listener](#162-listener)
    - [16.3. Client](#163-client)
- [17. Security considerations](#17-security-considerations)
- [18. Static code rules](#18-static-code-rules)

## 1. Overview

The library provides three main abstractions:

- A `Listener` receives HTTP requests over the network and dispatches them to the services attached to it.
- A `Service` is a collection of resource methods. Each resource method handles requests for one HTTP method and one resource path, and its parameters and return value are bound to the request and the response.
- A `Client` sends HTTP requests to a remote endpoint, and binds the responses to the types the caller expects. The client can be configured with resiliency features such as retrying, circuit breaking and failover.

Interceptors run common logic before and after resource methods, and error interceptors turn errors into responses. Security is provided through declarative authentication and authorization, imperative auth handlers, and TLS. The library supports HTTP/1.0, HTTP/1.1 and HTTP/2, and is also the transport of other standard libraries such as GraphQL and WebSub.

## 2. Terminology

| Term                           | Meaning                                                                                                                                                                                  |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Listener                       | A value of the `Listener` type, bound to one port.                                                                                                                                       |
| Service                        | A service object attached to a listener whose type is a subtype of `Service`.                                                                                                            |
| Resource                       | A resource method of a service. It is identified by its accessor and its resource path.                                                                                                 |
| Accessor                       | The method name of a resource, e.g. `get` or `default`. It determines the HTTP methods the resource handles.                                                                            |
| Base path                      | The absolute path at which a service is attached to a listener.                                                                                                                         |
| Resource path                  | The path of a resource relative to the base path of its service.                                                                                                                        |
| Sub-path                       | The part of the request path that follows the base path of the selected service.                                                                                                        |
| Default host                   | The host name `b7a.default`, under which a service is registered when it does not configure a host.                                                                                    |
| Data binding                   | Converting a part of a message, such as a query parameter, a header or the payload, to a Ballerina value of the declared type, or the reverse.                                           |
| Status code response           | A value of a record type that includes one of the status code record types of the library, such as `Ok` or `NotFound`. Each fixes the status code of the response.                       |
| Interceptor pipeline           | The ordered list of interceptors that apply to the requests of a service.                                                                                                               |
| Network-level failure          | A client request that does not result in an HTTP response, e.g. a connection failure, a connection reset, an idle timeout or a TLS handshake failure. It results in a `ClientError`.      |
| Idle timeout                   | The `timeout` of a listener or a client. It is the maximum period of inactivity on a connection or stream, not the maximum duration of a request.                                       |
| Configurable                   | A module-level `configurable` variable of the library, set under `[ballerina.http]` in `Config.toml` or with a `-Cballerina.http.<name>=<value>` argument.                               |

## 3. Listener

### 3.1. Description

A listener accepts connections on a port, reads HTTP requests from them, dispatches each request to an attached service, and writes the responses back. It implements the listener object lifecycle defined in the [Ballerina language specification](https://ballerina.io/spec/lang/master/#section_8.3).

### 3.2. Configuration

A listener is created with a port and an optional `ListenerConfiguration`. The port MUST be greater than `0`. Initialization fails with a `ListenerError` when the port is `0` or when any configuration value below is invalid.

| Field                      | Type                     | Default         | Meaning                                                                                                                                                                                                                                       |
|----------------------------|--------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `host`                     | `string`                 | `"0.0.0.0"`     | Network interface to bind. An empty or blank value is treated as `"0.0.0.0"`.                                                                                                                                                                |
| `httpVersion`              | `HttpVersion`            | `HTTP_2_0`      | Highest HTTP version the listener accepts. See [HTTP versions](#34-http-versions-and-connections).                                                                                                                                           |
| `http1Settings`            | `ListenerHttp1Settings`  | `{}`            | Settings for HTTP/1.x connections. See below.                                                                                                                                                                                                 |
| `secureSocket`             | `ListenerSecureSocket?`  | `()`            | TLS configuration. `()` means the listener accepts cleartext connections only. See [TLS](#162-listener).                                                                                                                                      |
| `timeout`                  | `decimal`                | `60`            | Idle timeout. `0` disables it. A negative value is an initialization error.                                                                                                                                                                   |
| `server`                   | `string?`                | `()`            | Value of the `Server` header of responses. `()` means `ballerina/<library version>`.                                                                                                                                                         |
| `requestLimits`            | `RequestLimitConfigs`    | `{}`            | Limits on the size of inbound requests. See [Request limits](#35-request-limits).                                                                                                                                                            |
| `gracefulStopTimeout`      | `decimal`                | `0`             | Period for which `gracefulStop()` lets in-flight requests complete. A negative value is an initialization error.                                                                                                                              |
| `socketConfig`             | `ServerSocketConfig`     | `{}`            | Socket options: `soBackLog` (`100`), `connectTimeOut` (`15`), `receiveBufferSize` (`1048576`), `sendBufferSize` (`1048576`), `tcpNoDelay` (`true`), `socketReuse` (`true`) and `keepAlive` (`false`).                                       |
| `http2InitialWindowSize`   | `int`                    | `65535`         | HTTP/2 initial flow-control window size advertised to clients.                                                                                                                                                                               |
| `http2MaxActiveStreams`    | `int`                    | `100`           | Maximum number of concurrent streams per HTTP/2 connection, advertised as `SETTINGS_MAX_CONCURRENT_STREAMS`.                                                                                                                                  |
| `minIdleTimeInStaleState`  | `decimal`                | `300`           | Minimum time an HTTP/2 connection that has received a `GOAWAY` frame is kept open. `-1` keeps it open until all its in-flight streams are complete.                                                                                         |
| `timeBetweenStaleEviction` | `decimal`                | `30`            | Interval between the runs that close HTTP/2 connections whose `minIdleTimeInStaleState` has elapsed. A value less than or equal to `0` is treated as `30`.                                                                                  |

`ListenerHttp1Settings` has the following fields. They apply to every HTTP/1.x connection of the listener, whatever the value of `httpVersion`.

| Field                  | Type        | Default          | Meaning                                                                                                                              |
|------------------------|-------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `keepAlive`            | `KeepAlive` | `KEEPALIVE_AUTO` | Whether a connection is kept open after a response. See [Keep-alive](#342-keep-alive-and-pipelining).                                |
| `maxPipelinedRequests` | `int`       | `10`             | Maximum number of requests on one connection that have been received but not yet responded to.                                      |

The configuration of the secure socket, the window size and the stale eviction fields apply to both cleartext and TLS listeners.

### 3.3. Lifecycle

1. `attach(service, basePath)` registers a service under its host (see [Service configuration](#44-service-configuration)) and base path (see [Base path](#42-base-path)). It returns an error when a service with the same base path is already registered under the same host. Services with the same base path MAY be attached to the same listener under different hosts. A service MAY be attached before or after `start()`.
2. `start()` binds the port and starts accepting connections. Calling it on a listener that has already started has no effect. Service-level interceptors are created when `start()` is called. A failure to create the interceptor pipeline of a service is returned as a `ListenerError`. A failure to bind the port results in a panic with a `ListenerError`.
3. `detach(service)` removes a service. Requests received afterwards are not dispatched to it. Detaching a service that is not attached has no effect.
4. `gracefulStop()` stops accepting new connections, waits for `gracefulStopTimeout`, and then closes all remaining connections. Requests that are still in flight when the connections are closed are terminated without a response. With the default `gracefulStopTimeout` of `0`, in-flight requests are terminated immediately.
5. `immediateStop()` stops accepting new connections and closes all connections immediately.

### 3.4. HTTP versions and connections

#### 3.4.1. HTTP versions

1. When `httpVersion` is `HTTP_2_0` and `secureSocket` is `()`, the listener accepts HTTP/2 over cleartext (h2c), both with prior knowledge and through an HTTP/1.1 `Upgrade: h2c` request. Any other connection is served as HTTP/1.x.
2. When `httpVersion` is `HTTP_2_0` and `secureSocket` is configured, the listener negotiates `h2` or `http/1.1` using ALPN.
3. When `httpVersion` is `HTTP_1_1` or `HTTP_1_0`, the listener never serves HTTP/2. With TLS, ALPN advertises `http/1.1` only.
4. Push promises are supported on HTTP/2 connections only. On an HTTP/1.x connection, `Caller->promise()` and `Caller->pushPromisedResponse()` return a `ListenerError`.

#### 3.4.2. Keep-alive and pipelining

1. With `KEEPALIVE_AUTO`, an HTTP/1.1 connection is kept open unless the request has a `Connection: close` header, and an HTTP/1.0 connection is kept open only if the request has a `Connection: keep-alive` header.
2. With `KEEPALIVE_ALWAYS`, the connection is kept open after every response. With `KEEPALIVE_NEVER`, the connection is closed after every response.
3. A response with the `text/event-stream` content type keeps the connection open regardless of `keepAlive`.
4. When a request arrives on a connection that already has `maxPipelinedRequests` requests that are not responded to, the connection is closed without a response.

#### 3.4.3. Idle timeout

1. On an HTTP/1.x connection with no request in progress, the connection is closed when the idle timeout elapses.
2. When the idle timeout elapses while the headers or the body of a request are being received, or after the request is dispatched but before the service starts the response, the listener responds with `408 Request Timeout` and closes the connection.
3. When the idle timeout elapses while a response is being written, the connection is closed.
4. On an HTTP/2 connection, the idle timeout applies to each stream. Before the response starts, the stream is answered with `408 Request Timeout`. After the response starts, the stream is reset with `INTERNAL_ERROR`.
5. Inactivity caused by the application consuming or producing a body slowly is handled as described in [Message body streaming](#13-message-body-streaming-and-back-pressure).

### 3.5. Request limits

| Field               | Type  | Default | Meaning                                                                                                                                                                                       |
|---------------------|-------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `maxUriLength`      | `int` | `4096`  | Maximum length of the request line of an HTTP/1.x request. A negative value is an initialization error.                                                                                      |
| `maxHeaderSize`     | `int` | `8192`  | Maximum total size of the request headers. A negative value is an initialization error. For HTTP/2, it is advertised as `SETTINGS_MAX_HEADER_LIST_SIZE`.                                      |
| `maxEntityBodySize` | `int` | `-1`    | Maximum size of the body of each HTTP/1.x request. `-1` means no limit. A value less than `-1` is an initialization error.                                                                   |

1. An HTTP/1.x request whose request line exceeds `maxUriLength` is answered with `414 URI Too Long`, and one whose headers exceed `maxHeaderSize` is answered with `431 Request Header Fields Too Large`. Both responses use the `HTTP/1.0` status line, and the connection is closed afterwards.
2. `maxEntityBodySize` applies to each request on its own, so the requests on a keep-alive connection do not share one budget. It does not apply to HTTP/2 streams.
3. When `maxEntityBodySize` is set, a request is not dispatched until its whole body has arrived, so a request whose body exceeds the limit never reaches the service:
   - A request whose `Content-Length` header exceeds the limit is answered with `413 Payload Too Large` without its body being read.
   - A request whose body exceeds the limit as it arrives, such as a chunked request, is answered with `413 Payload Too Large`.
4. In both cases of rule 3 the connection is closed after the response. If an earlier request on the connection has not been answered yet, the connection is closed without the `413 Payload Too Large` response, which the client would otherwise take as the response to the earlier request.
5. The idle timeout keeps applying while the body arrives, and each part of the body that is read counts as activity. A request that stays idle before its body is complete is answered with `408 Request Timeout`.
6. A request with an `Expect: 100-continue` header and no `Content-Length` over the limit is dispatched as soon as its headers arrive, since the client sends the body only after the service answers. Its body is counted as the service reads it, and the connection is closed once the body exceeds the limit. The `413 Payload Too Large` response is sent only if the service has not already responded.

### 3.6. Default listener

1. `getDefaultListener()` returns a listener that is shared by all its callers. The listener is created on the first call, and every later call returns the same listener. The function does not start the listener.
2. The port of the default listener is the `defaultListenerPort` configurable, whose default is `9090`.
3. The configuration of the default listener is the `defaultListenerConfig` configurable of type `ListenerConfiguration`, whose default is `{}`.
4. The function returns a `ListenerError` when the listener cannot be created.

## 4. Service

### 4.1. Description

A service is a service object whose type is a subtype of the `Service` type. It is created with a service declaration, a service class, or a service constructor expression, and attached to a listener. The library also defines the following service types:

- `ServiceContract`: A service object type that includes it defines the contract of a service. See [Service contract](#45-service-contract).
- `InterceptableService`: A service that includes it defines its interceptor pipeline. See [Interceptors](#9-interceptors).

### 4.2. Base path

The base path of a service is given by the `attach` call, or by the attach point of a service declaration, and is normalized as follows:

1. When it is `()`, the base path is `/`.
2. When it is a string, it is trimmed and split into segments on `/`. When it is a `string[]`, each member is a segment. A leading `/` is not required.
3. Each segment is unescaped, so that `hello\-world` becomes `hello-world`, and then percent-encoded. The segments are joined with `/`, prefixed with `/`.
4. Empty segments are removed, a trailing `/` is removed, and a trailing `*` is removed.

For a service implemented from a service contract type, the base path is the `basePath` field of the `ServiceConfig` annotation of the contract type. When the field is absent, the base path is `/`. When it is empty or blank, the base path is `/` followed by the name of the service contract type.

### 4.3. Compile-time validation

The compiler plugin validates service declarations attached to a listener of this library, and object type descriptors that are subtypes of `Service`. Service classes and service constructor expressions are validated at runtime when they are attached. The validation rules for resources are given in [Resources](#5-resources) and [Resource parameters](#7-resource-parameters).

| Code       | Condition                                                                                                       |
|------------|-----------------------------------------------------------------------------------------------------------------|
| `HTTP_101` | The service has a remote method.                                                                                |
| `HTTP_119` | `mediaTypeSubtypePrefix` ends with a suffix (`+...`).                                                           |
| `HTTP_120` | `mediaTypeSubtypePrefix` is not a valid media type subtype.                                                     |
| `HTTP_155` | `basePath` is set in `ServiceConfig` of a type that is not a service contract type.                            |
| `HTTP_157` | `serviceType` is set in `ServiceConfig` of a service that is not implemented from a service contract type.      |

### 4.4. Service configuration

The `ServiceConfig` annotation configures a service. It MAY be attached to a service or to a service contract type.

| Field                    | Type                   | Default        | Meaning                                                                                                                                                                                                                                 |
|--------------------------|------------------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `host`                   | `string`               | `"b7a.default"`| Host under which the service is registered. See [Service selection](#61-service-selection).                                                                                                                                             |
| `compression`            | `CompressionConfig`    | `{}`           | Compression of responses. See below.                                                                                                                                                                                                    |
| `chunking`               | `Chunking`             | `CHUNKING_AUTO`| Transfer encoding of responses. `CHUNKING_AUTO` uses `Content-Length` for payloads smaller than 8 KB and chunked encoding otherwise. `CHUNKING_ALWAYS` always uses chunked encoding. `CHUNKING_NEVER` never uses chunked encoding.      |
| `cors`                   | `CorsConfig`           | `{}`           | CORS configuration. See [CORS](#66-cors).                                                                                                                                                                                               |
| `auth`                   | `ListenerAuthConfig[]` | absent         | Declarative authentication and authorization. See [Declarative authentication](#151-declarative-listener-authentication).                                                                                                               |
| `mediaTypeSubtypePrefix` | `string`               | absent         | When present, the content type `type/subtype` of every response is rewritten to `type/<prefix>+subtype`.                                                                                                                                |
| `treatNilableAsOptional` | `boolean`              | `true`         | Whether a nilable query or header parameter whose value is absent is bound to `()`. See [Query parameters](#74-query-parameters).                                                                                                       |
| `openApiDefinition`      | `byte[]`               | `[]`           | OpenAPI definition of the service. It is used only when the compiler plugin has not generated a definition for the service.                                                                                                             |
| `validation`             | `boolean`              | `true`         | Whether constraint validation is applied to bound parameters and payloads.                                                                                                                                                              |
| `serviceType`            | `typedesc`             | absent         | Service contract type that the service implements. The compiler plugin sets it for services implemented from a service contract type.                                                                                                   |
| `basePath`               | `string`               | absent         | Base path of a service contract type. It MUST NOT be set on other types.                                                                                                                                                                |
| `laxDataBinding`         | `boolean`              | `false`        | Relaxed binding of JSON payloads to records. See [Payload parameter](#76-payload-parameter).                                                                                                                                            |

`CompressionConfig` has the fields `enable` of type `Compression` (default `COMPRESSION_AUTO`) and `contentTypes` of type `string[]` (default `[]`):

1. With `COMPRESSION_AUTO`, a response is compressed according to the `Accept-Encoding` header of the request.
2. With `COMPRESSION_ALWAYS`, a response is compressed, using gzip when the request has no `Accept-Encoding` header or only `identity`.
3. With `COMPRESSION_NEVER`, a response is not compressed, and its `Content-Encoding` is `identity`.
4. When `contentTypes` is not empty, a response whose content type does not contain any of its members is not compressed.
5. A `Content-Encoding` header set by the service is not changed.

### 4.5. Service contract

A service contract type is a service object type that includes `ServiceContract`. A service declaration whose type is a service contract type implements that contract.

1. The base path of the service is derived from the contract type, as described in [Base path](#42-base-path).
2. The annotations of the contract type and its resources apply to the service.
3. The service MUST NOT have a base path in its declaration, MUST NOT have resources that are not defined in the contract type, and MUST NOT have HTTP annotations on its resources or parameters. Its `ServiceConfig` annotation MAY only have the `serviceType` and `openApiDefinition` fields.

| Code       | Condition                                                                                                                         |
|------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `HTTP_153` | The service has a `ServiceConfig` annotation with fields other than `serviceType` and `openApiDefinition`.                       |
| `HTTP_154` | The service declaration has a base path.                                                                                          |
| `HTTP_156` | `serviceType` in `ServiceConfig` is not the contract type of the service.                                                         |
| `HTTP_158` | The service has a resource that is not defined in the contract type.                                                              |
| `HTTP_159` | A resource has a `ResourceConfig` annotation.                                                                                     |
| `HTTP_160` | A resource or parameter has another HTTP annotation.                                                                              |

### 4.6. OpenAPI resources

1. For a service with the `@openapi:ServiceInfo {embed: true}` annotation and without a `contract` field in that annotation, the compiler plugin generates the OpenAPI definition of the service, and the listener serves it through two generated resources:
   - `get openapi-doc-dygixywsw`, which returns the definition as `application/json`.
   - `get swagger-ui-dygixywsw`, which returns an HTML page that renders the definition with Swagger UI loaded from `unpkg.com`.
2. A `204 No Content` response to an `OPTIONS` request on the service has a `Link` header with the paths of these resources, with the relations `service-desc` and `swagger-ui`.
3. A user-defined resource with the same accessor and path as a generated resource causes the attach to fail.

#### Example

```ballerina
@openapi:ServiceInfo {embed: true}
service /hello on new http:Listener(9090) {
    resource function get greeting() returns string => "Hello, World!";
}
// OPTIONS /hello → 204 No Content
// link: </hello/openapi-doc-dygixywsw>;rel="service-desc", </hello/swagger-ui-dygixywsw>;rel="swagger-ui"
```

## 5. Resources

### 5.1. Description

A resource is a resource method of a service. Its accessor determines the HTTP methods it handles, and its resource path determines the request paths it handles, relative to the base path of the service.

### 5.2. Accessors

1. The HTTP method handled by a resource is its accessor name in upper case, e.g. `get` handles `GET`. Any accessor name is allowed, so custom methods such as `copy` handle `COPY`.
2. The request method is compared with the upper-cased accessor name exactly, so a request method in lower case does not match.
3. The `default` accessor handles every HTTP method for which the same resource path has no resource with a matching accessor.

### 5.3. Resource paths

1. A resource path consists of segments separated by `/`, without a leading `/`. The resource path `.` denotes the base path itself.
2. A literal segment is an identifier. Characters that are not allowed in an identifier MUST be escaped, e.g. `hello\-world`. The segment is unescaped and percent-encoded before matching.
3. A path parameter `[T name]` matches exactly one segment. `T` MUST be a subtype of exactly one of `string`, `int`, `float`, `decimal` and `boolean`. Finite types, enums and constrained types satisfying this rule are allowed. Unions of these types and nilable types are not.
4. A rest parameter `[T... name]` matches the remaining segments, including none. It MUST be the last segment, and `T` follows rule 3.
5. Two resources of a service conflict when they have the same accessor and their paths have the same literal segments at the same positions and parameters at the same positions, regardless of the names and types of the parameters. Attaching a service with conflicting resources fails with a `ListenerError`.

| Code       | Condition                                                                         |
|------------|-----------------------------------------------------------------------------------|
| `HTTP_145` | A path parameter or rest parameter has a type that does not satisfy rule 3.       |

### 5.4. Resource configuration

The `ResourceConfig` annotation configures a resource.

| Field                   | Type                             | Default | Meaning                                                                                                                                                                                                    |
|-------------------------|----------------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`                  | `string`                         | absent  | Link name of the resource. See [Links](#88-links).                                                                                                                                                        |
| `consumes`              | `string[]`                       | `[]`    | Media types accepted in the request `Content-Type`. `[]` accepts any. See [Resource selection](#63-resource-selection).                                                                                   |
| `produces`              | `string[]`                       | `[]`    | Media types that the resource produces, matched against the request `Accept` header. `[]` accepts any. See [Resource selection](#63-resource-selection).                                                  |
| `cors`                  | `CorsConfig`                     | `{}`    | CORS configuration of the resource. See [CORS](#66-cors).                                                                                                                                                 |
| `transactionInfectable` | `boolean`                        | `true`  | When `false`, a request with an `X-XID` header, which propagates a distributed transaction, is rejected.                                                                                                  |
| `auth`                  | `ListenerAuthConfig[]\|Scopes`   | absent  | Declarative authentication and authorization of the resource. See [Declarative authentication](#151-declarative-listener-authentication).                                                                 |
| `linkedTo`              | `LinkedTo[]`                     | absent  | Resources linked from this resource. See [Links](#88-links).                                                                                                                                              |

## 6. Request dispatching

### 6.1. Service selection

The listener selects the service for a request as follows:

1. If the `Host` header of the request is equal to the `host` of the `ServiceConfig` annotation of one or more attached services, the candidates are those services. The comparison is a case-sensitive string comparison that includes the port, so the host `localhost` does not match the header `localhost:9090`. Otherwise, the candidates are the services registered under the default host. If there are no candidates, the result is a `ServiceNotFoundError` (`404 Not Found`).
2. The matrix parameters are removed from the request path, as described in [Matrix parameters](#62-matrix-parameters).
3. The request target is split at the first `?` into the path and the query. Text after a second `?` is ignored.
4. The candidate base paths are compared with the request path in order of decreasing length. A base path matches when its segments are equal to the leading segments of the request path. Segments are compared case-sensitively after percent-decoding the request path. Empty segments are ignored, and dot segments (`.` and `..`) are compared literally without normalization.
5. The first base path that matches selects its service. If none matches and a service is attached at `/`, that service is selected. Otherwise, the result is a `ServiceNotFoundError` (`404 Not Found`).
6. The sub-path is the part of the request path after the base path, or `/` when the request path is the base path. A trailing `/` of the sub-path is ignored.

### 6.2. Matrix parameters

1. Each segment of the request path is split on `;`. The first part is the segment, and each other part MUST have the form `name=value`. If any part does not, the result is a `BadMatrixParamError` (`400 Bad Request`), whether or not a service would match.
2. The matrix parameters are available through `Request.getMatrixParams(path)`, where `path` is the request path up to and including the segment, without matrix parameters, e.g. `/hello/t1/john`. The values are returned without percent-decoding. When a segment has the same parameter more than once, the last value is used.

### 6.3. Resource selection

The resource of the selected service is chosen by matching the sub-path against the resource paths:

1. The resource paths form a tree of segments. The children of a node are tried in the following order: literal segments, longer ones first; then the path parameter; then the rest parameter. All path parameters at the same position of different resources share one node.
2. A literal segment matches a request segment that is equal to it, compared case-sensitively after percent-decoding the request segment. A path parameter matches any one segment. A rest parameter matches all the remaining segments, including none.
3. The tree is searched depth-first. When a subtree does not lead to a selected resource, the next child is tried.
4. At a node where the whole sub-path has been matched, the resource is chosen as follows:
   1. The resource whose accessor matches the request method, otherwise the `default` resource. If there is neither, the request is a candidate `405 Method Not Allowed`, and the search continues with rule 3. An `OPTIONS` request is handled as described in [Automatic OPTIONS responses](#64-automatic-options-responses).
   2. If the resource has a non-empty `consumes`, the media type of the request `Content-Type`, without parameters, MUST be equal to one of its members, compared case-insensitively. A request without `Content-Type` is treated as `application/octet-stream`. Otherwise, the request is a candidate `415 Unsupported Media Type`, and the search continues with rule 3.
   3. If the resource has a non-empty `produces` and the request has an `Accept` header other than `*/*`, one of the media ranges of the header MUST match one of its members. A range `type/*` matches any member with that type, and other ranges match a member equal to them, compared case-insensitively. Quality values are ignored. Otherwise, the request is a candidate `406 Not Acceptable`, and the search continues with rule 3.
   4. Otherwise, the resource is selected and the search stops.
5. If no resource is selected, the result is the last candidate error recorded during the search: `ResourceMethodNotAllowedError` (405), `UnsupportedRequestMediaTypeError` (415) or `RequestNotAcceptableError` (406). If no candidate error was recorded, the result is a `ResourceNotFoundError` (`404 Not Found`).

A `HEAD` request is matched like any other method. It is not dispatched to a `get` resource.

> **Note:** Because the search backtracks, a service with `resource function get foo()` and `resource function 'default [string... path]()` dispatches `POST /foo` to the default resource rather than responding with `405 Method Not Allowed`.

### 6.4. Automatic OPTIONS responses

1. When an `OPTIONS` request matches a node that has no `options` and no `default` resource, the listener responds with `204 No Content` and an `Allow` header listing the methods of the resources at that node and `OPTIONS`. If the request is a CORS preflight request, it is processed as described in [CORS](#66-cors).
2. When an `OPTIONS` request does not match any node and its request target is equal to the base path, the `Allow` header lists the methods of all resources of the service and `OPTIONS`. If the service has a `default` resource, it lists all the standard methods.
3. The response has a `Link` header to the [OpenAPI resources](#46-openapi-resources) when the service has them.
4. Otherwise, the result is a `ResourceNotFoundError` (`404 Not Found`).

### 6.5. Path parameter binding

1. The value of a path parameter is the matched segment, percent-decoded once. A `+` in the segment is not decoded to a space.
2. The value of a rest parameter is the list of the matched segments, each percent-decoded once.
3. The value is converted to the declared type. An `int` value is parsed as a decimal integer, a `float` value as a floating point number, a `decimal` value as a decimal number, and a `boolean` value as `true` or `false`, case-insensitively.
4. When the value cannot be converted, the result is a `PathParameterBindingError` (`400 Bad Request`). When the declared type is a finite type and the value is not a member of it, the result is a `ResourceNotFoundError` (`404 Not Found`).
5. When `validation` is enabled, the constraints of the declared type are validated. A violation results in a `ResourcePathValidationError` (`400 Bad Request`).

### 6.6. CORS

The `cors` field of the `ServiceConfig` and `ResourceConfig` annotations is a `CorsConfig`:

| Field              | Type       | Default | Meaning                                                                                       |
|--------------------|------------|---------|-----------------------------------------------------------------------------------------------|
| `allowOrigins`     | `string[]` | `[]`    | Origins allowed to access the resource. `["*"]` allows any origin.                            |
| `allowCredentials` | `boolean`  | `false` | Whether `Access-Control-Allow-Credentials: true` is sent.                                     |
| `allowHeaders`     | `string[]` | `[]`    | Request headers allowed in actual requests.                                                   |
| `allowMethods`     | `string[]` | `[]`    | Methods allowed in actual requests. `["*"]` allows any method.                                |
| `exposeHeaders`    | `string[]` | `[]`    | Response headers exposed to the client.                                                       |
| `maxAge`           | `decimal`  | `-1`    | Duration for which the result of a preflight request may be cached.                            |

1. A `CorsConfig` is _enabled_ when any of its arrays is non-empty, `allowCredentials` is `true`, or `maxAge` is greater than or equal to `0`. An enabled configuration with an empty `allowOrigins` allows any origin. An enabled service configuration with an empty `allowMethods` allows any method, and an enabled resource configuration with an empty `allowMethods` allows the methods of the resource.
2. A resource with an enabled `cors` configuration uses it, and ignores the service configuration entirely. Otherwise, the resource uses the service configuration.
3. For a request with an `Origin` header that is dispatched to a resource with an enabled configuration:
   - If all the origins of the header are allowed, the response has `Access-Control-Allow-Origin` set to the origins of the request, `Access-Control-Allow-Credentials: true` when `allowCredentials` is `true`, and `Access-Control-Expose-Headers` when `exposeHeaders` is not empty.
   - Otherwise, the response has no CORS headers. The request is still processed.
4. An `OPTIONS` request handled as in [Automatic OPTIONS responses](#64-automatic-options-responses) is a preflight request when it has exactly one origin in its `Origin` header and a single value in its `Access-Control-Request-Method` header. It is accepted when a resource at the node handles the requested method (`HEAD` is checked against `GET`), the origin and the method are allowed by the configuration of that resource, and every header of `Access-Control-Request-Headers` is in `allowHeaders`, compared case-insensitively, or `allowHeaders` is empty.
5. The response to an accepted preflight request has `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials` as in rule 3, `Access-Control-Allow-Methods` set to the requested method, `Access-Control-Allow-Headers` set to the requested headers, and `Access-Control-Max-Age` set to `maxAge`. It has no `Allow` header.
6. A preflight request whose path matches an `options` or `default` resource is dispatched to that resource.

### 6.7. Dispatching errors

| Condition                                                    | Error                              | Status                       |
|--------------------------------------------------------------|------------------------------------|------------------------------|
| No service matches                                           | `ServiceNotFoundError`             | `404 Not Found`              |
| A matrix parameter is malformed                              | `BadMatrixParamError`              | `400 Bad Request`            |
| No resource path matches                                     | `ResourceNotFoundError`            | `404 Not Found`              |
| A resource path matches, but no accessor matches the method  | `ResourceMethodNotAllowedError`    | `405 Method Not Allowed`     |
| `consumes` does not match                                    | `UnsupportedRequestMediaTypeError` | `415 Unsupported Media Type` |
| `produces` does not match                                    | `RequestNotAcceptableError`        | `406 Not Acceptable`         |
| An internal failure during dispatching                       | `ResourceDispatchingServerError`   | `500 Internal Server Error`  |

These errors are handled as described in [Error handling](#10-error-handling).

## 7. Resource parameters

### 7.1. Parameter classification

A resource MAY have any number of parameters in any order. Each parameter is classified as follows:

1. A parameter of type `Caller`, `Request`, `Headers`, `RequestContext` or `error` is a special parameter. A resource MUST NOT have more than one parameter of each of these types.
2. A parameter with the `@http:Payload` annotation is the payload parameter, and one with the `@http:Header` annotation is a header parameter. A parameter MUST NOT have more than one of the `@http:Payload`, `@http:Header`, `@http:Query` and `@http:CallerInfo` annotations, and a resource MUST NOT have more than one payload parameter.
3. In a resource whose accessor is not `get`, `head` or `options`, and which has no `@http:Payload` parameter, a parameter without an annotation is the payload parameter when its type, or each non-nil member of its union type, is one of: `byte[]`, `xml`, or a subtype of `map<anydata>`, `table<map<anydata>>`, an anydata tuple, or an array whose member type is not one of `string`, `int`, `float`, `decimal` and `boolean`. At most one parameter can be inferred this way. When two parameters qualify, the resource is rejected at compile time, and one of them MUST be annotated with `@http:Payload` or `@http:Query`.
4. Every other parameter is a query parameter.

### 7.2. Special parameters

| Type             | Value                                                                                                                                                                    |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Caller`         | The caller of the request, used to respond explicitly. See [Responding with a caller](#85-responding-with-a-caller).                                                    |
| `Request`        | The request. Its payload can be read only once, by either the request or the payload parameter.                                                                          |
| `Headers`        | A read-only view of all the headers of the request.                                                                                                                      |
| `RequestContext` | The request context shared with the interceptors. See [Request context](#94-request-context).                                                                           |
| `error`          | The error handled by an error interceptor. In a resource of a service, it is an error value without meaning, and SHOULD NOT be used.                                     |

### 7.3. Names

The name of a query parameter is the `name` field of its `@http:Query` annotation, or else the name of the parameter without escapes. The name of a header parameter is the `name` field of its `@http:Header` annotation, or else the name of the parameter.

### 7.4. Query parameters

1. The type of a query parameter MUST be one of: `string`, `int`, `float`, `decimal`, `boolean`, a finite type of these, an array of these, `map<anydata>` (records included), an array of `map<anydata>`, or a nilable form of any of these.
2. The query is split on `&` into parameters, and each parameter on the first `=` into a name and a value. The name and the value are trimmed. The value is then split on `,` into multiple values, and each value is percent-decoded, so an encoded `%2C` is not split. A parameter without `=` has a name and no value. Names are case-sensitive.
3. A parameter of an array type is bound to all the values of all the occurrences of its name. A parameter of any other type is bound to the first value.
4. Each value is converted to the member type as described for path parameters in [Path parameter binding](#65-path-parameter-binding). A value for a `map<anydata>` type is parsed as JSON and converted to the declared type. When the conversion fails, the result is a `QueryParameterBindingError` (`400 Bad Request`).
5. When the request has no value for the parameter:
   - If the parameter has a default value, the default value is used.
   - Otherwise, if the type is nilable and either `treatNilableAsOptional` is `true` or the name is present without a value, the parameter is `()`.
   - Otherwise, the result is a `QueryParameterBindingError` (`400 Bad Request`).
6. When `validation` is enabled, the constraints of the declared type are validated. A violation results in a `QueryParameterValidationError` (`400 Bad Request`).
7. Query parameters of the request that have no corresponding parameter are ignored. They are available through `Request.getQueryParams()`.

### 7.5. Header parameters

1. The type of a header parameter MUST be one of: `string`, `int`, `float`, `decimal`, `boolean`, an array of these, a closed record whose fields have these types or their nilable forms, or a nilable form of any of these. A record MUST NOT have a rest field.
2. Header names are compared case-insensitively.
3. A parameter of an array type is bound to the values of all the header lines with its name. A parameter of any other type is bound to the value of the first one. The value of a header line is not split on commas.
4. When the request has the header with an empty value, a parameter of a nilable type is `()`. Otherwise, the result is a `HeaderBindingError` (`400 Bad Request`).
5. When the request does not have the header:
   - If the parameter has a default value, the default value is used.
   - Otherwise, if the type is nilable and `treatNilableAsOptional` is `true`, the parameter is `()`.
   - Otherwise, the result is a `HeaderBindingError` (`400 Bad Request`).
6. Each field of a record parameter is bound as a separate header, named by the `name` field of the `@http:Header` annotation of the field, or else by the field name. When a field without a nilable type cannot be bound and the record parameter is nilable, the parameter is `()`. Otherwise, the result is a `HeaderBindingError` (`400 Bad Request`).
7. When a value cannot be converted, the result is a `HeaderBindingError` (`400 Bad Request`). When `validation` is enabled, the constraints of the declared type are validated. A violation results in a `HeaderValidationError` (`400 Bad Request`).

### 7.6. Payload parameter

1. The type of the payload parameter MUST be a subtype of `anydata`, optionally intersected with `readonly`.
2. The whole request body is read before the resource is invoked.
3. The body is converted according to the `Content-Type` of the request, compared case-insensitively and without parameters, using the first matching row:

   | Content-Type                                                                            | Conversion                                                                                                                                                                                         |
   |-----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
   | `application/xml`, `text/xml`, or a type with the `+xml` or `.xml` suffix               | Parsed as XML. The type MUST contain `xml`.                                                                                                                                                        |
   | `text/plain` or a type with the `+plain` suffix, `application/x-www-form-urlencoded`    | Read as text. The value is bound to `string` or a finite string type as is, to `byte[]` as UTF-8 bytes, or to `map<string>` after decoding it as a form.                                           |
   | `application/octet-stream` or a type with the `+octet-stream` suffix                    | Read as bytes. The type MUST be `byte[]`.                                                                                                                                                          |
   | `application/json`, `text/json`, or a type with the `+json` or `.json` suffix           | Parsed as JSON and converted to the declared type.                                                                                                                                                 |
   | Absent, or any other media type                                                         | Chosen by the declared type: `string` is read as text, `xml` is parsed as XML, `byte[]` is read as bytes, and any other type is parsed as JSON.                                                    |

4. When the body cannot be converted to the declared type, the result is a `PayloadBindingError` (`400 Bad Request`). A request is never rejected with `415 Unsupported Media Type` because of its payload. Only `consumes` causes `415 Unsupported Media Type`.
5. When the body is empty, a parameter of a nilable type is `()`. Otherwise, the result is a `PayloadBindingError` (`400 Bad Request`). A default value of the payload parameter is not used.
6. JSON is converted to a closed record strictly: a field of the payload that is not in the record is an error. When `laxDataBinding` is `true` and the declared type contains a record type, JSON is converted with data projection, a `null` value of an optional field that is not nilable is treated as absent, and an absent field of a nilable type is treated as `null`.
7. When the declared type is an intersection with `readonly`, the value is read-only.
8. When `validation` is enabled, the constraints of the declared type are validated. A violation results in a `PayloadValidationError` (`400 Bad Request`).
9. The `mediaType` field of the `@http:Payload` annotation on a parameter is used for documentation and OpenAPI generation. It is not checked against the request.

### 7.7. Compile-time validation

| Code                                         | Condition                                                                                                     |
|----------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| `HTTP_105`, `HTTP_106`                       | A parameter has a type that is not allowed for any kind of parameter.                                         |
| `HTTP_107`                                   | The payload parameter type is not a subtype of `anydata`.                                                     |
| `HTTP_108`                                   | A parameter has more than one HTTP annotation.                                                                |
| `HTTP_109`, `HTTP_110`, `HTTP_144`           | A header parameter type does not satisfy rule 1 of [Header parameters](#75-header-parameters).                |
| `HTTP_111`                                   | A parameter with `@http:CallerInfo` is not of type `Caller`.                                                  |
| `HTTP_112`, `HTTP_113`                       | A query parameter type does not satisfy rule 1 of [Query parameters](#74-query-parameters).                  |
| `HTTP_115`, `HTTP_116`, `HTTP_117`, `HTTP_121`, `HTTP_122` | More than one parameter of type `Caller`, `Request`, `Headers`, `RequestContext` or `error`.     |
| `HTTP_129`                                   | A `get`, `head` or `options` resource has a `@http:Payload` parameter.                                        |
| `HTTP_133`, `HTTP_134`                       | A parameter has an intersection type other than `readonly & T` with `T` allowed for the parameter.            |
| `HTTP_151`                                   | More than one parameter qualifies as the inferred payload parameter.                                          |
| `HTTP_152`                                   | An inferred payload parameter has a union of structured and non-structured types.                             |

## 8. Responses

### 8.1. Return types

1. The return type of a resource MUST be a subtype of `anydata|Response|StatusCodeResponse|stream<SseEvent, error?>|stream<SseEvent, error>|error`.
2. A resource with a `Caller` parameter MUST have a return type that is a subtype of `error?`.
3. The value returned by the resource is converted to the response as described in this section, unless the resource has already responded through its `Caller`. In that case, nothing more is sent, and a returned value other than `()` is logged as a warning.

### 8.2. Status codes

| Returned value                                                   | Status                                                                                       |
|------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `()`, in a resource without a `Caller` parameter                 | `202 Accepted`, without a body                                                               |
| `()`, in a resource with a `Caller` parameter that has not responded | `500 Internal Server Error`, without a body                                             |
| An `anydata` value, from a `post` resource                       | `201 Created`                                                                                |
| An `anydata` value, from any other resource                      | `200 OK`. This includes a `default` resource handling a `POST` request.                      |
| A status code response                                           | The status code of its type                                                                  |
| A `Response`                                                     | The status code of the response                                                              |
| A stream of `SseEvent`                                           | `200 OK`. See [Server-sent events](#86-server-sent-events).                                  |
| An `error`                                                       | See [Error handling](#10-error-handling).                                                    |

### 8.3. Content type and serialization

1. An `anydata` value, or the `body` of a status code response, is serialized as follows:

   | Value                    | Serialization                   | Default content type        |
   |--------------------------|---------------------------------|-----------------------------|
   | `()`                     | No body                         | None                        |
   | `xml`                    | XML                             | `application/xml`           |
   | `string`                 | Text                            | `text/plain`                |
   | `byte[]`                 | Bytes                           | `application/octet-stream`  |
   | Any other `anydata`      | JSON, using `jsondata:toJson`   | `application/json`          |

2. The content type of the response is the first of the following that is present:
   1. The `mediaType` field of a status code response.
   2. The `mediaType` field of the `@http:Payload` annotation on the return type. When it is an array, its first member is used.
   3. The `Content-Type` in the `headers` field of a status code response.
   4. The default content type of the value.
3. For a returned `Response`, the `mediaType` of the `@http:Payload` annotation is used only when the response has no `Content-Type`.
4. When the content type is `application/x-www-form-urlencoded` and the value is a map, the value is encoded as a form.
5. The `mediaType` of the `@http:Payload` annotation on the return type is not checked against the `Accept` header of the request. Only `produces` causes `406 Not Acceptable`.
6. When the service has a `mediaTypeSubtypePrefix`, it is applied to the content type of every response, as described in [Service configuration](#44-service-configuration).

### 8.4. Status code responses

The library defines a closed record type for each standard status code, e.g. `Ok`, `Created` and `NotFound`, and `DefaultStatusCodeResponse` for other codes. Each has the following fields:

| Field       | Type                                                         | Meaning                                                                       |
|-------------|--------------------------------------------------------------|-------------------------------------------------------------------------------|
| `status`    | read-only status record                                      | The status code. It is fixed by the type, except for `DefaultStatusCodeResponse`. |
| `mediaType` | `string`, optional                                           | The content type of the response.                                             |
| `headers`   | `map<string\|int\|boolean\|string[]\|int[]\|boolean[]>`, optional | Headers of the response.                                                  |
| `body`      | `anydata`, optional                                          | The payload of the response.                                                  |

`NoContent` has no `mediaType` and no `body` field. A user-defined subtype MAY narrow the types of `headers` and `body`.

### 8.5. Responding with a caller

1. `Caller->respond(message)` sends the response to the request. `message` MAY be a `Response`, a status code response, an `anydata` value, a `mime:Entity[]`, a `stream<byte[], io:Error?>`, a stream of `SseEvent`, or an `error`. An `error` is converted to a response as described in [Error handling](#10-error-handling).
2. An `anydata` message from a `post` resource results in `201 Created`, and from any other resource in `200 OK`.
3. A `Response` value can be sent only once. Sending it again returns a `ListenerError`, and the request is answered with `500 Internal Server Error`. The behaviour of responding to the same request more than once is unspecified.
4. The `@http:CallerInfo {respondType: T}` annotation on the `Caller` parameter declares the type of the response. The compiler plugin checks that the arguments of `respond()` are of type `T`. It has no runtime effect.

| Code       | Condition                                                                                                 |
|------------|-----------------------------------------------------------------------------------------------------------|
| `HTTP_114` | The argument of `respond()` is not of the type declared by `@http:CallerInfo`.                             |

### 8.6. Server-sent events

1. When a resource returns a stream of `SseEvent`, each event is written to the response as it is produced, in the `text/event-stream` format.
2. The response has `Content-Type: text/event-stream` and `Cache-Control: no-cache`. On an HTTP/1.1 connection, it also has `Transfer-Encoding: chunked` and `Connection: keep-alive`, and the connection is kept open.
3. The response ends when the stream ends.

### 8.7. Response caching headers

The `@http:Cache` annotation on the return type of a resource adds caching headers to its responses. It applies to `anydata` values and to status code responses with a `2XX` status. It is ignored for other values.

| Field             | Type       | Default | Meaning                                                                    |
|-------------------|------------|---------|----------------------------------------------------------------------------|
| `mustRevalidate`  | `boolean`  | `true`  | Adds the `must-revalidate` directive.                                      |
| `noCache`         | `boolean`  | `false` | Adds the `no-cache` directive, with `noCacheFields` when not empty.        |
| `noStore`         | `boolean`  | `false` | Adds the `no-store` directive.                                             |
| `noTransform`     | `boolean`  | `false` | Adds the `no-transform` directive.                                         |
| `isPrivate`       | `boolean`  | `false` | Adds `private`, with `privateFields` when not empty, instead of `public`.  |
| `proxyRevalidate` | `boolean`  | `false` | Adds the `proxy-revalidate` directive.                                     |
| `maxAge`          | `decimal`  | `3600`  | Adds `max-age`, rounded down, when greater than or equal to `0`.           |
| `sMaxAge`         | `decimal`  | `-1`    | Adds `s-maxage`, rounded down, when greater than or equal to `0`.          |
| `noCacheFields`   | `string[]` | `[]`    | Field names of the `no-cache` directive.                                   |
| `privateFields`   | `string[]` | `[]`    | Field names of the `private` directive.                                    |
| `setETag`         | `boolean`  | `true`  | Adds an `ETag` header.                                                     |
| `setLastModified` | `boolean`  | `true`  | Adds a `Last-Modified` header with the time of the response.               |

1. The `Cache-Control` directives are written in the order of the table. Either `public` or `private` is always written.
2. The `ETag` value is the CRC32 checksum of the payload in hexadecimal, without quotes. It is added only for `xml`, `string`, `byte[]` and JSON payloads.
3. The listener does not evaluate conditional requests, so it does not respond with `304 Not Modified`.

| Code       | Condition                                                                                                  |
|------------|------------------------------------------------------------------------------------------------------------|
| `HTTP_130` | `@http:Cache` is used on a return type that contains neither `anydata` nor a success status code response. |

### 8.8. Links

The `linkedTo` field of `ResourceConfig` records links from a resource to other resources of the same service.

1. A `LinkedTo` value has the fields `name` (the link name of the target resource), `relation` (default `"self"`) and `method` (optional). `name` and `relation` are compared case-insensitively, and `method` is compared after conversion to upper case.
2. The target is the resource whose `ResourceConfig` has the same `name`. Several resources MAY share a link name only when they have the same path, and then `method` MUST be given to select one. The relations of the links of a resource MUST be unique.
3. For each link, a `Link` record is created with `rel` set to the relation, `href` set to the path of the target relative to the listener, with path parameters written as `{name}`, `methods` set to the method of the target, and `types` set to the media types the target produces, when known.
4. When the response of the resource is an `anydata` value or the `body` of a `2XX` status code response, and it is a mapping without a `_links` field to which a field can be added, the links are added to it as the `_links` field, a map from relation to `Link`. Otherwise, when the response has no `Link` header, the links are added as a `Link` header in the form `<href>; rel="relation"; methods="METHOD"`, separated by `, `.
5. Links are not added when the resource returns a `Response`.

| Code       | Condition                                                                                             |
|------------|-------------------------------------------------------------------------------------------------------|
| `HTTP_146` | Resources with the same link name have different paths.                                               |
| `HTTP_147` | The links of a resource have duplicate relations.                                                     |
| `HTTP_148` | No resource has the link name.                                                                        |
| `HTTP_149` | Several resources have the link name, and `method` is not given.                                      |
| `HTTP_150` | No resource with the link name has the given method.                                                  |

### 8.9. Compile-time validation

| Code       | Condition                                                                                    |
|------------|----------------------------------------------------------------------------------------------|
| `HTTP_102` | The return type does not satisfy rule 1 of [Return types](#81-return-types).                 |
| `HTTP_118` | A resource with a `Caller` parameter returns a type that is not a subtype of `error?`.       |
| `HTTP_131` | `@http:Payload` is used on a return type that has no payload, such as `error?`.              |

## 9. Interceptors

### 9.1. Description

Interceptors run common logic on the requests and responses of a service. A request interceptor runs before the resource, and a response interceptor runs after it. Error interceptors turn errors into responses.

### 9.2. Interceptor types

| Type                       | Member                                                     | Rules                                                                                                                         |
|----------------------------|------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `RequestInterceptor`       | Exactly one resource method, with any accessor and path    | Its parameters are bound as described in [Resource parameters](#7-resource-parameters).                                       |
| `RequestErrorInterceptor`  | Exactly one resource method `'default [string... path]`    | It MUST have an `error` parameter. Its other parameters are bound as for a request interceptor.                              |
| `ResponseInterceptor`      | Exactly one remote method `interceptResponse`              | Its parameters MAY only be of the types `RequestContext`, `Request`, `Response` and `Caller`.                                |
| `ResponseErrorInterceptor` | Exactly one remote method `interceptResponseError`         | It MUST have an `error` parameter. Its other parameters follow the rule of a response interceptor.                          |

1. The return type of an interceptor method MUST be a subtype of `anydata|Response|StatusCodeResponse|stream<SseEvent, error?>|stream<SseEvent, error>|NextService|error?`.
2. Interceptor methods and their return types MUST NOT have annotations.
3. An interceptor service class MUST include exactly one of the interceptor types.

### 9.3. Engaging interceptors

1. A service that includes `InterceptableService` defines its interceptor pipeline with the method `createInterceptors() returns Interceptor|Interceptor[]`. The method is called once, when the listener starts. When it returns an error, the error is logged and the service has no interceptors.
2. The pipeline of a service is `DefaultErrorInterceptor` followed by the interceptors returned by `createInterceptors()`, in order. `DefaultErrorInterceptor` is described in [Default error response](#102-default-error-response).
3. The resource path of a request interceptor is relative to the base path of the service. A request interceptor runs for a request only when its resource matches the request, as described in [Resource selection](#63-resource-selection). An interceptor that does not match is skipped.
4. When no service matches a request, the request is handled by the pipeline of the service attached at `/`, or by the pipeline of the only service of the listener when it has one service. Otherwise, it is handled by `DefaultErrorInterceptor` only.

### 9.4. Request context

A `RequestContext` is created for each request, and the same context is passed to every interceptor and to the resource.

1. `set(key, value)` stores a value. A value of type `Cloneable` is stored as a clone, and an `isolated object` is stored as is.
2. `get(key)` returns a clone of the value. It panics when the key is not present.
3. `getWithType(key, targetType)` returns the value converted to `targetType`, without cloning it. It returns a `ListenerError` when the key is not present or when the value cannot be converted.
4. `hasKey(key)` and `keys()` report the stored keys. `remove(key)` removes a value, and panics when the key is not present.
5. `next()` returns the next service in the pipeline, as described in [Execution](#95-execution). Called from a resource of a service, it returns an `InterceptorReturnError`.
6. When the request has an `Authorization` header of the form `Bearer <token>`, the context has the key `JWT_INFORMATION` with the decoded `[jwt:Header, jwt:Payload]` of the token. The token is decoded but not validated. When it cannot be decoded, the key is absent.

### 9.5. Execution

1. The request interceptors run in the order of the pipeline. A request interceptor continues the pipeline by returning the value of `ctx.next()`, which is the next matching request interceptor, or else the resource of the service. Returning any other service object results in an `InterceptorReturnError`.
2. When a request interceptor returns a value other than a service object or an error, the value becomes the response, as described in [Responses](#8-responses), and the response interceptors that precede it in the pipeline run.
3. The response interceptors run in the reverse order of the pipeline, starting from the end of the pipeline when the response comes from the resource. A response interceptor continues the pipeline by returning the value of `ctx.next()`. When it returns another value other than an error, that value replaces the response, and the pipeline continues.
4. When a request interceptor or a request error interceptor returns an error, the next request error interceptor in the pipeline handles it. If there is none, the response error interceptors handle it, starting from the end of the pipeline.
5. When the resource returns an error, or when dispatching to or binding the parameters of the resource fails, the response error interceptors handle the error, starting from the end of the pipeline. Request error interceptors do not handle these errors.
6. When a response interceptor or a response error interceptor returns an error, the next response error interceptor towards the start of the pipeline handles it. `DefaultErrorInterceptor`, at the start of the pipeline, handles every error that reaches it.
7. While an error is being handled, response interceptors are skipped. When an error interceptor returns a value, the error is handled, the value becomes the response, and the remaining response interceptors run.
8. When a request interceptor binds the payload, the request body is read in full before the interceptor runs.

> **Note:** The behaviour of an interceptor that returns `()` without calling `next()` is unspecified.

#### Example

![Interceptor pipeline](_resources/interceptor-pipeline.png)

In the above pipeline, the solid blue boxes (1, 2, 4) are request interceptors, the dashed blue box (6) is a request error interceptor, the solid green boxes (3, 5) are response interceptors, and the dashed green box (0) is a response error interceptor. `DefaultErrorInterceptor` precedes position 0.

- When no error occurs, the request interceptors run in the order 1, 2, 4, then the resource, then the response interceptors in the order 5, 3 (rules 1 and 3).
- When request interceptor 4 returns a response, only response interceptor 3 runs (rule 2).
- When request interceptor 2 returns an error, request error interceptor 6 handles it (rule 4). When 6 returns a value, it becomes the response, and response interceptors 5 and 3 run (rule 7).
- When the resource returns an error, response error interceptor 0 handles it, and response interceptors 5 and 3 are skipped (rules 5 and 7).

### 9.6. Compile-time validation

| Code                                 | Condition                                                                                          |
|--------------------------------------|----------------------------------------------------------------------------------------------------|
| `HTTP_123`                           | An interceptor includes more than one interceptor type.                                            |
| `HTTP_124`, `HTTP_132`               | A request interceptor has more than one resource method, or none.                                  |
| `HTTP_125`, `HTTP_142`               | An interceptor method or its return type has an annotation.                                        |
| `HTTP_126`, `HTTP_141`               | An interceptor method has a return type that does not satisfy rule 1 of [Interceptor types](#92-interceptor-types). |
| `HTTP_127`, `HTTP_128`               | A request error interceptor resource is not `'default [string... path]`.                          |
| `HTTP_135`, `HTTP_138`               | A response interceptor does not have exactly the required remote method.                           |
| `HTTP_136`, `HTTP_137`               | An interceptor has a resource or remote method that its type does not allow.                       |
| `HTTP_139`, `HTTP_140`               | A response interceptor method has a parameter that is not allowed, or more than one `Response`.    |
| `HTTP_143`                           | An error interceptor method has no `error` parameter.                                              |

## 10. Error handling

### 10.1. Status codes of errors

An error returned by a resource or an interceptor, or raised by the library while processing a request, is converted to a response with the following status code:

| Error                                                                                                                                          | Status                                                       |
|------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| A status code error of the `ballerina/http.httpscerr` module, e.g. `httpscerr:NotFoundError`                                                   | The status code of its type                                  |
| `httpscerr:DefaultStatusCodeError`                                                                                                             | `statusCode` of its detail, else the status of its cause, else `500 Internal Server Error` |
| `ApplicationResponseError`, i.e. a `ClientRequestError` or `RemoteServerError` from a client call                                              | The status code, headers and body of the remote response    |
| `ClientConnectorError`                                                                                                                         | `502 Bad Gateway`                                            |
| `PathParameterBindingError`, `QueryParameterBindingError`, `HeaderBindingError`, `PayloadBindingError`, and the corresponding validation errors | `400 Bad Request`                                            |
| `BadMatrixParamError`                                                                                                                          | `400 Bad Request`                                            |
| `ListenerAuthnError`                                                                                                                           | `401 Unauthorized`                                           |
| `ListenerAuthzError`                                                                                                                           | `403 Forbidden`                                              |
| `ServiceNotFoundError`, `ResourceNotFoundError`                                                                                                | `404 Not Found`                                              |
| `ResourceMethodNotAllowedError`                                                                                                                | `405 Method Not Allowed`                                     |
| `RequestNotAcceptableError`                                                                                                                    | `406 Not Acceptable`                                         |
| `UnsupportedRequestMediaTypeError`                                                                                                             | `415 Unsupported Media Type`                                 |
| `InterceptorReturnError`, `ResourceDispatchingServerError`                                                                                     | `500 Internal Server Error`                                  |
| Any other error                                                                                                                                | `500 Internal Server Error`                                  |

### 10.2. Default error response

`DefaultErrorInterceptor` is a response error interceptor at the start of every pipeline. For an error that reaches it:

1. Unless the error is raised by the library for a request it rejects, such as a binding or dispatching error, the error is logged with the path and the method of the request.
2. The response has the status code given in [Status codes of errors](#101-status-codes-of-errors), and the headers in the `headers` field of the error detail, when present.
3. When the error detail has a `body`, it is the payload of the response, serialized as described in [Content type and serialization](#83-content-type-and-serialization). Otherwise, the payload is the following JSON object, with `Content-Type: application/json`:

   | Field       | Value                                                    |
   |-------------|----------------------------------------------------------|
   | `timestamp` | Time of the response, in RFC 3339 format in UTC          |
   | `status`    | Status code                                              |
   | `reason`    | Reason phrase of the status code                         |
   | `message`   | Message of the error                                     |
   | `path`      | Raw path of the request                                  |
   | `method`    | Method of the request                                    |

4. A user-defined response error interceptor receives, as its `Response` parameter, a response with the status code of the error and the message of the error as a text payload.

### 10.3. Panics

When a resource or an interceptor panics, the listener responds with `500 Internal Server Error` and the message of the panic as a `text/plain` payload, without running the interceptors, prints the panic with its stack trace, and terminates the program with exit code `1`. Panics raised by [declarative authentication](#151-declarative-listener-authentication) are an exception, and are handled as errors.

## 11. Client

### 11.1. Description

A `Client` sends requests to one remote endpoint, given by a URL, and binds the responses to the types the caller expects. `StatusCodeClient` binds responses to status code responses. `LoadBalanceClient` and `FailoverClient` send requests to several endpoints, and are described in [Resiliency](#12-resiliency).

### 11.2. Initialization

1. When the URL has no scheme, `https://` is used if `secureSocket` or `auth` is configured, and `http://` otherwise.
2. A malformed URL, or any invalid configuration value, makes the initialization return a `ClientError`.
3. When `secureSocket` is configured and the URL uses `http://`, the TLS configuration is ignored and a warning is printed.

### 11.3. Configuration

`ClientConfiguration` has the following fields:

| Field             | Type                    | Default             | Meaning                                                                                                                                                                       |
|-------------------|-------------------------|---------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `httpVersion`     | `HttpVersion`           | `HTTP_2_0`          | HTTP version of the requests. With `HTTP_2_0`, the client negotiates HTTP/2 with ALPN over TLS, and over cleartext uses an `Upgrade: h2c` request unless `http2PriorKnowledge` is `true`. |
| `http1Settings`   | `ClientHttp1Settings`   | `{}`                | `keepAlive` (`KEEPALIVE_AUTO`) and `chunking` (`CHUNKING_AUTO`) of HTTP/1.x requests. Its `proxy` field is deprecated. See [Proxy](#118-proxy).                              |
| `http2Settings`   | `ClientHttp2Settings`   | `{}`                | `http2PriorKnowledge` (`false`) and `http2InitialWindowSize` (`65535`).                                                                                                      |
| `timeout`         | `decimal`               | `30`                | Idle timeout. When it elapses, the request fails with an `IdleTimeoutError`.                                                                                                 |
| `forwarded`       | `string`                | `"disable"`         | Handling of the `Forwarded` header when forwarding requests: `"enable"`, `"transition"` or `"disable"`, compared case-insensitively. Any other value is an initialization error. |
| `followRedirects` | `FollowRedirects?`      | `()`                | Redirect handling. See [Redirects](#116-redirects).                                                                                                                           |
| `poolConfig`      | `PoolConfiguration?`    | `()`                | Connection pool. `()` means a pool shared by all clients that do not configure one.                                                                                          |
| `cache`           | `CacheConfig`           | `{}`                | Response caching, enabled by default. See [Caching](#115-caching).                                                                                                           |
| `compression`     | `Compression`           | `COMPRESSION_AUTO`  | Whether the `Accept-Encoding` header is sent.                                                                                                                                |
| `auth`            | `ClientAuthConfig?`     | `()`                | Authentication of requests. See [Client authentication](#153-client-authentication).                                                                                         |
| `circuitBreaker`  | `CircuitBreakerConfig?` | `()`                | See [Circuit breaker](#122-circuit-breaker).                                                                                                                                 |
| `retryConfig`     | `RetryConfig?`          | `()`                | See [Retry](#121-retry).                                                                                                                                                     |
| `cookieConfig`    | `CookieConfig?`         | `()`                | See [Cookies](#117-cookies).                                                                                                                                                 |
| `responseLimits`  | `ResponseLimitConfigs`  | `{}`                | See [Response limits](#119-response-limits).                                                                                                                                 |
| `proxy`           | `ProxyConfig?`          | `()`                | See [Proxy](#118-proxy).                                                                                                                                                     |
| `socketConfig`    | `ClientSocketConfig`    | `{}`                | Socket options: `connectTimeOut` (`15`), `receiveBufferSize` (`1048576`), `sendBufferSize` (`1048576`), `tcpNoDelay` (`true`), `socketReuse` (`true`) and `keepAlive` (`false`). |
| `validation`      | `boolean`               | `true`              | Whether constraint validation is applied to bound response payloads.                                                                                                         |
| `laxDataBinding`  | `boolean`               | `false`             | Relaxed binding of JSON payloads to records, as for the [payload parameter](#76-payload-parameter).                                                                          |
| `secureSocket`    | `ClientSecureSocket?`   | `()`                | TLS configuration. See [TLS](#163-client).                                                                                                                                   |

`PoolConfiguration` has the fields `maxActiveConnections` (`-1`, unlimited), `maxIdleConnections` (`100`), `waitTime` (`30`), `maxActiveStreamsPerConnection` (`100`), `minEvictableIdleTime` (`300`), `timeBetweenEvictionRuns` (`30`), `minIdleTimeInStaleState` (`300`) and `timeBetweenStaleEviction` (`30`). Their defaults are configurables of the same names.

### 11.4. Feature composition

The features of a client are applied in the following order, from the call outwards to the network. A feature is present only when it is configured.

1. Circuit breaker
2. Redirects
3. Retry
4. Cookies
5. Caching
6. Authentication
7. The connection to the endpoint

Consequences of this order:

- A call and all its retries count as one request for the circuit breaker.
- The request to each redirect location is retried separately.
- Authentication headers are added to each attempt, including retries.
- A response served from the cache is not retried or redirected.

### 11.5. Caching

| Field            | Type            | Default                        | Meaning                                                                                       |
|------------------|-----------------|--------------------------------|-----------------------------------------------------------------------------------------------|
| `enabled`        | `boolean`       | `true`                         | Whether responses are cached.                                                                 |
| `isShared`       | `boolean`       | `false`                        | Whether the cache is a shared cache. A shared cache does not store `private` responses, and honours `s-maxage`. |
| `capacity`       | `int`           | `16`                           | Maximum number of cache entries.                                                              |
| `evictionFactor` | `float`         | `0.2`                          | Fraction of the entries evicted when the cache is full. It MUST be in the range (0, 1].       |
| `policy`         | `CachingPolicy` | `CACHE_CONTROL_AND_VALIDATORS` | Which responses are cached. See rule 2.                                                       |

1. Only responses to `GET` and `HEAD` requests are cached. Requests sent with `submit()` are not cached.
2. With `CACHE_CONTROL_AND_VALIDATORS`, a response is stored only if it has a `Cache-Control` header and an `ETag` or `Last-Modified` header. With `RFC_7234`, this condition does not apply.
3. A response is not stored when it has the `no-store` directive, when the request has the `no-store` directive, or when the cache is shared and the response has the `private` directive. Otherwise, it is stored when it has `max-age`, `s-maxage` with a shared cache, a `Cache-Control` header without `private`, or an `Expires` header, or when its status code is one of `200`, `203`, `204`, `206`, `300`, `301`, `404`, `405`, `410`, `414` and `501`.
4. The cache key is the method and the path of the request. The host and the `Vary` header are not part of the key.
5. A fresh cached response is returned without contacting the endpoint, unless the request or the cached response has the `no-cache` directive or the request has a `Pragma` header. Then the response is revalidated with a conditional request. A stale cached response is returned with a `Warning: 110` header when the request allows stale responses, and is revalidated otherwise.
6. A response with a `2XX` or `3XX` status to a request with any method other than `GET` and `HEAD` invalidates the cached responses of the same path.

### 11.6. Redirects

| Field              | Type      | Default | Meaning                                                                                   |
|--------------------|-----------|---------|-------------------------------------------------------------------------------------------|
| `enabled`          | `boolean` | `false` | Whether redirects are followed. When `false`, the field has no effect.                    |
| `maxCount`         | `int`     | `5`     | Maximum number of redirects followed for one call.                                        |
| `allowAuthHeaders` | `boolean` | `false` | Whether authentication headers are sent to redirect locations.                            |

1. Responses with the status codes `300`, `301`, `302`, `303`, `305`, `307` and `308` are followed. Other responses are returned.
2. For `301`, `302` and `303`, the request to the redirect location uses `GET`. For the other codes, it uses the original method and payload. The payload of a request with a method other than `GET`, `HEAD` and `OPTIONS` is read into memory before the first request so that it can be resent.
3. The redirect location is the `Location` header of the response. A relative location is resolved against the URL of the request. A response without a `Location` header makes the call return a `ClientError`.
4. The request to the redirect location uses the configuration of the client.
5. Unless `allowAuthHeaders` is `true`, the `Authorization` and `Proxy-Authorization` headers are removed, and configured `auth` is not applied, for redirect locations.
6. When `maxCount` redirects have been followed, the last redirect response is returned. The `resolvedRequestedURI` field of the response is the URL of the last request.
7. Redirects are followed for `get`, `post`, `put`, `patch`, `delete`, `head`, `options` and their resource method forms, and for `execute` with a standard method. They are not followed for `forward`, `submit` and `execute` with a custom method.
8. The redirect count of a call is not affected by other calls.

### 11.7. Cookies

| Field                     | Type                       | Default | Meaning                                                                         |
|---------------------------|----------------------------|---------|---------------------------------------------------------------------------------|
| `enabled`                 | `boolean`                  | `false` | Whether cookies are stored and sent.                                            |
| `maxCookiesPerDomain`     | `int`                      | `50`    | Maximum number of cookies stored for one domain.                                |
| `maxTotalCookieCount`     | `int`                      | `3000`  | Maximum number of cookies stored.                                               |
| `blockThirdPartyCookies`  | `boolean`                  | `true`  | Whether cookies for other domains are rejected.                                 |
| `persistentCookieHandler` | `PersistentCookieHandler`  | absent  | Store of persistent cookies. Without it, persistent cookies are not stored.     |

1. Cookies of `Set-Cookie` headers in responses are stored. A cookie that would exceed a limit is not stored, and the error is logged. It is not returned to the caller.
2. When `blockThirdPartyCookies` is `true`, a cookie whose `Domain` does not domain-match the host of the request, or whose `Path` does not path-match its path, is not stored. When it is `false`, the `Domain` and `Path` of cookies are not checked.
3. A request includes the stored cookies whose domain and path match the request. A cookie with the `Secure` attribute is sent only over `https`.

### 11.8. Proxy

| Field      | Type            | Default | Meaning                                         |
|------------|-----------------|---------|-------------------------------------------------|
| `host`     | `string`        | `""`    | Host of the proxy server.                       |
| `port`     | `int`           | `0`     | Port of the proxy server.                       |
| `userName` | `string`        | `""`    | User name for proxy authentication.             |
| `password` | `string`        | `""`    | Password for proxy authentication.              |
| `protocol` | `ProxyProtocol` | absent  | Proxy protocol. When absent, `HTTP` is used.    |

1. With `HTTP`, requests are sent through an HTTP proxy.
2. With `SOCKS4`, requests are sent through a SOCKS version 4 proxy. `userName` is sent as the SOCKS4 user id, and `password` is ignored with a warning. The target host is resolved by the client.
3. With `SOCKS5`, requests are sent through a SOCKS version 5 proxy, using `userName` and `password` for authentication. The target host is resolved by the proxy.
4. SOCKS proxies are supported for `http://` and `https://` URLs, over HTTP/1.1 and HTTP/2.
5. A proxy host that cannot be resolved makes the initialization return a `ClientError`.
6. The deprecated `proxy` field of `ClientHttp1Settings` is used only when `httpVersion` is `HTTP_1_1` and the `proxy` field of the configuration is `()`. Setting it prints a deprecation warning.

> **Note:** `protocol` is optional rather than defaultable, so that a mapping value without `protocol` remains assignable to `ProxyConfig`.

### 11.9. Response limits

| Field                 | Type  | Default | Meaning                                                                                                                       |
|-----------------------|-------|---------|-------------------------------------------------------------------------------------------------------------------------------|
| `maxStatusLineLength` | `int` | `4096`  | Maximum length of the status line. A negative value is an initialization error.                                              |
| `maxHeaderSize`       | `int` | `8192`  | Maximum total size of the response headers. A negative value is an initialization error.                                     |
| `maxEntityBodySize`   | `int` | `-1`    | Maximum size of the body of each HTTP/1.x response. `-1` means no limit. A value less than `-1` is an initialization error. |

1. A response whose status line or headers exceed the limit fails the request with a `ClientError`.
2. `maxEntityBodySize` applies to each response on its own, and does not apply to HTTP/2 streams.
3. When `maxEntityBodySize` is set, a response is not returned to the caller until its whole body has arrived. A response whose `Content-Length` header exceeds the limit, or whose body exceeds the limit as it arrives, fails the request with a `ClientError`, and the connection is closed. Responses that cannot have a body are not checked against their `Content-Length` header: responses to `HEAD` requests and `1XX`, `204` and `304` responses.
4. The idle timeout keeps applying while the body arrives, and each part of the body that is read counts as activity. A response that stays idle before its body is complete fails the request with an `IdleTimeoutError`.

### 11.10. Sending requests

1. The client has a remote method for each standard method (`get`, `post`, `put`, `patch`, `delete`, `head`, `options`), a resource method for each of them, `execute` for any method, and `forward`, which sends an inbound `Request` with its own method.
2. The payload of a request MAY be a `Request`, any `anydata` value, a `mime:Entity[]` for a multipart payload, or a `stream<byte[], io:Error?>`. It is serialized as follows:

   | Payload                              | Serialization   | Default content type       |
   |--------------------------------------|-----------------|----------------------------|
   | `()`                                 | No body         | None                       |
   | `string`                             | Text            | `text/plain`               |
   | `xml`                                | XML             | `application/xml`          |
   | `byte[]`, `stream<byte[], io:Error?>`| Bytes           | `application/octet-stream` |
   | `mime:Entity[]`                      | Multipart       | `multipart/form-data`      |
   | Any other `anydata`                  | JSON            | `application/json`         |

3. The `Content-Type` of the request is the `mediaType` argument, else the `Content-Type` in the `headers` argument, else the default content type of the payload.
4. When `mediaType` is `application/x-www-form-urlencoded` and the payload is an `anydata` value other than `string`, `xml` and `byte[]`, the payload MUST be convertible to `map<string>`, and is encoded as a form. Otherwise, the call returns a `ClientError`.
5. In the resource method form, the path segments are joined with `/`. The values of query parameters are converted to strings, and the values of an array are joined with `,`. The name of a query parameter is the `name` field of its `@http:Query` annotation, or else its name. `http:QueryParams` MAY be used to pass several query parameters as one value.
6. `head()` returns a `Response` without data binding.
7. `submit()` sends a request and returns an `HttpFuture`, whose response is obtained with `getResponse()`. On HTTP/2 connections, `hasPromise()`, `getNextPromise()`, `getPromisedResponse()` and `rejectPromise()` handle the push promises of the response.

### 11.11. Response data binding

The return type of a client call is determined by the `targetType` argument, which defaults to the contextually expected type. The response is converted to it as follows:

1. If the request fails, the `ClientError` is returned.
2. If `targetType` contains `Response`, the `Response` is returned, whatever its status code.
3. If the status code is in the range `400` to `599`, a `ClientRequestError` (`4XX`) or a `RemoteServerError` (`5XX`) is returned. Its message is the reason phrase, and its detail has the `statusCode`, the `headers`, and the `body` of the response. The body is read as JSON for `application/json`, as XML for `application/xml`, as bytes for `application/octet-stream`, and as text otherwise. An empty body is `()`.
4. If `targetType` is a stream of `SseEvent`, the `Content-Type` of the response MUST start with `text/event-stream`, and the events are returned as a stream. Otherwise, a `PayloadBindingError` is returned. A union of a stream of `SseEvent` and other types is not supported.
5. Otherwise, the payload is converted to `targetType` according to the `Content-Type` of the response, compared without parameters, as for the [payload parameter](#76-payload-parameter), with these differences:
   - A `map<string>` is decoded from a form only for `application/x-www-form-urlencoded`.
   - When the payload cannot be converted, a `PayloadBindingError` is returned.
   - When the response has no body, `()` is returned if `targetType` contains `()`, and a `NoContentError` is returned otherwise.
6. When `validation` is `true`, the constraints of `targetType` are validated. A violation results in a `PayloadValidationError`.
7. `1XX`, `2XX` and `3XX` responses are converted by rule 5. A `3XX` response is not an error.

### 11.12. Status code client

`StatusCodeClient` has the same configuration and methods as `Client`, but its `targetType` MUST be a status code response type or a union of them.

1. The response is bound to the member of `targetType` whose status code is the status code of the response, or else to a member with the default status, i.e. a subtype of `DefaultStatusCodeResponse`.
2. When no member matches, a `StatusCodeResponseBindingError` is returned: `StatusCodeBindingClientRequestError` for a `4XX` response, `StatusCodeBindingRemoteServerError` for a `5XX` response, and `StatusCodeResponseBindingError` otherwise. A `4XX` or `5XX` response that matches a member is not an error.
3. The `headers` field is bound from the response headers. Each field of a record type is bound to the header named by the `name` of its `@http:Header` annotation, or else by its name. A field that is not optional MUST have a header.
4. The `mediaType` field, when present in the type, is bound to the `Content-Type` of the response.
5. The `body` field is bound as described in [Response data binding](#1111-response-data-binding).
6. A failure to bind or validate the headers, the media type or the body returns the corresponding subtype of `StatusCodeResponseBindingError`, whose detail has the field `fromDefaultStatusCodeMapping`, which is `true` when the response was bound by the default status.

### 11.13. Client errors

The errors returned by clients are subtypes of `ClientError`:

| Error                                                                   | Condition                                                                                    |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `OutboundRequestError` and its subtypes                                 | The request could not be written.                                                            |
| `InboundResponseError` and its subtypes                                 | The response could not be read.                                                              |
| `IdleTimeoutError`                                                      | The idle timeout elapsed.                                                                    |
| `ClientConnectorError`                                                  | The connection to the endpoint failed.                                                       |
| `SslError`                                                              | The TLS handshake or configuration failed.                                                   |
| `ClientAuthError`                                                       | The authentication headers could not be created.                                             |
| `ApplicationResponseError` (`ClientRequestError`, `RemoteServerError`)  | The response has a `4XX` or `5XX` status and data binding was requested.                     |
| `NoContentError`                                                        | The response has no body and `targetType` is not nilable.                                    |
| `ResiliencyError` and its subtypes                                      | A resiliency feature failed. See [Resiliency](#12-resiliency).                               |
| `StatusCodeResponseBindingError` and its subtypes                       | A `StatusCodeClient` response could not be bound.                                            |
| `GenericClientError`                                                    | Any other failure, including invalid configuration.                                         |

Binding and validation errors are also of the types `PayloadBindingError`, `PayloadValidationError`, `HeaderBindingError` and `MediaTypeBindingError`, which MAY be used to test for them.

## 12. Resiliency

### 12.1. Retry

| Field             | Type      | Default | Meaning                                                                                                                                                                                                |
|-------------------|-----------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `count`           | `int`     | `0`     | Number of retries after the initial attempt. A request is sent at most `count + 1` times. `0` disables retrying.                                                                                      |
| `interval`        | `decimal` | `0`     | Wait time before the first retry.                                                                                                                                                                      |
| `backOffFactor`   | `float`   | `0.0`   | Multiplier applied to the previous wait time before each later retry. A value less than or equal to `0.0` is treated as `1.0`, which keeps the wait time constant. A value between `0.0` and `1.0` shrinks the wait time. |
| `maxWaitInterval` | `decimal` | `0`     | Upper bound of the wait times computed using `backOffFactor`. `0` is treated as `60`. The first retry always waits `interval`, even if it exceeds this bound.                                         |
| `statusCodes`     | `int[]`   | `[]`    | Response status codes on which the request is retried.                                                                                                                                                 |

1. The client sends the request.
2. If the attempt results in a network-level failure, or in a response whose status code is in `statusCodes`, and fewer than `count` retries have been made, the client waits as given by rule 4 and goes to step 1.
3. Otherwise, the client returns the outcome of the last attempt: the response, including a response whose status code is in `statusCodes`, or the `ClientError`. A response is then converted as described in [Response data binding](#1111-response-data-binding), so a `4XX` or `5XX` response becomes an `ApplicationResponseError` after the retries.
4. The wait time before the first retry is `interval`. The wait time before each later retry is the previous wait time multiplied by `backOffFactor`, capped at `maxWaitInterval`.
5. Responses whose status codes are not in `statusCodes`, including `4XX` and `5XX` responses, are not retried. Therefore, when `statusCodes` is empty, only network-level failures are retried.
6. Requests are retried whatever their method, including non-idempotent methods such as `POST` and `PATCH`.
7. The payload of the request is read into memory before the first attempt so that it can be resent. This includes streamed payloads.
8. The client `timeout` applies to each attempt separately.

#### Example

The following client sends a request at most five times, retrying on network-level failures and on `503 Service Unavailable` responses. The wait times between the attempts are 3, 6, 12 and 20 seconds, where the last one is capped by `maxWaitInterval`.

```ballerina
http:Client clientEP = check new ("http://localhost:9090",
    retryConfig = {count: 4, interval: 3, backOffFactor: 2.0, maxWaitInterval: 20, statusCodes: [503]}
);
```

### 12.2. Circuit breaker

| Field                                  | Type      | Default | Meaning                                                                                                                       |
|----------------------------------------|-----------|---------|-------------------------------------------------------------------------------------------------------------------------------|
| `rollingWindow.timeWindow`             | `decimal` | `60`    | Duration of the window over which requests are counted.                                                                      |
| `rollingWindow.bucketSize`             | `decimal` | `10`    | Duration of each bucket of the window. It MUST NOT be greater than `timeWindow`, otherwise the initialization returns a `ClientError`. |
| `rollingWindow.requestVolumeThreshold` | `int`     | `10`    | Minimum number of requests in the window before the circuit can change its state.                                            |
| `failureThreshold`                     | `float`   | `0.0`   | Failure ratio above which the circuit opens. It MUST be in the range [0, 1], otherwise the initialization panics with a `CircuitBreakerConfigError`. |
| `resetTime`                            | `decimal` | `0`     | Duration for which the circuit stays open before it lets a request through.                                                  |
| `statusCodes`                          | `int[]`   | `[]`    | Response status codes counted as failures.                                                                                    |

1. A request _fails_ when it results in a `ClientError`, including the outcome of exhausted retries, or in a response whose status code is in `statusCodes`. Otherwise, it succeeds.
2. The window is divided into `timeWindow / bucketSize` buckets, each counting the requests, failures and rejected requests in its period. Buckets older than `timeWindow` are discarded. When no request is made for longer than `timeWindow`, all the buckets are discarded.
3. The circuit has three states, and is evaluated when a request is made:
   - **Closed**: The request is sent. When the window has at least `requestVolumeThreshold` requests and the ratio of failures to the requests that were not rejected is greater than `failureThreshold`, the circuit becomes open before the request is sent.
   - **Open**: The request is not sent, and the call returns an `UpstreamServiceUnavailableError`. When more than `resetTime` has passed since the last failure, or since the circuit was forced open, the circuit becomes half-open and the request is sent.
   - **Half-open**: The request is sent. When the window has at least `requestVolumeThreshold` requests, the circuit becomes closed if the last completed request succeeded, and open otherwise. The number of requests sent while the circuit is half-open is not limited.
4. `circuitBreakerForceOpen()` opens the circuit, `circuitBreakerForceClose()` closes it and discards the buckets, and `getCircuitBreakerCurrentState()` returns the state of the circuit as of the last request. These methods panic with a `ClientError` when the client has no circuit breaker.

### 12.3. Load balance client

`LoadBalanceClient` distributes requests over the endpoints of `targets`. Its configuration has the fields of `ClientConfiguration` except `secureSocket`, which is configured per target, and the following fields:

| Field      | Type                | Default | Meaning                                                                     |
|------------|---------------------|---------|-----------------------------------------------------------------------------|
| `targets`  | `TargetService[]`   | `[]`    | The endpoints, each with a `url` and an optional `secureSocket`.            |
| `lbRule`   | `LoadBalancerRule?` | `()`    | Rule that selects the endpoint of a request. `()` means round robin.        |
| `failover` | `boolean`           | `true`  | Whether a request that fails is sent to the next endpoint.                  |

1. With round robin, the endpoints are selected in order, starting from the first, and the position is shared by all the calls and attempts of the client.
2. When an attempt results in a `ClientError` and `failover` is `true`, the request is sent to the next endpoint selected by the rule. A response is returned whatever its status code. The payload of the request is read into memory so that it can be resent.
3. When all the endpoints fail, the call returns an `AllLoadBalanceEndpointsFailedError` whose message includes the last error. When `failover` is `false`, the first error is returned.
4. `submit()`, `getResponse()`, `getNextPromise()` and `getPromisedResponse()` return an `UnsupportedActionError`, `hasPromise()` returns `false`, and `execute()` with a custom method returns an `UnsupportedActionError`.
5. The behaviour of a load balance client with no targets is unspecified.

### 12.4. Failover client

`FailoverClient` sends a request to the endpoints of `targets` one at a time until one succeeds. Its configuration has the fields of `ClientConfiguration` except `secureSocket`, and the following fields:

| Field           | Type              | Default                | Meaning                                                           |
|-----------------|-------------------|------------------------|-------------------------------------------------------------------|
| `targets`       | `TargetService[]` | `[]`                   | The endpoints, each with a `url` and an optional `secureSocket`.  |
| `failoverCodes` | `int[]`           | `[501, 502, 503, 504]` | Response status codes on which the next endpoint is tried.        |
| `interval`      | `decimal`         | `0`                    | Wait time between attempts.                                       |

1. A call starts with the endpoint that last succeeded, initially the first one, and tries the endpoints in order, wrapping around, until each has been tried once.
2. An attempt fails when it results in a `ClientError` or in a response whose status code is in `failoverCodes`.
3. When all the endpoints fail, the call returns a `FailoverAllEndpointsFailedError` whose message includes the last error or the last response, and whose detail field `failoverErrors` has the error of each attempt. An attempt that failed with a status code is represented by a `FailoverActionFailedError`.
4. `getSucceededEndpointIndex()` returns the index of the endpoint that last succeeded.
5. `hasPromise()` returns `false`, and `getNextPromise()` and `getPromisedResponse()` return an `UnsupportedActionError`.
6. The behaviour of a failover client with no targets is unspecified.

## 13. Message body streaming and back-pressure

1. Message bodies are transferred on demand rather than buffered in full, unless a rule of this specification requires the body to be read in full. An inbound body is read from the connection as the application consumes it, and an outbound body is written as the remote endpoint accepts it. While an application consumes or produces a body slowly, no data moves on the connection.
2. Inactivity caused by the pace of the application does not count towards the idle timeout of a listener or a client. A remote endpoint that stops responding is still timed out.
   - For HTTP/2, this applies to both directions of a stream.
   - For HTTP/1.x, this applies to reading a body only. A remote endpoint that reads a body slowly is not distinguished from one that has stopped responding.
3. A transfer that makes no progress is treated as stalled once the idle timeout has elapsed once for it, and is excused for up to `maxBackPressureStallTime` more before the idle timeout applies. Any progress restarts this period. A transfer that never makes progress again is therefore closed after the idle timeout plus `maxBackPressureStallTime`.
4. `maxBackPressureStallTime` is a configurable of type `decimal` whose default is `300`. A negative value lets a stalled transfer wait indefinitely. `0` removes the allowance, so that any inactivity counts towards the idle timeout.

## 14. Observability

### 14.1. Trace logs

Trace logs record the HTTP messages sent and received by listeners and clients. They are disabled by default.

| Configurable                    | Type      | Default | Meaning                                         |
|---------------------------------|-----------|---------|-------------------------------------------------|
| `traceLogConsole`               | `boolean` | `false` | Whether trace logs are written to the console.  |
| `traceLogAdvancedConfig`        | record    | `{}`    | Further destinations. See below.                |

`traceLogAdvancedConfig` has the following fields:

| Field     | Type          | Default | Meaning                                                                                                    |
|-----------|---------------|---------|------------------------------------------------------------------------------------------------------------|
| `console` | `boolean`     | `false` | Whether trace logs are written to the console.                                                             |
| `file`    | `LogFileConfig`  | absent  | File destination, with a `path` and an optional `rotation`. See [Log rotation](#143-log-rotation).         |
| `path`    | `string`      | absent  | Deprecated. File path of the trace logs. Ignored, with a warning, when `file` is set.                     |
| `host`    | `string`      | absent  | Host of a socket destination. When `host` and `port` are set, trace logs are sent to it in JSON format.    |
| `port`    | `int`         | absent  | Port of a socket destination. It MUST NOT be `0`.                                                          |

1. Console output is written to the standard error stream.
2. Each record has the form `[yyyy-MM-dd HH:mm:ss,SSS] LEVEL {logger} - message`.
3. An invalid configuration, or a socket destination that cannot be connected to, makes the initialization of the module fail.

### 14.2. Access logs

Access logs record one entry for each request handled by a listener. They are disabled by default, and are configured with the `accessLogConfig` configurable:

| Field        | Type          | Default            | Meaning                                                                                                               |
|--------------|---------------|--------------------|-----------------------------------------------------------------------------------------------------------------------|
| `console`    | `boolean`     | `false`            | Whether access logs are written to the console.                                                                       |
| `format`     | `string`      | `"flat"`           | `"flat"` or `"json"`. Any other value is treated as `"flat"`, with a warning.                                         |
| `attributes` | `string[]`    | absent             | Attributes of each entry. When absent, the default attributes are used. `[]` disables access logs.                   |
| `file`       | `LogFileConfig`  | absent             | File destination, with a `path` and an optional `rotation`. See [Log rotation](#143-log-rotation).                    |
| `path`       | `string`      | absent             | Deprecated. File path of the access logs. Ignored, with a warning, when `file` is set.                               |

The following attributes are supported. The default attributes are `ip`, `date_time`, `request`, `status`, `response_body_size`, `http_referrer` and `http_user_agent`.

| Attribute              | Value                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------|
| `ip`                   | The first address of the `X-Forwarded-For` header, else the address of the client            |
| `date_time`            | Time the request was received, as `[dd/MMM/yyyy:HH:mm:ss.SSS Z]` in the flat format          |
| `request`              | Request line                                                                                 |
| `request_method`       | Method of the request                                                                        |
| `request_uri`          | Request target, including the query                                                          |
| `scheme`               | Protocol version of the request, e.g. `HTTP/1.1`                                             |
| `status`               | Status code of the response                                                                  |
| `request_body_size`    | Size of the request body, from `Content-Length` when present                                 |
| `response_body_size`   | Size of the response body                                                                    |
| `request_time`         | Time taken to process the request, in milliseconds                                           |
| `http_referrer`        | `Referer` header                                                                             |
| `http_user_agent`      | `User-Agent` header                                                                          |
| `http_x_forwarded_for` | `X-Forwarded-For` header                                                                     |
| `http_<name>`          | The header `<name>`, e.g. `http_x-request-id`                                                |

1. The attributes of an entry are written in the order of the table, followed by the `http_<name>` attributes, regardless of the order of the configuration. Unknown attributes are ignored.
2. In the flat format, the values are separated by spaces. The values of `request`, `http_referrer`, `http_user_agent`, `http_x_forwarded_for` and `http_<name>` are quoted, and a missing value is written as `-`. In the JSON format, each entry is a JSON object.
3. The requests sent by clients while handling the request are appended to its entry: after `~` in the flat format, and as an `upstream` array in the JSON format.
4. Console output is written to the standard error stream.

### 14.3. Log rotation

The `rotation` field of a file destination is a `log:RotationConfig` of the `ballerina/log` module:

| Field            | Type             | Default    | Meaning                                                                       |
|------------------|------------------|------------|-------------------------------------------------------------------------------|
| `policy`         | `RotationPolicy` | `BOTH`     | `SIZE_BASED`, `TIME_BASED`, or `BOTH`, which rotates on whichever comes first. |
| `maxFileSize`    | `int`            | `10485760` | File size at which a `SIZE_BASED` or `BOTH` policy rotates the file.           |
| `maxAge`         | `int`            | `86400`    | File age at which a `TIME_BASED` or `BOTH` policy rotates the file.            |
| `maxBackupFiles` | `int`            | `10`       | Number of rotated files kept. `0` keeps none.                                  |

1. When `rotation` is absent, the file is not rotated.
2. The rotation condition is checked before each record is written. The size is that of the file, including content present before the program started. The age is measured from when the file was opened, at startup or at the last rotation. A file can therefore exceed `maxFileSize` by one record.
3. A rotated file is renamed to `{basename}-{yyyyMMdd-HHmmssSSS}.{extension}`, using the local time zone, and a new file is created. When there are more than `maxBackupFiles` rotated files, the oldest are deleted.
4. The parent directories of the file are created when they do not exist. The file is locked with a `{path}.lck` file, and startup fails when another process holds the lock.
5. A `maxFileSize` less than or equal to `0` with a `SIZE_BASED` or `BOTH` policy, a `maxAge` less than or equal to `0` with a `TIME_BASED` or `BOTH` policy, a negative `maxBackupFiles`, and an empty or directory `path` make the initialization of the module fail.

## 15. Authentication and authorization

### 15.1. Declarative listener authentication

The `auth` field of the `ServiceConfig` and `ResourceConfig` annotations secures resources. Each `ListenerAuthConfig` is one of the following, each with an optional `scopes` field of type `string|string[]`:

| Config                     | Scheme   | Credentials validated by                                       |
|----------------------------|----------|----------------------------------------------------------------|
| `FileUserStoreConfigWithScopes` | `Basic`  | The users configured under `[[ballerina.auth.users]]`     |
| `LdapUserStoreConfigWithScopes` | `Basic`  | An LDAP user store                                        |
| `JwtValidatorConfigWithScopes`  | `Bearer` | JWT validation                                            |
| `OAuth2IntrospectionConfigWithScopes` | `Bearer` | An OAuth2 introspection endpoint                    |

1. The configurations of a resource are chosen as follows:
   - If the resource has `auth` of type `ListenerAuthConfig[]`, those configurations are used, and the configurations of the service are ignored.
   - If the resource has `auth` of type `Scopes`, the configurations of the service are used with their scopes replaced by those scopes.
   - Otherwise, the configurations of the service are used.
2. Authentication runs after the request interceptors and before the resource. A request without an `Authorization` header results in a `ListenerAuthnError` (`401 Unauthorized`).
3. The scheme is the first word of the `Authorization` header. The configurations for that scheme are tried in order. The first configuration that authenticates and authorizes the request is used, and the resource is invoked.
4. When no configuration authenticates the request, the result is a `ListenerAuthnError` (`401 Unauthorized`). When a configuration authenticates the request but does not authorize it, the result is a `ListenerAuthzError` (`403 Forbidden`), and later configurations are not tried.
5. A request is authorized when the configuration has no scopes, or when at least one scope of the user is equal to one of the configured scopes. The scopes of a JWT are taken from the claim named by `scopeKey` (default `"scope"`), which MAY be a space-separated string or an array. The scopes of an OAuth2 token are taken from the introspection response, and MUST be a space-separated string. A user of a user store without scopes is not authorized.
6. An inactive OAuth2 token results in a `ListenerAuthnError` (`401 Unauthorized`).
7. The errors of rules 2 to 6 are handled as described in [Error handling](#10-error-handling), and are visible to error interceptors as `ListenerAuthnError` and `ListenerAuthzError`. The responses do not have a `WWW-Authenticate` header.

> **Note:** The behaviour of a resource with `auth` of type `Scopes` in a service without `auth`, and of `auth: []`, is unspecified.

### 15.2. Imperative listener authentication

The following handlers authenticate and authorize requests from the code of a resource. Their `authenticate` and `authorize` methods accept a `Request`, a `Headers` value, or the value of the `Authorization` header.

| Handler                                  | Kind         | `authenticate` returns                 | `authorize` returns                                         |
|------------------------------------------|--------------|----------------------------------------|-------------------------------------------------------------|
| `ListenerFileUserStoreBasicAuthHandler`  | class        | `auth:UserDetails\|Unauthorized`       | `Forbidden?`                                                |
| `ListenerLdapUserStoreBasicAuthHandler`  | client class | `auth:UserDetails\|Unauthorized`       | `Forbidden?`                                                |
| `ListenerJwtAuthHandler`                 | class        | `jwt:Payload\|Unauthorized`            | `Forbidden?`                                                |
| `ListenerOAuth2Handler`                  | client class | none                                   | `oauth2:IntrospectionResponse\|Unauthorized\|Forbidden`     |

1. A missing `Authorization` header results in an `Unauthorized` value whose body is `"Authorization header not available."`.
2. The Basic auth handlers return `Unauthorized` for a scheme other than `Basic`.
3. Scopes are matched as in rule 5 of [Declarative listener authentication](#151-declarative-listener-authentication).

### 15.3. Client authentication

The `auth` field of a client configuration is one of the following. The corresponding handler MAY also be used directly, through its `enrich()` method.

| Config                                           | Handler                              | Header                                                       |
|--------------------------------------------------|--------------------------------------|--------------------------------------------------------------|
| `CredentialsConfig`                              | `ClientBasicAuthHandler`             | `Authorization: Basic <base64 of username:password>`         |
| `BearerTokenConfig`                              | `ClientBearerTokenAuthHandler`       | `Authorization: Bearer <token>`                              |
| `JwtIssuerConfig`                                | `ClientSelfSignedJwtAuthHandler`     | `Authorization: Bearer <self-signed JWT>`                    |
| `OAuth2GrantConfig` (client credentials, password, refresh token or JWT bearer grant) | `ClientOAuth2Handler` | `Authorization: Bearer <access token>`         |

1. The header is set on each request, replacing an `Authorization` header set by the caller.
2. When the header cannot be created, e.g. because an access token cannot be obtained, the call returns a `ClientAuthError` and the request is not sent.
3. The caching and refreshing of tokens is provided by the `ballerina/jwt` and `ballerina/oauth2` modules. A `401 Unauthorized` response does not cause a token to be refreshed.

## 16. TLS

### 16.1. Common configuration

The following fields are shared by the listener and client TLS configurations:

| Field              | Type                                   | Meaning                                                                                                             |
|--------------------|----------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| `key`              | `crypto:KeyStore\|CertKey`             | Key store, or certificate and private key files, of the endpoint.                                                   |
| `protocol`         | `record {Protocol name; string[] versions = [];}` | Protocol (`SSL`, `TLS` or `DTLS`) and versions. Empty `versions` means the defaults of the Java runtime. |
| `certValidation`   | `record {CertValidationType type = OCSP_STAPLING; int cacheSize; int cacheValidityPeriod;}` | Certificate revocation checking. A `cacheSize` of `0` means `50`, and a `cacheValidityPeriod` of `0` means `15`. |
| `ciphers`          | `string[]`                             | Cipher suites.                                                                                                      |
| `shareSession`     | `boolean`                              | Whether TLS sessions are reused. Default `true`.                                                                    |
| `handshakeTimeout` | `decimal`                              | TLS handshake timeout. When absent or `0`, the default of the Java runtime is used.                                 |
| `sessionTimeout`   | `decimal`                              | TLS session timeout. When absent or `0`, the default of the Java runtime is used.                                   |

A key store or trust store with a blank path or password is an initialization error.

### 16.2. Listener

`ListenerSecureSocket` has the fields of [Common configuration](#161-common-configuration), and:

1. `key` is required.
2. `mutualSsl` is an optional `record {VerifyClient verifyClient = REQUIRE; crypto:TrustStore|string cert;}`. With `REQUIRE`, a client MUST present a certificate trusted by `cert`. With `OPTIONAL`, a client MAY present one.
3. When `ciphers` is not set, a fixed list of 12 cipher suites is used.

### 16.3. Client

`ClientSecureSocket` has the fields of [Common configuration](#161-common-configuration), and:

| Field            | Type                         | Default | Meaning                                                                                                  |
|------------------|------------------------------|---------|----------------------------------------------------------------------------------------------------------|
| `enable`         | `boolean`                    | `true`  | When `false`, the certificate of the server is not validated. `key` is still used.                       |
| `cert`           | `crypto:TrustStore\|string`  | absent  | Trust store or certificate file used to validate the server. When absent, the trust store of the Java runtime is used. |
| `verifyHostName` | `boolean`                    | `true`  | Whether the host name of the server is verified against its certificate.                                 |
| `serverName`     | `string`                     | absent  | Server name sent with SNI. When absent, the host of the URL is used.                                     |

1. `key` is optional, and is used for mutual TLS.
2. When `ciphers` is not set, the defaults of the Java runtime are used.
3. A client with an `https://` URL and no `secureSocket` uses the defaults of the Java runtime.

## 17. Security considerations

1. The listener accepts cleartext connections unless `secureSocket` is configured. Credentials, including those of Basic authentication, are then sent in clear text.
2. `ClientSecureSocket` with `enable: false` disables the validation of server certificates, and exposes the client to man-in-the-middle attacks.
3. The `default` accessor handles every method, including methods that are expected to be safe, such as `GET`. See static code rule `ballerina/http:1`.
4. A CORS configuration with `allowOrigins: ["*"]` allows any origin to read the responses of the resource. A request from an origin that is not allowed is still processed, so CORS MUST NOT be relied upon for access control.
5. Payload binding reads the whole request body into memory. Without `maxEntityBodySize`, the size of the body is not limited.
6. Redirects, retries and load balancing read request payloads into memory, and retries resend non-idempotent requests.
7. The `JWT_INFORMATION` member of the request context is decoded without validation, and MUST NOT be used for authorization unless the token has been validated, e.g. by declarative authentication.
8. When a resource or an interceptor panics, the program terminates. A panic triggered by a request therefore stops the service.
9. The Swagger UI resource loads its scripts from `unpkg.com`.

## 18. Static code rules

The compiler plugin provides the following rules to the Ballerina static code analysis tool. Their rationale and remediation are documented in [Static code rules](../static-code-rules.md).

| Id                 | Kind          | Triggered by                                                                                                                                                               |
|--------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ballerina/http:1` | VULNERABILITY | A resource with the `default` accessor.                                                                                                                                    |
| `ballerina/http:2` | VULNERABILITY | A `cors` field whose `allowOrigins` list literal contains `"*"`, in any annotation. Values given through variables or constants are not detected.                          |
| `ballerina/http:3` | VULNERABILITY | A client resource access action with a path segment that is a reference to a parameter of the enclosing resource.                                                         |
| `ballerina/http:4` | VULNERABILITY | A resource whose return type includes a redirect status code response, and which returns a mapping literal whose `Location` header uses a parameter of the resource.      |

## Changes

- 2.18.2: Rewrote the specification as a normative contract, following the [library specification guide](https://github.com/ballerina-platform/ballerina-library/blob/main/docs/library-specification-guide.md). The following statements of the previous version were corrected to match the intended behaviour:
  - A path parameter that cannot be converted results in `400 Bad Request`, not `500 Internal Server Error`.
  - The `mediaType` of the `@http:Payload` annotation is not checked against the request (`415`) or the `Accept` header (`406`). Only `consumes` and `produces` are.
  - The default client `timeout` is `30`, not `60`, and client caching is enabled by default.
  - `ServiceConfig` has no `interceptors` field. Interceptors are engaged through `InterceptableService`.
  - A request error interceptor has a resource method, not a remote method, and the default error response is a JSON object.
  - Relaxed data binding applies to request payloads in services and response payloads in clients.
- 2.18.2: Specified the retry behaviour of the HTTP client ([#2766](https://github.com/ballerina-platform/module-ballerina-http/pull/2766)).

## References

- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [RFC 9112: HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112)
- [RFC 9113: HTTP/2](https://www.rfc-editor.org/rfc/rfc9113)
- [RFC 6265: HTTP State Management Mechanism](https://www.rfc-editor.org/rfc/rfc6265)
- [Fetch Standard: CORS protocol](https://fetch.spec.whatwg.org/#http-cors-protocol)
- [Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [Ballerina language specification](https://ballerina.io/spec/lang/master/)
