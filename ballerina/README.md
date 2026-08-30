## Overview

This module provides APIs for connecting and interacting with HTTP and HTTP2 endpoints. It facilitates two types of network entry points as the `Client` and `Listener`.

### Client

The `Client` is used to connect to and interact with HTTP endpoints. They support connection pooling and can be 
configured to have a maximum number of active connections that can be made with the remote endpoint. The `Client` 
activates connection eviction after a given idle period and also supports follow-redirects so that you do not 
have to manually handle 3xx HTTP status codes.

#### Resiliency

The `Client` handles resilience in multiple ways such as load balancing, circuit breaking, endpoint timeouts, and via a 
retry mechanism.

Load balancing is used in the round-robin or failover manner.

When a failure occurs in the remote service, the client connections might wait for some time before a timeout occurs. 
Awaiting requests consume resources in the system. Circuit Breakers are used to trip after a certain number of failed 
requests to the remote service. Once a circuit breaker trips, it does not allow the client to send requests to the 
remote service for a period of time.

The Ballerina circuit breaker supports tripping on HTTP error status codes and I/O errors. Failure thresholds can be 
configured based on a sliding window (e.g., 5 failures within 10 seconds). The `Client` also supports a retry 
mechanism that allows it to resend failed requests periodically for a given number of times.

#### Security

The `Client` supports Server Name Indication (SNI), Certificate Revocation List (CRL), Online Certificate Status 
Protocol (OCSP), and OCSP Stapling for SSL/TLS connections.
Also, the `Client` can be configured to send authentication information to the endpoint being invoked. Ballerina has 
built-in support for Basic authentication, JWT authentication, and OAuth2 authentication.

In addition to that, it supports both HTTP/1.1 and HTTP2 protocols and connection keep-alive, content 
chunking, HTTP caching, data compression/decompression, response payload binding, and authorization can be highlighted as the features of the `Clients`.

A `Client` can be defined using the URL of the remote service that it needs to connect with as shown below:

```ballerina
http:Client clientEndpoint = check new("https://my-simple-backend.com");
```
The defined `Client` endpoint can be used to call a remote service as follows:

```ballerina
// Send a GET request to the specified endpoint.
http:Response response = check clientEndpoint->get("/get?id=123");
```
The payload can be retrieved as the return value from the remote function as follows:

```ballerina
// Retrieve payload as json.
json payload = check clientEndpoint->post("/backend/Json", "foo");
```

### Listener

The `Listener` is the underneath server connector that binds the given IP/Port to the network and it's behavior can 
be changed using the `http:ListenerConfiguration`. In HTTP, the `http:Service`-typed services can be attached to 
the `Listener`. The service type precisely describes the syntax for both the service and resource.

A `Service` represents a collection of network-accessible entry points and can be exposed via a `Listener` endpoint. 
A resource represents one such entry point and can have its own path, HTTP methods, body format, `consumes` and 
`produces` content types, CORS headers, etc. In resources, the HTTP method and resource path are mandatory parameters and
the String literal and path parameters can be stated as the path. The resource function accepts the `http:Caller`, `http:Request`, 
`http:Headers`, query parameters, header parameters, and payload parameters as arguments. However, they are optional.

When a `Service` receives a request, it is dispatched to the best-matched resource.

A `Listener` endpoint can be defined as follows:

```ballerina
// Attributes associated with the `Listener` endpoint are defined here.
listener http:Listener helloWorldEP = new(9090);
```

Then a `Service` can be defined and attached to the above `Listener` endpoint as shown below:

```ballerina
// By default, Ballerina assumes that the service is to be exposed via HTTP/1.1.
service /helloWorld on helloWorldEP {

   resource function post [string name](@http:Payload string message) returns string {
       // Sends the response back to the client along with a string payload.
       return "Hello, World! I’m " + name + ". " + message;
   }
}
```

#### Security

`Listener` endpoints can be exposed via SSL. They support Mutual SSL, Hostname Verification, and Application Layer 
Protocol Negotiation (ALPN) for HTTP2. `Listener` endpoints also support Certificate Revocation List (CRL), Online 
Certificate Status Protocol (OCSP), and OCSP Stapling.
Also, The `listener` can be configured to authenticate and authorize the inbound requests. Ballerina has 
built-in support for basic authentication, JWT authentication, and OAuth2 authentication.

In addition to that, supports both the HTTP/1.1 and HTTP2 protocols and connection keep-alive, content 
chunking, HTTP caching, data compression/decompression, payload binding, HTTP/2 stream concurrency limiting, and
authorization can be highlighted as the features of a `Service`.

