// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/observe;
import ballerina/scan;
import ballerina/time;

# The HTTP client provides functionality to connect to remote HTTP services and perform requests using standard HTTP methods like GET, POST, PUT, DELETE, etc.
#
# + url - Target service url
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner
# + cookieStore - Stores the cookies of the client
# + requireValidation - Enables the inbound payload validation functionality which provided by the constraint package
# + requireLaxDataBinding - Enables or disables relaxed data binding.
public client isolated class Client {
    *ClientObject;

    private final string url;
    private CookieStore? cookieStore = ();
    final HttpClient httpClient;
    private final boolean requireValidation;
    private final boolean requireLaxDataBinding;
    private final decimal callTimeout;

    # Gets invoked to initialize the `client`. During initialization, the configurations provided through the `config`
    # record is used to determine which type of additional behaviours are added to the endpoint (e.g., caching,
    # security, circuit breaking).
    #
    # + url - URL of the target service
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public isolated function init(string url, *ClientConfiguration config) returns ClientError? {
        if config.callTimeout < 0d {
            return error GenericClientError("'callTimeout' must not be negative");
        }
        self.callTimeout = config.callTimeout;
        ClientViewSource? viewSource = takeClientViewSource(url);
        if viewSource is ClientViewSource {
            // A view made by `withDeadline()`, which shares everything with the client it was made from
            self.url = viewSource.url;
            self.cookieStore = viewSource.cookieStore;
            self.httpClient = viewSource.httpClient;
            self.requireValidation = viewSource.requireValidation;
            self.requireLaxDataBinding = viewSource.requireLaxDataBinding;
            return;
        }
        var cookieConfigVal = config.cookieConfig;
        if cookieConfigVal is CookieConfig {
            if cookieConfigVal.enabled {
                self.cookieStore = new(cookieConfigVal?.persistentCookieHandler);
            }
        }
        self.httpClient = check initialize(url, config, self.cookieStore);
        self.url = getURLWithScheme(url, self.httpClient);
        self.requireValidation = config.validation;
        self.requireLaxDataBinding = config.laxDataBinding;
        return;
    }

    # Creates a view of this client in which every call has the given total time, instead of the `callTimeout` of the
    # client. The view shares the connection pool, the cookies and the resiliency behaviour (retry, redirect and
    # circuit breaker state) of this client, so it costs nothing to create one per call, for example
    # `http:Client view = client.withDeadline(5); Order[] orders = check view->/orders;`. It covers the resource and the
    # remote methods alike.
    #
    # All the attempts of a call, that is its retries and its redirects, share the time. When it runs out, the HTTP/1.1
    # connection is closed and dropped from the pool, or the HTTP/2 stream is reset with `CANCEL`, and the call fails
    # with an `http:CallTimeoutError`. The time covers waiting for a connection, making it, writing the request and
    # reading the response, including the body bytes that are read after the `http:Response` has been returned.
    #
    # + deadline - Total time in seconds that a call may take, or `0` for no limit
    # + return - A view of this client with the given time for its calls
    public isolated function withDeadline(decimal deadline) returns Client {
        if deadline < 0d {
            panic error GenericClientError("the deadline of a call must not be negative");
        }
        string viewKey = CLIENT_VIEW_KEY_PREFIX + nextClientViewId().toString();
        ClientViewSource viewSource = new (self.url, self.getCookieStore(), self.httpClient, self.requireValidation,
            self.requireLaxDataBinding);
        lock {
            clientViewSources[viewKey] = viewSource;
        }
        Client|ClientError view = new (viewKey, callTimeout = deadline);
        if view is ClientError {
            discardClientViewSource(viewKey);
            panic view;
        }
        return view;
    }

    # The client resource function to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function get [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "getResource"
    } external;

    # Retrieve a representation of a specified resource from an HTTP endpoint.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        applyCallDeadline(req, self.callTimeout);
        Response|ClientError response = self.httpClient->get(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_GET, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function post [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "postResource"
    } external;

    # Create a new resource or submit data to a resource for processing.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function post(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPost(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        applyCallDeadline(req, self.callTimeout);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->post(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_POST, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function put [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "putResource"
    } external;

    # Create a new resource or replace a representation of a specified resource.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPut(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        applyCallDeadline(req, self.callTimeout);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->put(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PUT, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function delete [PathParamType ...path](RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "deleteResource"
    } external;

    # Remove a specified resource from an HTTP endpoint.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (),
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processDelete(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        applyCallDeadline(req, self.callTimeout);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->delete(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_DELETE, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function patch [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "patchResource"
    } external;

    # Partially update an existing resource in an HTTP endpoint.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPatch(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        applyCallDeadline(req, self.callTimeout);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->patch(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PATCH, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP HEAD requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + params - The query parameters
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    isolated resource function head [PathParamType ...path](map<string|string[]>? headers = (), *QueryParams params)
            returns Response|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "headResource"
    } external;

    # Get the metadata of a resource in the form of headers without the body. Often used for testing the resource existence or finding recent modifications.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        applyCallDeadline(req, self.callTimeout);
        Response|ClientError response = self.httpClient->head(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_HEAD, response.statusCode, self.url);
        }
        return response;
    }

    # The client resource function to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function options [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "optionsResource"
    } external;

    # Get the communication options for a specified resource.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        applyCallDeadline(req, self.callTimeout);
        Response|ClientError response = self.httpClient->options(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_OPTIONS, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # Send a request using any HTTP method. Can be used to invoke the endpoint with a custom or less common HTTP method.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function execute(string httpVerb, string path, RequestMessage message,
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processExecute(string httpVerb, string path, RequestMessage message,
            TargetType targetType, string? mediaType, map<string|string[]>? headers)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        applyCallDeadline(req, self.callTimeout);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->execute(httpVerb, path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, httpVerb, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # Forward an incoming request to another endpoint using the same HTTP method. Can be used in proxy or gateway scenarios.
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - Expected return type (to be used for automatic data binding).
    #                Supported types:
    #                - Built-in subtypes of `anydata` (`string`, `byte[]`, `json|xml`, etc.)
    #                - Custom types (e.g., `User`, `Student?`, `Person[]`, etc.)
    #                - Full HTTP response with headers and status (`http:Response`)
    #                - Stream of Server-Sent Events (`stream<http:SseEvent, error?>`)
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        applyCallDeadline(request, self.callTimeout);
        Response|ClientError response = self.httpClient->forward(path, request);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, request.method, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # Send an asynchronous HTTP request that does not wait for the response immediately. Can be used for non-blocking operations.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = check buildRequest(message, ());
        applyCallDeadline(req, self.callTimeout);
        return self.httpClient->submit(httpVerb, path, req);
    }

    # Cancel a previously submitted asynchronous request. Cancelling closes the HTTP/1.1 connection that carries the
    # request and drops it from the pool, or resets the HTTP/2 stream with `CANCEL`, so the connection is released at
    # once instead of when the remote endpoint responds or goes idle. A cancelled request does not count as a failure of
    # the remote endpoint towards the circuit breaker. Nothing happens if the request has completed.
    #
    # Getting the response of a cancelled request, or reading the body of its response if the response has started,
    # fails with an `http:CallCancelledError`. The outcome of the request on the remote endpoint is unknown to the
    # caller.
    #
    # When the client has a retry or a circuit breaker configuration, the future is returned only once the response
    # has started, so the request can no longer be cancelled before that.
    #
    # + httpFuture - The `http:HttpFuture` related to the asynchronous invocation to cancel
    # + return - An `http:ClientError` if the future is not one that a submitted request returned, otherwise nil
    remote isolated function cancel(HttpFuture httpFuture) returns ClientError? {
        return externCancelCall(httpFuture);
    }

    # Get the response from a previously submitted asynchronous request. Can be used after calling `submit()` action to retrieve the actual response.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http: ClientError` if the invocation fails
    @scan:Suppress {rules: [scan:CHECKPANIC_USAGE], reason: "observe:addTagToSpan with the default span ID and observe:addTagToMetrics never return an error"}
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        Response|ClientError response = self.httpClient->getResponse(httpFuture);
        if observabilityEnabled && response is Response {
            string statusCode = response.statusCode.toString();
            _ = checkpanic observe:addTagToSpan(HTTP_STATUS_CODE, statusCode);
            _ = checkpanic observe:addTagToMetrics(HTTP_STATUS_CODE_GROUP, getStatusCodeRange(statusCode));
        }
        return response;
    }

    # Check if the server has sent a push promise for additional resources. Should be used with HTTP/2 server push functionality.
    #
    # + httpFuture - The `http:HttpFuture` relates to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Get the next server push promise that contains information about additional resources the server wants to send.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Get the actual response data from a server push promise. Can be used to receive resources that the server proactively sends.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        Response|ClientError response = self.httpClient->getPromisedResponse(promise);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(promise.path, promise.method, response.statusCode, self.url);
        }
        return response;
    }

    # Reject a server push promise to decline receiving the additional resource.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }

    # Get the cookie storage associated with this HTTP client. Can be used to access stored cookies for session management.
    #
    # + return - The cookie store related to the client
    public isolated function getCookieStore() returns CookieStore? {
        lock {
            return self.cookieStore;
        }
    }

    # Force the circuit breaker to allow all requests through, ignoring current error rates. Can be used to manually
    # restore service after fixing issues.
    public isolated function circuitBreakerForceClose() {
        do {
            CircuitBreakerClient cbClient = check trap <CircuitBreakerClient>self.httpClient;
            cbClient.forceClose();
        } on fail error err {
            panic error ClientError("illegal method invocation. 'circuitBreakerForceClose()' is allowed for clients " +
                "which have configured with circuit breaker configurations", err);
        }
    }

    # Force the circuit breaker to block all requests until the reset time expires. Can be used to manually stop
    # requests during maintenance or known issues.
    public isolated function circuitBreakerForceOpen() {
        do {
            CircuitBreakerClient cbClient = check trap <CircuitBreakerClient>self.httpClient;
            cbClient.forceOpen();
        } on fail error err {
            panic error ClientError("illegal method invocation. 'circuitBreakerForceOpen()' is allowed for clients " +
                "which have configured with circuit breaker configurations", err);
        }
    }

    # Check the current state of the circuit breaker. Can be used to monitor the health status of your HTTP connections.
    #
    # + return - The current `http:CircuitState` of the circuit breaker
    public isolated function getCircuitBreakerCurrentState() returns CircuitState {
        do {
            CircuitBreakerClient cbClient = check trap <CircuitBreakerClient>self.httpClient;
            return cbClient.getCurrentState();
        } on fail error err {
            panic error ClientError("illegal method invocation. 'getCircuitBreakerCurrentState()' is allowed for " +
                "clients which have configured with circuit breaker configurations", err);
        }
    }
}

