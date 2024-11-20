Ballerina HTTP Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-http/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-http)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-http/actions/workflows/build-with-bal-test-graalvm.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-http.svg)](https://github.com/ballerina-platform/module-ballerina-http/commits/master)
  [![Github issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/http.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Fhttp)

This library provides APIs for connecting and interacting with HTTP and HTTP2 endpoints. It
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
http:Response response = check clientEndpoint->/backend(id = 123);
```
The payload can be retrieved as the return value from the remote function as follows:

```ballerina
// Retrieve payload as json.
json payload = check clientEndpoint->/backend/Json.post("foo");
```

### Listener

The `Listener` is the underneath server connector that binds the given IP/Port to the network and it's behavior can
be changed using the `http:ListenerConfiguration`. In HTTP, the `http:Service`-typed services can be attached to
the `Listener`. The service type precisely describes the syntax for both the service and resource.

A `Service` represents a collection of network-accessible entry points and can be exposed via a `Listener` endpoint.
A resource represents one such entry point and can have its own path, HTTP methods, body format, `consumes` and
`produces` content types, CORS headers, etc. In resources, the HTTP method and resource path are mandatory parameters and
the String literal and path parameters can be stated as the path. The resource method accepts the `http:Caller`, `http:Request`,
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

## Issues and projects 

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Standard Library. To report bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina Standard Library [parent repository](https://github.com/ballerina-platform/ballerina-standard-library). 

This repository only contains the source code for the package.

## Build from the source

### Set Up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/downloads/)
   
   * [OpenJDK](https://adoptium.net/)
   
        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Export GitHub Personal access token with read package permissions as follows,

        export packageUser=<Username>
        export packagePAT=<Personal access token>

3. Download and install [Docker](https://www.docker.com/) and Docker Compose.

### Build the source

Execute the commands below to build from source.

1. To build the library:
    ```
    ./gradlew clean build
    ```
   
2. To run the integration tests:
    ```
    ./gradlew clean test
    ```

3. To run a group of tests
    ```
    ./gradlew clean test -Pgroups=<test_group_names>
    ```

4. To build the package without the tests:
    ```
    ./gradlew clean build -x test
    ```
   
5. To debug the tests:
    ```
    ./gradlew clean test -Pdebug=<port>
    ```
   
6. To debug with Ballerina language:
    ```
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina central repository:
    ```
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina central repository:
    ```
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`HTTP` library](https://lib.ballerina.io/ballerina/http/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
* View the [Ballerina performance test results](https://github.com/ballerina-platform/ballerina-lang/blob/master/performance/benchmarks/summary.md).