## Writing HTTP services

When authoring an HTTP service, keep the following conventions in mind:

- An HTTP service always needs an `http:Listener` attached to it. Declare the listener at the module level as a variable and reference it in the service declaration (for example, `listener http:Listener ep = check new (8080);`).
- Resource functions define the network entry points of the service. `remote` functions are not allowed in an HTTP service, but other methods — such as `init` and private helper functions for reusable logic — are permitted.
- Path parameters are declared in the resource function path (for example, `resource function get v1/user/[int userId]/profile()`).
- Resource function parameters carry the query parameters, headers, and body:
    - **Body** - annotate with `@http:Payload`. The annotation is optional when there is a single parameter and its type is a record.
    - **Query parameters** - annotate with `@http:Query`.
    - **Headers** - annotate with `@http:Header`.
- Prefer a concrete type (any `anydata` such as a `string`, `json`, or record) as the resource return type.

```ballerina
import ballerina/http;

listener http:Listener ep = check new (8080);

type Person record {
    string name;
    int age;
};

service /v1 on ep {

    // Prefer types as the return type; can be any anydata such as string, json, or record.
    resource function get foo() returns Person|error {
        return {name: "John", age: 30};
    }

    // Query parameters
    resource function get bar(@http:Query string id) returns Person|error {
        return {name: "John", age: 30};
    }

    // Path parameters
    resource function get customers/[int id]/accounts() returns Person|error {
        return {name: "John", age: 30};
    }

    // Body with data binding and header parameters
    resource function post customers/[int id]/accounts(@http:Payload Person account, @http:Header string customHeader) returns Person|error {
        return account;
    }
}
```

## Writing HTTP clients

- Always declare clients at the module level as `final` variables.
- Use direct data binding to bind the response to a type whenever possible.
- Use the `http:Response` type as the return type only when you need to access the headers or status code of the response.

```ballerina
import ballerina/http;

// Always declare clients at the module level as final variables.
final http:Client cl = check new ("http://localhost:9090");

type Person record {
    string name;
    int age;
};

public function main() returns error? {
    // If only the body of the response is needed, use direct data binding.
    Person p = check cl->get("/foo/bar");

    // If the full response is needed, use http:Response.
    http:Response res = check cl->get("/foo/bar");
    json payload = check res.getJsonPayload();
    Person p1 = check payload.cloneWithType();

    // Get a specific header.
    string contentTypeHeader = check res.getHeader("Content-Type");

    // Get the status code.
    int statusCode = res.statusCode;

    // Send a request with query params and headers (both optional).
    Person p3 = check cl->get("/foo/bar?queryParam1=value&queryParam2=val2", headers = {
        "x-Custom-Header": "custom-value"
    });
}
```

## Writing tests for HTTP services

When writing tests for an HTTP service, the following conventions keep the suite consistent and readable. Refer to the `ballerina/test` module for the core test framework.

**Test file structure**

- Start with the necessary imports, including `ballerina/http`, `ballerina/test`, and anything else required.
- Define an HTTP client at the module level named `clientEp`, declared `final` as in the client guidance above.
- Organize tests logically: create, read, update, delete.
- Add helper functions only when they improve readability, and reuse existing types from the codebase rather than redefining them.

**Test functions**

- Write at least one test case for every resource function.
- Each test function should return `error?` and use the `check` keyword for error propagation.
- Use the client resource-access syntax that mirrors the resource being tested:
    - GET - `Book book = check clientEp->/books/[isbn]();` for `resource function get books/[string isbn]()`.
    - POST - `Book book = check clientEp->/books.post(newBook);` for `resource function post books(@http:Payload Book newBook)`.
    - PUT - `Book book = check clientEp->/books/[isbn].put(updatedBook, name = "BookName");`.
    - DELETE - `string result = check clientEp->/books.delete(isbn = value);` for `resource function delete books(@http:Query string isbn) returns string|error`.
    - PATCH - `Book book = check clientEp->/books/[isbn].patch(updatedBook, name = "BookName");`.
- For non-annotated resource parameters, records are treated as body parameters and other types as query parameters.
- For negative test cases, cover the scenarios explicitly handled in the service rather than theoretical edge cases.

**Response handling**

- Use direct data binding for positive test cases.
- For negative test cases, use `http:Response` variables and assert the status codes.
- Always assign responses to variables with specific types.