isolated function initialize(string url, ClientConfiguration config, CookieStore? cookieStore) returns HttpClient|ClientError {
    var cbConfig = config.circuitBreaker;
    if cbConfig is CircuitBreakerConfig {
        return createCircuitBreakerClient(url, config, cookieStore);
    } else {
        var redirectConfigVal = config.followRedirects;
        if redirectConfigVal is FollowRedirects {
            return createRedirectClient(url, config, cookieStore);
        } else {
            return checkForRetry(url, config, cookieStore);
        }
    }
}

isolated function createRedirectClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var redirectConfig = configuration.followRedirects;
    if redirectConfig is FollowRedirects {
        if redirectConfig.enabled {
            var retryClient = createRetryClient(url, configuration, cookieStore);
            if retryClient is HttpClient {
                return new RedirectClient(url, configuration, redirectConfig, retryClient);
            } else {
                return retryClient;
            }
        } else {
            return createRetryClient(url, configuration, cookieStore);
        }
    } else {
        return createRetryClient(url, configuration, cookieStore);
    }
}

isolated function checkForRetry(string url, ClientConfiguration config, CookieStore? cookieStore) returns HttpClient|ClientError {
    var retryConfigVal = config.retryConfig;
    if retryConfigVal is RetryConfig {
        return createRetryClient(url, config, cookieStore);
    } else {
         return createCookieClient(url, config, cookieStore);
    }
}

