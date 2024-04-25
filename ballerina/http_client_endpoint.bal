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

import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/observe;
import ballerina/time;

# The HTTP client provides the capability for initiating contact with a remote HTTP service. The API it
# provides includes the functions for the standard HTTP methods forwarding a received request and sending requests
# using custom HTTP verbs.

# + url - Target service url
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner
# + cookieStore - Stores the cookies of the client
# + requireValidation - Enables the inbound payload validation functionalty which provided by the constraint package
public client isolated class Client {
    *ClientObject;

    private final string url;
    private CookieStore? cookieStore = ();
    final HttpClient httpClient;
    private final boolean requireValidation;

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
        return;
    }

    # The client resource function to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function post [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "postResource"
    } external;

    # The `Client.post()` function can be used to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function post(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPost(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->post(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_POST, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # The client resource function to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function put [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "putResource"
    } external;

    # The `Client.put()` function can be used to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPut(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->put(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PUT, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # The client resource function to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function patch [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "patchResource"
    } external;

    # The `Client.patch()` function can be used to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPatch(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->patch(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_PATCH, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # The client resource function to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function delete [PathParamType ...path](RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "deleteResource"
    } external;

    # The `Client.delete()` function can be used to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (),
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processDelete(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->delete(path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_DELETE, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
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
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function get [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "getResource"
    } external;

    # The `Client.get()` function can be used to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->get(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_GET, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # The client resource function to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function options [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "optionsResource"
    } external;

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->options(path, message = req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, HTTP_OPTIONS, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # Invokes an HTTP call with the specified HTTP verb.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function execute(string httpVerb, string path, RequestMessage message,
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processExecute(string httpVerb, string path, RequestMessage message,
            TargetType targetType, string? mediaType, map<string|string[]>? headers)
            returns Response|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->execute(httpVerb, path, req);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, httpVerb, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # The `Client.forward()` function can be used to invoke an HTTP call with inbound request's HTTP verb
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, TargetType targetType)
            returns Response|anydata|ClientError {
        Response|ClientError response = self.httpClient->forward(path, request);
        if observabilityEnabled && response is Response {
            addObservabilityInformation(path, request.method, response.statusCode, self.url);
        }
        return processResponse(response, targetType, self.requireValidation);
    }

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `Client->submit()` function does not give out a `http:Response` as the result.
    # Rather it returns an `http:HttpFuture` which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value
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
        return new CircuitBreakerClient(uri, configuration, circuitBreakerInferredConfig, cbHttpClient, circuitHealth);
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
            return new RetryClient(url, configuration, retryInferredConfig, httpCookieClient);
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

isolated function createStatusCodeResponseBindingError(boolean generalError, int statusCode, string reasonPhrase,
        map<string[]> headers, anydata body = ()) returns ClientError {
    if generalError {
        return error StatusCodeResponseBindingError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    }
    if 100 <= statusCode && statusCode <= 399 {
        return error StatusCodeBindingSuccessError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    } else if 400 <= statusCode && statusCode <= 499 {
        return error StatusCodeBindingClientRequestError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    } else {
        return error StatusCodeBindingRemoteServerError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    }
}

isolated function processResponse(Response|ClientError response, TargetType targetType, boolean requireValidation)
        returns Response|anydata|ClientError {
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
            return error PayloadBindingClientError("http:ApplicationResponseError creation failed: " + statusCode.toString() +
                " response payload extraction failed", payload);
        } else {
            return createResponseError(statusCode, reasonPhrase, headers, payload);
        }
    }
    if targetType is typedesc<anydata> {
        anydata payload = check performDataBinding(response, targetType);
        if requireValidation {
            return performDataValidation(payload, targetType);
        }
        return payload;
    } else {
        panic error GenericClientError("invalid payload target type");
    }
}

isolated function processResponseNew(Response|ClientError response, typedesc<StatusCodeResponse> targetType, boolean requireValidation)
        returns StatusCodeResponse|ClientError {
    if response is ClientError {
        return response;
    }
    return externProcessResponseNew(response, targetType, requireValidation);
}

isolated function externProcessResponse(Response response, TargetType targetType, boolean requireValidation)
                                  returns Response|anydata|StatusCodeResponse|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponseProcessor",
    name: "processResponse"
} external;

isolated function externProcessResponseNew(Response response, typedesc<StatusCodeResponse> targetType, boolean requireValidation)
                                  returns StatusCodeResponse|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponseProcessor",
    name: "processResponse"
} external;

isolated function hasHttpResponseType(typedesc targetTypeDesc) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.api.service.signature.builder.AbstractPayloadBuilder"
} external;
