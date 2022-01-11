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

import ballerina/crypto;
import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/observe;
import ballerina/time;
import ballerina/log;

# The HTTP client provides the capability for initiating contact with a remote HTTP service. The API it
# provides includes the functions for the standard HTTP methods forwarding a received request and sending requests
# using custom HTTP verbs.

# + url - Target service url
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner
# + cookieStore - Stores the cookies of the client
public client isolated class Client {
    *ClientObject;

    private final string url;
    private CookieStore? cookieStore = ();
    public final HttpClient httpClient;

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
        if (cookieConfigVal is CookieConfig) {
            if (cookieConfigVal.enabled) {
                self.cookieStore = new(cookieConfigVal?.persistentCookieHandler);
            }
        }
        self.httpClient = check initialize(url, config, self.cookieStore);
        return;
    }

    # The `Client.post()` function can be used to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function post(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPost(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|PayloadType|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->post(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_POST, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.put()` function can be used to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPut(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|PayloadType|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->put(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_PUT, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.patch()` function can be used to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processPatch(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|PayloadType|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->patch(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_PATCH, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.delete()` function can be used to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (),
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processDelete(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|PayloadType|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->delete(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_DELETE, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.head()` function can be used to send HTTP HEAD requests to HTTP endpoints.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->head(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_HEAD, response.statusCode, self.url);
        }
        return response;
    }

    # The `Client.get()` function can be used to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|PayloadType|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->get(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_GET, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|PayloadType|ClientError {
        Request req = buildRequestWithHeaders(headers);
        Response|ClientError response = self.httpClient->options(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_OPTIONS, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # Invokes an HTTP call with the specified HTTP verb.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function execute(string httpVerb, string path, RequestMessage message,
            map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processExecute(string httpVerb, string path, RequestMessage message,
            TargetType targetType, string? mediaType, map<string|string[]>? headers)
            returns Response|PayloadType|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        Response|ClientError response = self.httpClient->execute(httpVerb, path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, httpVerb, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.forward()` function can be used to invoke an HTTP call with inbound request's HTTP verb
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, TargetType targetType)
            returns Response|PayloadType|ClientError {
        Response|ClientError response = self.httpClient->forward(path, request);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, request.method, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
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
        if (observabilityEnabled && response is Response) {
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
        if (observabilityEnabled && response is Response) {
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
}

# Represents a single service and its related configurations.
#
# + url - URL of the target service
# + secureSocket - Configurations for secure communication with the remote HTTP endpoint
public type TargetService record {|
    string url = "";
    ClientSecureSocket? secureSocket = ();
|};

# Provides a set of configurations for controlling the behaviours when communicating with a remote HTTP endpoint.
# The following fields are inherited from the other configuration records in addition to the `Client`-specific
# configs.
#
# + secureSocket - SSL/TLS-related options
public type ClientConfiguration record {|
    *CommonClientConfiguration;
    ClientSecureSocket? secureSocket = ();
|};

# Provides settings related to HTTP/1.x protocol.
#
# + keepAlive - Specifies whether to reuse a connection for multiple requests
# + chunking - The chunking behaviour of the request
# + proxy - Proxy server related options
public type ClientHttp1Settings record {|
    KeepAlive keepAlive = KEEPALIVE_AUTO;
    Chunking chunking = CHUNKING_AUTO;
    ProxyConfig? proxy = ();
|};

# Provides inbound response status line, total header and entity body size threshold configurations.
#
# + maxStatusLineLength - Maximum allowed length for response status line(`HTTP/1.1 200 OK`). Exceeding this limit will
#                         result in a `ClientError`
# + maxHeaderSize - Maximum allowed size for headers. Exceeding this limit will result in a `ClientError`
# + maxEntityBodySize - Maximum allowed size for the entity body. By default it is set to -1 which means there is no
#                       restriction `maxEntityBodySize`, On the Exceeding this limit will result in a `ClientError`
public type ResponseLimitConfigs record {|
    int maxStatusLineLength = 4096;
    int maxHeaderSize = 8192;
    int maxEntityBodySize = -1;
|};

# Provides settings related to HTTP/2 protocol.
#
# + http2PriorKnowledge - Configuration to enable HTTP/2 prior knowledge
public type ClientHttp2Settings record {|
    boolean http2PriorKnowledge = false;
|};

# Provides configurations for controlling the retrying behavior in failure scenarios.
#
# + count - Number of retry attempts before giving up
# + interval - Retry interval in seconds
# + backOffFactor - Multiplier, which increases the retry interval exponentially.
# + maxWaitInterval - Maximum time of the retry interval in seconds
# + statusCodes - HTTP response status codes which are considered as failures
public type RetryConfig record {|
    int count = 0;
    decimal interval = 0;
    float backOffFactor = 0.0;
    decimal maxWaitInterval = 0;
    int[] statusCodes = [];
|};

# Provides configurations for facilitating secure communication with a remote HTTP endpoint.
#
# + enable - Enable SSL validation
# + cert - Configurations associated with `crypto:TrustStore` or single certificate file that the client trusts
# + key - Configurations associated with `crypto:KeyStore` or combination of certificate and private key of the client
# + protocol - SSL/TLS protocol related options
# + certValidation - Certificate validation against OCSP_CRL, OCSP_STAPLING related options
# + ciphers - List of ciphers to be used
#             eg: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
# + verifyHostName - Enable/disable host name verification
# + shareSession - Enable/disable new SSL session creation
# + handshakeTimeout - SSL handshake time out
# + sessionTimeout - SSL session time out
public type ClientSecureSocket record {|
    boolean enable = true;
    crypto:TrustStore|string cert?;
    crypto:KeyStore|CertKey key?;
    record {|
        Protocol name;
        string[] versions = [];
    |} protocol?;
    record {|
        CertValidationType 'type = OCSP_STAPLING;
        int cacheSize;
        int cacheValidityPeriod;
    |} certValidation?;
    string[] ciphers?;
    boolean verifyHostName = true;
    boolean shareSession = true;
    decimal handshakeTimeout?;
    decimal sessionTimeout?;
|};

# Provides configurations for controlling the endpoint's behaviour in response to HTTP redirect related responses.
# The response status codes of 301, 302, and 303 are redirected using a GET request while 300, 305, 307, and 308
# status codes use the original request HTTP method during redirection.
#
# + enabled - Enable/disable redirection
# + maxCount - Maximum number of redirects to follow
# + allowAuthHeaders - By default Authorization and Proxy-Authorization headers are removed from the redirect requests.
#                      Set it to true if Auth headers are needed to be sent during the redirection
public type FollowRedirects record {|
    boolean enabled = false;
    int maxCount = 5;
    boolean allowAuthHeaders = false;
|};

# Proxy server configurations to be used with the HTTP client endpoint.
#
# + host - Host name of the proxy server
# + port - Proxy server port
# + userName - Proxy server username
# + password - proxy server password
public type ProxyConfig record {|
    string host = "";
    int port = 0;
    string userName = "";
    string password = "";
|};

# Client configuration for cookies.
#
# + enabled - User agents provide users with a mechanism for disabling or enabling cookies
# + maxCookiesPerDomain - Maximum number of cookies per domain, which is 50
# + maxTotalCookieCount - Maximum number of total cookies allowed to be stored in cookie store, which is 3000
# + blockThirdPartyCookies - User can block cookies from third party responses and refuse to send cookies for third party requests, if needed
# + persistentCookieHandler - To manage persistent cookies, users are provided with a mechanism for specifying a persistent cookie store with their own mechanism
#                             which references the persistent cookie handler or specifying the CSV persistent cookie handler. If not specified any, only the session cookies are used
public type CookieConfig record {|
     boolean enabled = false;
     int maxCookiesPerDomain = 50;
     int maxTotalCookieCount = 3000;
     boolean blockThirdPartyCookies = true;
     PersistentCookieHandler persistentCookieHandler?;
|};

isolated function initialize(string url, ClientConfiguration config, CookieStore? cookieStore) returns HttpClient|ClientError {
    var cbConfig = config.circuitBreaker;
    if (cbConfig is CircuitBreakerConfig) {
        return createCircuitBreakerClient(url, config, cookieStore);
    } else {
        var redirectConfigVal = config.followRedirects;
        if (redirectConfigVal is FollowRedirects) {
            return createRedirectClient(url, config, cookieStore);
        } else {
            return checkForRetry(url, config, cookieStore);
        }
    }
}

isolated function createRedirectClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var redirectConfig = configuration.followRedirects;
    if (redirectConfig is FollowRedirects) {
        if (redirectConfig.enabled) {
            var retryClient = createRetryClient(url, configuration, cookieStore);
            if (retryClient is HttpClient) {
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
    if (retryConfigVal is RetryConfig) {
        return createRetryClient(url, config, cookieStore);
    } else {
         return createCookieClient(url, config, cookieStore);
    }
}

isolated function createCircuitBreakerClient(string uri, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    HttpClient cbHttpClient;
    var cbConfig = configuration.circuitBreaker;
    if (cbConfig is CircuitBreakerConfig) {
        validateCircuitBreakerConfiguration(cbConfig);
        var redirectConfig = configuration.followRedirects;
        if (redirectConfig is FollowRedirects) {
            var redirectClient = createRedirectClient(uri, configuration, cookieStore);
            if (redirectClient is HttpClient) {
                cbHttpClient = redirectClient;
            } else {
                return redirectClient;
            }
        } else {
            var retryClient = checkForRetry(uri, configuration, cookieStore);
            if (retryClient is HttpClient) {
                cbHttpClient = retryClient;
            } else {
                return retryClient;
            }
        }

        time:Utc circuitStartTime = time:utcNow();
        int numberOfBuckets = <int> (cbConfig.rollingWindow.timeWindow / cbConfig.rollingWindow.bucketSize);
        Bucket?[] bucketArray = [];
        int bucketIndex = 0;
        while (bucketIndex < numberOfBuckets) {
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
    if (retryConfig is RetryConfig) {
        RetryInferredConfig retryInferredConfig = {
            count: retryConfig.count,
            interval: retryConfig.interval,
            backOffFactor: retryConfig.backOffFactor,
            maxWaitInterval: retryConfig.maxWaitInterval,
            statusCodes: retryConfig.statusCodes
        };
        var httpCookieClient = createCookieClient(url, configuration, cookieStore);
        if (httpCookieClient is HttpClient) {
            return new RetryClient(url, configuration, retryInferredConfig, httpCookieClient);
        }
        return httpCookieClient;
    }
    return createCookieClient(url, configuration, cookieStore);
}

isolated function createCookieClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var cookieConfigVal = configuration.cookieConfig;
    if (cookieConfigVal is CookieConfig) {
        if (!cookieConfigVal.enabled) {
            return createDefaultClient(url, configuration);
        }
        if (configuration.cache.enabled) {
            var httpCachingClient = createHttpCachingClient(url, configuration, configuration.cache);
            if (httpCachingClient is HttpClient) {
                return new CookieClient(url, cookieConfigVal, httpCachingClient, cookieStore);
            }
            return httpCachingClient;
        }
        var httpSecureClient = createHttpSecureClient(url, configuration);
        if (httpSecureClient is HttpClient) {
            return new CookieClient(url, cookieConfigVal, httpSecureClient, cookieStore);
        }
        return httpSecureClient;
    }
    return createDefaultClient(url, configuration);
}

isolated function createDefaultClient(string url, ClientConfiguration configuration) returns HttpClient|ClientError {
    if (configuration.cache.enabled) {
        return createHttpCachingClient(url, configuration, configuration.cache);
    }
    return createHttpSecureClient(url, configuration);
}

isolated function processResponse(Response|ClientError response, TargetType targetType) returns Response|PayloadType|ClientError {
    if (targetType is typedesc<Response> || response is ClientError) {
        return response;
    }
    int statusCode = response.statusCode;
    if (400 <= statusCode && statusCode <= 599) {
        string reasonPhrase = response.reasonPhrase;
        map<string[]> headers = getHeaders(response);
        anydata|error payload = getPayload(response);
        if (payload is error) {
            if (payload is NoContentError) {
                return createResponseError(statusCode, reasonPhrase, headers);
            }
            return error PayloadBindingError("http:ApplicationResponseError creation failed: " + statusCode.toString() +
                " response payload extraction failed", payload);
        } else {
            return createResponseError(statusCode, reasonPhrase, headers, payload);
        }
    }
    return performDataBinding(response, targetType);
}

isolated function performDataBinding(Response response, TargetType targetType) returns PayloadType|ClientError {
    if (targetType is typedesc<string>) {
        return response.getTextPayload();
    } else if (targetType is typedesc<string?>) {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? () : payload;
    } else if (targetType is typedesc<map<string>>) {
        string payload = check response.getTextPayload();
        return getFormDataMap(payload);
    } else if (targetType is typedesc<map<string>?>) {
        string|ClientError payload = response.getTextPayload();
        if payload is error {
            if payload is NoContentError {
                return;
            }
            return payload;
        }
        return getFormDataMap(payload);
    } else if (targetType is typedesc<xml>) {
        return response.getXmlPayload();
    } else if (targetType is typedesc<xml?>) {
        xml|ClientError payload = response.getXmlPayload();
        return payload is NoContentError ? () : payload;
    } else if (targetType is typedesc<byte[]>) {
        return response.getBinaryPayload();
    } else if (targetType is typedesc<byte[]?>) {
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is byte[] {
            return payload.length() == 0 ? () : payload;
        }
        return payload;
    } else if (targetType is typedesc<record {| anydata...; |}>) {
        json payload = check response.getJsonPayload();
        var result = payload.cloneWithType(targetType);
        return result is error ? createPayloadBindingError(result) : result;
    } else if (targetType is typedesc<record {| anydata...; |}?>) {
        json|ClientError payload = response.getJsonPayload();
        if payload is json {
            var result = payload.cloneWithType(targetType);
            return result is error ? createPayloadBindingError(result) : result;
        } else {
            return payload is NoContentError ? () : payload;
        }
    } else if (targetType is typedesc<record {| anydata...; |}[]>) {
        json payload = check response.getJsonPayload();
        var result = payload.cloneWithType(targetType);
        return result is error ? createPayloadBindingError(result) : result;
    } else if (targetType is typedesc<record {| anydata...; |}[]?>) {
        json|ClientError payload = response.getJsonPayload();
        if payload is json {
            var result = payload.cloneWithType(targetType);
            return result is error ? createPayloadBindingError(result) : result;
        } else {
            return payload is NoContentError ? () : payload;
        }
    } else if (targetType is typedesc<map<json>>) {
        json payload = check response.getJsonPayload();
        return <map<json>> payload;
    } else if (targetType is typedesc<json>) {
        json|ClientError result = response.getJsonPayload();
        return result is NoContentError ? (): result;
    } else {
        // Consume payload to avoid memory leaks
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is error {
            log:printDebug("Error releasing payload during invalid target typed data binding: " + payload.message());
        }
        return error ClientError("invalid target type, expected: http:Response, string, xml, json, map<json>, byte[], record, record[] or a union of such a type with nil");
    }
}

isolated function getPayload(Response response) returns anydata|error {
    string|error contentTypeValue = response.getHeader(CONTENT_TYPE);
    string value = "";
    if (contentTypeValue is error) {
        return response.getTextPayload();
    } else {
        value = contentTypeValue;
    }
    var mediaType = mime:getMediaType(value.toLowerAscii());
    if (mediaType is mime:InvalidContentTypeError) {
        return response.getTextPayload();
    } else {
        match (mediaType.primaryType) {
            "application" => {
                match (mediaType.subType) {
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
        if (values is string[]) {
            headers[key] = values;
        }
    }
    return headers;
}

isolated function createResponseError(int statusCode, string reasonPhrase, map<string[]> headers, anydata body = ())
        returns ClientRequestError|RemoteServerError {
    if (400 <= statusCode && statusCode <= 499) {
        return error ClientRequestError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    } else {
        return error RemoteServerError(reasonPhrase, statusCode = statusCode, headers = headers, body = body);
    }
}

isolated function createPayloadBindingError(error result) returns PayloadBindingError {
    string errPrefix = "Payload binding failed: ";
    var errMsg = result.detail()["message"];
    if errMsg is string {
        return error PayloadBindingError(errPrefix + errMsg, result);
    }
    return error PayloadBindingError(errPrefix + result.message(), result);
}

# Represents HTTP methods.
public enum Method {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS
}
