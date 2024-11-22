// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/jballerina.java;
import ballerina/observe;

# The HTTP status code client provides the capability for initiating contact with a remote HTTP service. The API it
# provides includes the functions for the standard HTTP methods forwarding a received request and sending requests
# using custom HTTP verbs. The responses can be binded to `http:StatusCodeResponse` types

# + url - Target service url
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner
# + cookieStore - Stores the cookies of the client
# + requireValidation - Enables the inbound payload validation functionalty which provided by the constraint package
# + requireLaxDataBinding - Enables or disalbles relaxed data binding on the client side.
public client isolated class StatusCodeClient {
    *StatusCodeClientObject;

    private final string url;
    private CookieStore? cookieStore = ();
    final HttpClient httpClient;
    private final boolean requireValidation;
    private final boolean requireLaxDataBinding;

    # Gets invoked to initialize the `client`. During initialization, the configurations provided through the `config`
    # record is used to determine which type of additional behaviours are added to the endpoint (e.g., caching,
    # security, circuit breaking).
    #
    # + url - URL of the target service
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public isolated function init(string url, *ClientConfiguration config) returns ClientError? {
        self.url = url;
        var cookieConfigVal = config.cookieConfig;
        if cookieConfigVal is CookieConfig {
            if cookieConfigVal.enabled {
                self.cookieStore = new(cookieConfigVal?.persistentCookieHandler);
            }
        }
        self.httpClient = check initialize(url, config, self.cookieStore);
        self.requireValidation = config.validation;
        self.requireLaxDataBinding = config.laxDataBinding;
        return;
    }

    # The client resource function to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function post [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), typedesc<StatusCodeResponse> targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "postResource"
    } external;

    # The `Client.post()` function can be used to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function post(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPost(string path, RequestMessage message, typedesc<StatusCodeResponse> targetType,
            string? mediaType, map<string|string[]>? headers) returns StatusCodeResponse|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->post(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_POST, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function put [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), typedesc<StatusCodeResponse> targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "putResource"
    } external;

    # The `Client.put()` function can be used to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPut(string path, RequestMessage message, typedesc<StatusCodeResponse> targetType,
            string? mediaType, map<string|string[]>? headers) returns StatusCodeResponse|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->put(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PUT, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function patch [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "patchResource"
    } external;

    # The `Client.patch()` function can be used to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPatch(string path, RequestMessage message, typedesc<StatusCodeResponse> targetType,
            string? mediaType, map<string|string[]>? headers) returns StatusCodeResponse|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->patch(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PATCH, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function delete [PathParamType ...path](RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "deleteResource"
    } external;

    # The `Client.delete()` function can be used to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (),
            map<string|string[]>? headers = (), string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processDelete(string path, RequestMessage message, typedesc<StatusCodeResponse> targetType,
            string? mediaType, map<string|string[]>? headers) returns StatusCodeResponse|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->delete(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_DELETE, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
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

    # The `Client.head()` function can be used to send HTTP HEAD requests to HTTP endpoints.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->head(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_HEAD, response.statusCode, self.url);
        }
        return response;
    }
    
    # The client resource function to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function get [PathParamType ...path](map<string|string[]>? headers = (), typedesc<StatusCodeResponse> targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "getResource"
    } external;

    # The `Client.get()` function can be used to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, typedesc<StatusCodeResponse> targetType)
            returns StatusCodeResponse|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->get(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_GET, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The client resource function to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function options [PathParamType ...path](map<string|string[]>? headers = (), typedesc<StatusCodeResponse> targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "optionsResource"
    } external;

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, typedesc<StatusCodeResponse> targetType)
            returns StatusCodeResponse|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->options(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_OPTIONS, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # Invokes an HTTP call with the specified HTTP verb.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function execute(string httpVerb, string path, RequestMessage message,
            map<string|string[]>? headers = (), string? mediaType = (), typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processExecute(string httpVerb, string path, RequestMessage message,
            typedesc<StatusCodeResponse> targetType, string? mediaType, map<string|string[]>? headers)
            returns StatusCodeResponse|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->execute(httpVerb, path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, httpVerb, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The `Client.forward()` function can be used to invoke an HTTP call with inbound request's HTTP verb
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - HTTP status code response, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, typedesc<StatusCodeResponse> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, typedesc<StatusCodeResponse> targetType)
            returns StatusCodeResponse|ClientError {
        Response|ClientError response = self.httpClient->forward(path, request);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, request.method, response.statusCode, self.url);
        }
        return processResponseNew(response, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `Client->submit()` function does not give out a `http:Response` as the result.
    # Rather it returns an `http:HttpFuture` which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = check buildRequest(message, ());
        return self.httpClient->submit(httpVerb, path, req);
    }

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http: ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        Response|ClientError response = self.httpClient->getResponse(httpFuture);
        if observabilityEnabled && response is Response {
            string statusCode = response.statusCode.toString();
            _ = checkpanic observe:addTagToSpan(HTTP_STATUS_CODE, statusCode);
            _ = checkpanic observe:addTagToMetrics(HTTP_STATUS_CODE_GROUP, getStatusCodeRange(statusCode));
        }
        return response;
    }

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` relates to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Passes the request to an actual network call.
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

    # This just pass the request to actual network call.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }

    # Retrieves the cookie store of the client.
    #
    # + return - The cookie store related to the client
    public isolated function getCookieStore() returns CookieStore? {
        lock {
            return self.cookieStore;
        }
    }

    # The circuit breaker client related method to force the circuit into a closed state in which it will allow
    # requests regardless of the error percentage until the failure threshold exceeds.
    public isolated function circuitBreakerForceClose() {
        do {
            CircuitBreakerClient cbClient = check trap <CircuitBreakerClient>self.httpClient;
            cbClient.forceClose();
        } on fail error err {
            panic error ClientError("illegal method invocation. 'circuitBreakerForceClose()' is allowed for clients " +
                "which have configured with circuit breaker configurations", err);
        }
    }

    # The circuit breaker client related method to force the circuit into a open state in which it will suspend all
    # requests until `resetTime` interval exceeds.
    public isolated function circuitBreakerForceOpen() {
        do {
            CircuitBreakerClient cbClient = check trap <CircuitBreakerClient>self.httpClient;
            cbClient.forceOpen();
        } on fail error err {
            panic error ClientError("illegal method invocation. 'circuitBreakerForceOpen()' is allowed for clients " +
                "which have configured with circuit breaker configurations", err);
        }
    }

    # The circuit breaker client related method to provides the `http:CircuitState` of the circuit breaker.
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
