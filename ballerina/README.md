## Overview

This module provides APIs for connecting and interacting with HTTP and HTTP2 endpoints. It
facilitates two types of network entry points as the `Client` and `Listener`.

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
chunking, HTTP caching, data compression/decompression, payload binding, and authorization can be highlighted as the features of a `Service`.