isolated function createCircuitBreakerClient(string uri, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    HttpClient cbHttpClient;
    var cbConfig = configuration.circuitBreaker;
    if cbConfig is CircuitBreakerConfig {
        validateCircuitBreakerConfiguration(cbConfig);
        var redirectConfig = configuration.followRedirects;
        if redirectConfig is FollowRedirects {
            var redirectClient = createRedirectClient(uri, configuration, cookieStore);
            if redirectClient is HttpClient {
                cbHttpClient = redirectClient;
            } else {
                return redirectClient;
            }
        } else {
            var retryClient = checkForRetry(uri, configuration, cookieStore);
            if retryClient is HttpClient {
                cbHttpClient = retryClient;
            } else {
                return retryClient;
            }
        }

        time:Utc circuitStartTime = time:utcNow();
        int numberOfBuckets = <int> (cbConfig.rollingWindow.timeWindow / cbConfig.rollingWindow.bucketSize);
        Bucket?[] bucketArray = [];
        int bucketIndex = 0;
        while bucketIndex < numberOfBuckets {
            bucketArray[bucketIndex] = {};
            bucketIndex = bucketIndex + 1;
        }

        CircuitBreakerInferredConfig circuitBreakerInferredConfig = {
            failureThreshold: cbConfig.failureThreshold,
            resetTime: cbConfig.resetTime,
            statusCodes: cbConfig.statusCodes,
            noOfBuckets: numberOfBuckets,
            rollingWindow: cbConfig.rollingWindow
        };
        CircuitHealth circuitHealth = {
            startTime: circuitStartTime,
            lastRequestTime: circuitStartTime,
            lastErrorTime: circuitStartTime,
            lastForcedOpenTime: circuitStartTime,
            totalBuckets: bucketArray
        };
        return new CircuitBreakerClient(uri, circuitBreakerInferredConfig, cbHttpClient, circuitHealth);
    } else {
        return createCookieClient(uri, configuration, cookieStore);
    }
}

