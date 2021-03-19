## Package Overview

This package provides an implementation for connecting and interacting with HTTP and HTTP2 endpoints. The package facilitates two types of network entry points as ‘Client’ and ‘Listener’.

### Client

The `Client` is used to connect to and interact with HTTP endpoints. They support connection pooling and can be configured to have a maximum number of active connections that can be made with the remote endpoint. The `Client` activates connection eviction after a given idle period and also supports follow-redirects so that the users do not have to manually handle 3xx HTTP status codes.

The `Client` handles resilience in multiple ways such as load balancing, circuit breaking, endpoint timeouts, and a retry mechanism.

Load balancing is used in the round robin or failover manner.

When a failure occurs in the remote service, the client connections might wait for some time before a timeout occurs. Awaiting requests consume resources in the system. Circuit Breakers are used to trip after a certain number of failed requests to the remote service. Once a circuit breaker trips, it does not allow the client to send requests to the remote service for a period of time.

The Ballerina circuit breaker supports tripping on HTTP error status codes and I/O errors. Failure thresholds can be configured based on a sliding window (e.g., 5 failures within 10 seconds). `Client` endpoints also support a retry mechanism that allows a client to resend failed requests periodically for a given number of times.

The `Client` supports Server Name Indication (SNI), Certificate Revocation List (CRL), Online Certificate Status Protocol (OCSP), and OCSP Stapling for SSL/TLS connections. They also support HTTP2, keep-alive, chunking, HTTP caching, data compression/decompression, and authentication/authorization.

A `Client` can be defined using the URL of the remote service that the client needs to connect with, as shown below:

``` ballerina
http:Client|http:ClientError clientEndpoint = new("https://my-simple-backend.com");
```
The defined `Client` endpoint can be used to call a remote service as follows:

``` ballerina
// Send a GET request to the specified endpoint.
http:Response|http:ClientError response = clientEndpoint->get("/get?id=123");
```

For more information, see the following.
* [Client Endpoint Example](https://ballerina.io/learn/by-example/http-client-endpoint.html)
* [Circuit Breaker Example](https://ballerina.io/learn/by-example/http-circuit-breaker.html)
* [HTTP Redirects Example](https://ballerina.io/learn/by-example/http-redirects.html)
* [HTTP Cookies](https://ballerina.io/learn/by-example/http-cookies.html)

### Listener

A `Service` represents a collection of network-accessible entry points and can be exposed via a `Listener` endpoint. A resource represents one such entry point and can have its own path, HTTP methods, body format, 'consumes' and 'produces' content types, CORS headers, etc. In resources, `http:caller` and `http:Request` are mandatory parameters while `path` and `body` are optional.

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

See the following.
* [HTTPS Listener Example](https://ballerina.io/learn/by-example/https-listener.html)
* [HTTP CORS Example](https://ballerina.io/learn/by-example/http-cors.html)
* [HTTP Failover Example](https://ballerina.io/learn/by-example/http-failover.html)
* [HTTP Load Balancer Example](https://ballerina.io/learn/by-example/http-load-balancer.html)

`Listener` endpoints can be exposed via SSL. They support Mutual SSL, Hostname Verification, and Application Layer Protocol Negotiation (ALPN) for HTTP2. `Listener` endpoints also support Certificate Revocation List (CRL), Online Certificate Status Protocol (OCSP), OCSP Stapling, HTTP2, keep-alive, chunking, HTTP caching, data compression/decompression, and authentication/authorization.

For more information, see [Mutual SSL Example](https://ballerina.io/learn/by-example/mutual-ssl.html).

For more information, see [Caching Example](https://ballerina.io/learn/by-example/cache.html), [HTTP Disable Chunking Example](https://ballerina.io/learn/by-example/http-disable-chunking.html).
