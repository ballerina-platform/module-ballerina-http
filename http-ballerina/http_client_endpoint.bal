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
import ballerina/observe;
import ballerina/time;

////////////////////////////////
///// HTTP Client Endpoint /////
////////////////////////////////

# The HTTP client provides the capability for initiating contact with a remote HTTP service. The API it
# provides includes functions for the standard HTTP methods, forwarding a received request and sending requests
# using custom HTTP verbs.

# + url - Target service url
# + config - The configurations associated with the client
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner
# + cookieStore - Stores the cookies of the client
public client class Client {
    *ClientObject;

    public string url;
    public ClientConfiguration config = {};
    public HttpClient httpClient;
    public CookieStore? cookieStore = ();

    # Gets invoked to initialize the `client`. During initialization, the configurations provided through the `config`
    # record is used to determine which type of additional behaviours are added to the endpoint (e.g., caching,
    # security, circuit breaking).
    #
    # + url - URL of the target service
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public function init(string url, ClientConfiguration? config = ()) returns ClientError? {
        self.config = config ?: {};
        self.url = url;
        var cookieConfigVal = self.config.cookieConfig;
        if (cookieConfigVal is CookieConfig) {
            if (cookieConfigVal.enabled) {
                self.cookieStore = new(cookieConfigVal?.persistentCookieHandler);
            }
        }
        var result = initialize(url, self.config, self.cookieStore);
        if (result is ClientError) {
            return result;
        } else {
            self.httpClient = result;
        }
    }

    # The `Client.post()` function can be used to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function post(@untainted string path, RequestMessage message, TargetType targetType = Response)
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processPost(@untainted string path, RequestMessage message, TargetType targetType)
            returns @tainted Response|PayloadType|ClientError {
        // TODO improve signature once issue https://github.com/ballerina-platform/ballerina-spec/issues/386 is resolved
        // Dependently typed function signature support for ballerina function is required.
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->post(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_POST, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.head()` function can be used to send HTTP HEAD requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function head(@untainted string path, RequestMessage message = ()) returns @tainted
            Response|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->head(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_HEAD, response.statusCode, self.url);
        }
        return response;
    }

    # The `Client.put()` function can be used to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function put(@untainted string path, RequestMessage message, TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processPut(@untainted string path, RequestMessage message, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->put(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_PUT, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # Invokes an HTTP call with the specified HTTP verb.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function execute(@untainted string httpVerb, @untainted string path, RequestMessage message,
            TargetType targetType = Response) returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processExecute(@untainted string httpVerb, @untainted string path, RequestMessage message,
            TargetType targetType) returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->execute(httpVerb, path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, httpVerb, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.patch()` function can be used to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function patch(@untainted string path, RequestMessage message, TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processPatch(@untainted string path, RequestMessage message, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
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
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function delete(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processDelete(@untainted string path, RequestMessage message, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->delete(path, req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_DELETE, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }


    # The `Client.get()` function can be used to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function get(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processGet(@untainted string path, RequestMessage message, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->get(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_GET, response.statusCode, self.url);
        }
        return processResponse(response, targetType);
    }

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function options(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processOptions(@untainted string path, RequestMessage message, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        Response|ClientError response = self.httpClient->options(path, message = req);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(path, HTTP_OPTIONS, response.statusCode, self.url);
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
    remote function forward(@untainted string path, Request request, TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.actions.httpclient.HttpClientAction"
    } external;

    private function processForward(@untainted string path, Request request, TargetType targetType) 
            returns @tainted Response|PayloadType|ClientError {
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
    remote function submit(@untainted string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = buildRequest(message);
        return self.httpClient->submit(httpVerb, path, req);

    }

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http: ClientError` if the invocation fails
    remote function getResponse(HttpFuture httpFuture) returns Response|ClientError {
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
    remote function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Passes the request to an actual network call.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        Response|ClientError response = self.httpClient->getPromisedResponse(promise);
        if (observabilityEnabled && response is Response) {
            addObservabilityInformation(promise.path, promise.method, response.statusCode, self.url);
        }
        return response;
    }

    # This just pass the request to actual network call.
    #
    # + promise - The Push Promise to be rejected
    remote function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }

    # Retrieves the cookie store of the client.
    #
    # + return - The cookie store related to the client
    public function getCookieStore() returns CookieStore? {
        return self.cookieStore;
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
# Following fields are inherited from the other configuration records in addition to the Client specific
# configs.
#
# |                                                         |
# |:------------------------------------------------------- |
# | httpVersion - Copied from CommonClientConfiguration     |
# | http1Settings - Copied from CommonClientConfiguration   |
# | http2Settings - Copied from CommonClientConfiguration   |
# | timeoutInMillis - Copied from CommonClientConfiguration |
# | forwarded - Copied from CommonClientConfiguration       |
# | followRedirects - Copied from CommonClientConfiguration |
# | poolConfig - Copied from CommonClientConfiguration      |
# | cache - Copied from CommonClientConfiguration           |
# | compression - Copied from CommonClientConfiguration     |
# | auth - Copied from CommonClientConfiguration            |
# | circuitBreaker - Copied from CommonClientConfiguration  |
# | retryConfig - Copied from CommonClientConfiguration     |
# | cookieConfig - Copied from CommonClientConfiguration    |
# + secureSocket - SSL/TLS related options
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

isolated function createSimpleHttpClient(HttpClient caller, PoolConfiguration globalPoolConfig) = @java:Method {
   'class: "org.ballerinalang.net.http.clientendpoint.CreateSimpleHttpClient",
   name: "createSimpleHttpClient"
} external;

# Provides settings related to HTTP/2 protocol.
#
# + http2PriorKnowledge - Configuration to enable HTTP/2 prior knowledge
public type ClientHttp2Settings record {|
    boolean http2PriorKnowledge = false;
|};

# Provides configurations for controlling the retrying behavior in failure scenarios.
#
# + count - Number of retry attempts before giving up
# + intervalInMillis - Retry interval in milliseconds
# + backOffFactor - Multiplier, which increases the retry interval exponentially.
# + maxWaitIntervalInMillis - Maximum time of the retry interval in milliseconds
# + statusCodes - HTTP response status codes which are considered as failures
public type RetryConfig record {|
    int count = 0;
    int intervalInMillis = 0;
    float backOffFactor = 0.0;
    int maxWaitIntervalInMillis = 0;
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
# + verifyHostname - Enable/disable host name verification
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

function initialize(string serviceUrl, ClientConfiguration config, CookieStore? cookieStore) returns HttpClient|ClientError {
    boolean httpClientRequired = false;
    string url = serviceUrl;
    if (url.endsWith("/")) {
        int lastIndex = url.length() - 1;
        url = url.substring(0, lastIndex);
    }
    var cbConfig = config.circuitBreaker;
    if (cbConfig is CircuitBreakerConfig) {
        if (url.endsWith("/")) {
            int lastIndex = url.length() - 1;
            url = url.substring(0, lastIndex);
        }
    } else {
        httpClientRequired = true;
    }
    if (httpClientRequired) {
        var redirectConfigVal = config.followRedirects;
        if (redirectConfigVal is FollowRedirects) {
            return createRedirectClient(url, config, cookieStore);
        } else {
            return checkForRetry(url, config, cookieStore);
        }
    } else {
        return createCircuitBreakerClient(url, config, cookieStore);
    }
}

function createRedirectClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
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

function checkForRetry(string url, ClientConfiguration config, CookieStore? cookieStore) returns HttpClient|ClientError {
    var retryConfigVal = config.retryConfig;
    if (retryConfigVal is RetryConfig) {
        return createRetryClient(url, config, cookieStore);
    } else {
         return createCookieClient(url, config, cookieStore);
    }
}

function createCircuitBreakerClient(string uri, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    HttpClient cbHttpClient;
    var cbConfig = configuration.circuitBreaker;
    if (cbConfig is CircuitBreakerConfig) {
        validateCircuitBreakerConfiguration(cbConfig);
        boolean[] statusCodes = populateErrorCodeIndex(cbConfig.statusCodes);
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

        time:Time circuitStartTime = time:currentTime();
        int numberOfBuckets = (cbConfig.rollingWindow.timeWindowInMillis / cbConfig.rollingWindow.bucketSizeInMillis);
        Bucket?[] bucketArray = [];
        int bucketIndex = 0;
        while (bucketIndex < numberOfBuckets) {
            bucketArray[bucketIndex] = {};
            bucketIndex = bucketIndex + 1;
        }

        CircuitBreakerInferredConfig circuitBreakerInferredConfig = {
            failureThreshold: cbConfig.failureThreshold,
            resetTimeInMillis: cbConfig.resetTimeInMillis,
            statusCodes: statusCodes,
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

function createRetryClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var retryConfig = configuration.retryConfig;
    if (retryConfig is RetryConfig) {
        boolean[] statusCodes = populateErrorCodeIndex(retryConfig.statusCodes);
        RetryInferredConfig retryInferredConfig = {
            count: retryConfig.count,
            intervalInMillis: retryConfig.intervalInMillis,
            backOffFactor: retryConfig.backOffFactor,
            maxWaitIntervalInMillis: retryConfig.maxWaitIntervalInMillis,
            statusCodes: statusCodes
        };
        var httpCookieClient = createCookieClient(url, configuration, cookieStore);
        if (httpCookieClient is HttpClient) {
            return new RetryClient(url, configuration, retryInferredConfig, httpCookieClient);
        }
        return httpCookieClient;
    }
    return createCookieClient(url, configuration, cookieStore);
}

function createCookieClient(string url, ClientConfiguration configuration, CookieStore? cookieStore) returns HttpClient|ClientError {
    var cookieConfigVal = configuration.cookieConfig;
    if (cookieConfigVal is CookieConfig) {
        if (!cookieConfigVal.enabled) {
            return createDefaultClient(url, configuration);
        }
        if (configuration.cache.enabled) {
            var httpCachingClient = createHttpCachingClient(url, configuration, configuration.cache);
            if (httpCachingClient is HttpClient) {
                return new CookieClient(url, configuration, cookieConfigVal, httpCachingClient, cookieStore);
            }
            return httpCachingClient;
        }
        var httpSecureClient = createHttpSecureClient(url, configuration);
        if (httpSecureClient is HttpClient) {
            return new CookieClient(url, configuration, cookieConfigVal, httpSecureClient, cookieStore);
        }
        return httpSecureClient;
    }
    return createDefaultClient(url, configuration);
}

function createDefaultClient(string url, ClientConfiguration configuration) returns HttpClient|ClientError {
    if (configuration.cache.enabled) {
        return createHttpCachingClient(url, configuration, configuration.cache);
    }
    return createHttpSecureClient(url, configuration);
}

function processResponse(Response|ClientError result, TargetType targetType) returns @tainted
        Response|PayloadType|ClientError {
    if (targetType is typedesc<Response> || result is ClientError) {
        return result;
    }
    Response response = <Response> checkpanic result;
    int statusCode = response.statusCode;
    if (400 <= statusCode && statusCode <= 499) {
        string errorPayload = check response.getTextPayload();
        ClientRequestError err = error ClientRequestError(errorPayload, statusCode = statusCode);
        return err;
    }
    if (500 <= statusCode && statusCode <= 599) {
        string errorPayload = check response.getTextPayload();
        RemoteServerError err = error RemoteServerError(errorPayload, statusCode = statusCode);
        return err;
    }
    return performDataBinding(response, targetType);
}

function performDataBinding(Response response, TargetType targetType) returns @tainted PayloadType|ClientError {
    if (targetType is typedesc<string>) {
        return response.getTextPayload();
    } else if (targetType is typedesc<xml>) {
        return response.getXmlPayload();
    } else if (targetType is typedesc<byte[]>) {
        return response.getBinaryPayload();
    } else if (targetType is typedesc<record {| anydata...; |}>) {
        json payload = check response.getJsonPayload();
        var result = payload.cloneWithType(targetType);
        if (result is error) {
            return error GenericClientError("payload binding failed: " + result.message(), result);
        }
        return <record {| anydata...; |}> checkpanic result;
    } else if (targetType is typedesc<record {| anydata...; |}[]>) {
        json payload = check response.getJsonPayload();
        var result = payload.cloneWithType(targetType);
        if (result is error) {
            return error GenericClientError("payload binding failed: " + result.message(), result);
        }
        return <record {| anydata...; |}[]> checkpanic result;
    } else if (targetType is typedesc<map<json>>) {
        json payload = check response.getJsonPayload();
        return <map<json>> payload;
    } else if (targetType is typedesc<json>) {
        return response.getJsonPayload();
    }
}