isolated function createRetryClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var retryConfig = configuration.retryConfig;
    if retryConfig is RetryConfig {
        RetryInferredConfig retryInferredConfig = {
            count: retryConfig.count,
            interval: retryConfig.interval,
            backOffFactor: retryConfig.backOffFactor,
            maxWaitInterval: retryConfig.maxWaitInterval,
            statusCodes: retryConfig.statusCodes
        };
        var httpCookieClient = createCookieClient(url, configuration, cookieStore);
        if httpCookieClient is HttpClient {
            return new RetryClient(retryInferredConfig, httpCookieClient);
        }
        return httpCookieClient;
    }
    return createCookieClient(url, configuration, cookieStore);
}

isolated function createCookieClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var cookieConfigVal = configuration.cookieConfig;
    if cookieConfigVal is CookieConfig {
        if !cookieConfigVal.enabled {
            return createDefaultClient(url, configuration);
        }
        if configuration.cache.enabled {
            var httpCachingClient = createHttpCachingClient(url, configuration, configuration.cache);
            if httpCachingClient is HttpClient {
                return new CookieClient(url, cookieConfigVal, httpCachingClient, cookieStore);
            }
            return httpCachingClient;
        }
        var httpSecureClient = createHttpSecureClient(url, configuration);
        if httpSecureClient is HttpClient {
            return new CookieClient(url, cookieConfigVal, httpSecureClient, cookieStore);
        }
        return httpSecureClient;
    }
    return createDefaultClient(url, configuration);
}

isolated function createDefaultClient(string url, ClientConfiguration configuration) returns HttpClient|ClientError {
    if configuration.cache.enabled {
        return createHttpCachingClient(url, configuration, configuration.cache);
    }
    return createHttpSecureClient(url, configuration);
}

isolated function getPayload(Response response) returns anydata|error {
    string|error contentTypeValue = response.getHeader(CONTENT_TYPE);
    string value = "";
    if contentTypeValue is error {
        return response.getTextPayload();
    } else {
        value = contentTypeValue;
    }
    var mediaType = mime:getMediaType(value.toLowerAscii());
    if mediaType is mime:InvalidContentTypeError {
        return response.getTextPayload();
    } else {
        match mediaType.primaryType {
            "application" => {
                match mediaType.subType {
                    "json" => {
                        return response.getJsonPayload();
                    }
                    "xml" => {
                        return response.getXmlPayload();
                    }
                    "octet-stream" => {
                        return response.getBinaryPayload();
                    }
                    _ => {
                        return response.getTextPayload();
                    }
                }
            }
            _ => {
                return response.getTextPayload();
            }
        }
    }
}

isolated function getHeaders(Response response) returns map<string[]> {
    map<string[]> headers = {};
    string[] headerKeys = response.getHeaderNames();
    foreach string key in headerKeys {
        string[]|HeaderNotFoundError values = response.getHeaders(key);
        if values is string[] {
            headers[key] = values;
        }
    }
    return headers;
}

isolated function createResponseError(int statusCode, string reasonPhrase, map<string[]> headers, anydata body = ())
        returns ClientRequestError|RemoteServerError {
    if 400 <= statusCode && statusCode <= 499 {
        return error ClientRequestError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    } else {
        return error RemoteServerError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    }
}

// Add proper scheme to the URL if it is not present.
isolated function getURLWithScheme(string url, HttpClient httpClient) returns string {
    return isAbsolute(url) ? url : (httpClient is HttpSecureClient ? HTTPS_SCHEME + url : HTTP_SCHEME + url);
}

isolated function createStatusCodeResponseBindingError(int statusCode, string reasonPhrase, map<string[]> headers,
        anydata body = ()) returns ClientError {
    if 100 <= statusCode && statusCode <= 399 {
        return error StatusCodeResponseBindingError(reasonPhrase, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = false);
    } else if 400 <= statusCode && statusCode <= 499 {
        return error StatusCodeBindingClientRequestError(reasonPhrase, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = false);
    } else {
        return error StatusCodeBindingRemoteServerError(reasonPhrase, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = false);
    }
}

enum DataBindingErrorType {
    HEADER, MEDIA_TYPE, PAYLOAD, GENERIC
}

isolated function createStatusCodeResponseDataBindingError(DataBindingErrorType errorType, boolean fromDefaultStatusCodeMapping,
        int statusCode, string reasonPhrase, map<string[]> headers, anydata body = (), error? cause = ()) returns ClientError {
    match (errorType) {
        HEADER => {
            if cause is HeaderValidationClientError {
                return error HeaderValidationStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
            }
            return error HeaderBindingStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
        }
        MEDIA_TYPE => {
            if cause is MediaTypeValidationClientError {
                return error MediaTypeValidationStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
            }
            return error MediaTypeBindingStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
        }
        PAYLOAD => {
            if cause is PayloadValidationClientError {
                return error PayloadValidationStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
            }
            return error PayloadBindingStatusCodeClientError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
        }
        _ => {
            return error StatusCodeResponseBindingError(reasonPhrase, cause, statusCode = statusCode, headers = headers, body = body, fromDefaultStatusCodeMapping = fromDefaultStatusCodeMapping);
        }
    }
}

isolated function processResponse(Response|ClientError response, TargetType targetType, boolean requireValidation, boolean requireLaxDataBinding)
        returns Response|stream<SseEvent, error?>|anydata|ClientError {
    if response is ClientError || hasHttpResponseType(targetType) {
        return response;
    }
    int statusCode = response.statusCode;
    if 400 <= statusCode && statusCode <= 599 {
        string reasonPhrase = response.reasonPhrase;
        map<string[]> headers = getHeaders(response);
        anydata|error payload = getPayload(response);
        if payload is error {
            if payload is NoContentError {
                return createResponseError(statusCode, reasonPhrase, headers);
            }
            CallTimeoutError|CallCancelledError? callAbortError = findCallAbortError(payload);
            if callAbortError is error {
                return callAbortError;
            }
            return error PayloadBindingClientError("http:ApplicationResponseError creation failed: " + statusCode.toString() +
                " response payload extraction failed", payload);
        } else {
            return createResponseError(statusCode, reasonPhrase, headers, payload);
        }
    }
    if targetType is typedesc<anydata> {
        anydata|ClientError payload = performDataBinding(response, targetType, requireLaxDataBinding);
        if payload is ClientError {
            // A body that failed because its call ran out of time, or was cancelled, fails with that error
            CallTimeoutError|CallCancelledError? callAbortError = findCallAbortError(payload);
            return callAbortError is error ? callAbortError : payload;
        }
        if requireValidation {
            return performDataValidation(payload, targetType);
        }
        return payload;
    }
    if targetType is typedesc<stream<SseEvent, error?>> {
        return getSseEventStream(response);
    }
    if targetType is typedesc<anydata|stream<SseEvent, error?>> {
        return error PayloadBindingClientError("payload binding failed: " +
            "Target return type must not be a union of stream<http:SseEvent, error?> and anydata");
    }
    panic error GenericClientError("invalid payload target type");
}

isolated function getSseEventStream(Response response) returns stream<SseEvent, error?>|ClientError {
    check validateEventStreamContentType(response);
    mime:Entity entity = check response.getEntityWithBodyAndWithoutHeaders();
    stream<byte[], io:Error?>|mime:Error byteStream = getEntityAvailableByteStream(entity);
    if byteStream is mime:Error {
        return error GenericClientError("Error occurred while retrieving the byte stream from the response",
            byteStream);
    }
    BytesToEventStreamGenerator bytesToEventStreamGenerator = new (byteStream);
    stream<SseEvent, error?> eventStream = new (bytesToEventStreamGenerator);
    return eventStream;
}

isolated function validateEventStreamContentType(Response response) returns ClientError? {
    string|HeaderNotFoundError contentType = response.getHeader(CONTENT_TYPE);
    if contentType is HeaderNotFoundError || !contentType.startsWith(mime:TEXT_EVENT_STREAM) {
        return error PayloadBindingClientError(string `invalid payload target type. The response is not of ${mime:TEXT_EVENT_STREAM} content type.`);
    }
}

isolated function processResponseNew(Response|ClientError response, typedesc<StatusCodeResponse> targetType, boolean requireValidation,
    boolean requireLaxDataBinding) returns StatusCodeResponse|ClientError {
    if response is ClientError {
        return response;
    }
    return externProcessResponseNew(response, targetType, requireValidation, requireLaxDataBinding);
}

isolated function externProcessResponse(Response response, TargetType targetType, boolean requireValidation, boolean requireLaxDataBinding)
                                  returns Response|anydata|StatusCodeResponse|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponseProcessor",
    name: "processResponse"
} external;

isolated function externProcessResponseNew(Response response, typedesc<StatusCodeResponse> targetType, boolean requireValidation, boolean requireLaxDataBinding)
                                  returns StatusCodeResponse|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponseProcessor",
    name: "processResponse"
} external;

isolated function hasHttpResponseType(typedesc targetTypeDesc) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.api.service.signature.builder.AbstractPayloadBuilder"
} external;

const CLIENT_VIEW_KEY_PREFIX = "\u{0}client-view:";

// What a view made by `Client.withDeadline()` takes over from the client it was made from
isolated class ClientViewSource {
    final string url;
    final CookieStore? cookieStore;
    final HttpClient httpClient;
    final boolean requireValidation;
    final boolean requireLaxDataBinding;

    isolated function init(string url, CookieStore? cookieStore, HttpClient httpClient, boolean requireValidation,
            boolean requireLaxDataBinding) {
        self.url = url;
        self.cookieStore = cookieStore;
        self.httpClient = httpClient;
        self.requireValidation = requireValidation;
        self.requireLaxDataBinding = requireLaxDataBinding;
    }
}

isolated map<ClientViewSource> clientViewSources = {};
isolated int clientViewCounter = 0;

isolated function nextClientViewId() returns int {
    lock {
        clientViewCounter += 1;
        return clientViewCounter;
    }
}

isolated function takeClientViewSource(string url) returns ClientViewSource? {
    if !url.startsWith(CLIENT_VIEW_KEY_PREFIX) {
        return;
    }
    lock {
        return clientViewSources.removeIfHasKey(url);
    }
}

isolated function discardClientViewSource(string viewKey) {
    lock {
        _ = clientViewSources.removeIfHasKey(viewKey);
    }
}

// Starts the total time of the call the request is sent for, which every attempt of the call shares
isolated function applyCallDeadline(Request req, decimal callTimeout) {
    externSetCallDeadline(req, callTimeout);
}
