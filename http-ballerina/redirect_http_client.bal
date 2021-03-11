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

import ballerina/log;

# Provides redirect functionality for HTTP client remote functions.
#
# + url - Target service url
# + config - HTTP ClientConfiguration to be used for HTTP client invocation
# + redirectConfig - Configurations associated with redirect
# + httpClient - HTTP client for outbound HTTP requests
# + currentRedirectCount - Current redirect count of the HTTP client
public client class RedirectClient {

    public string url;
    public ClientConfiguration config;
    public FollowRedirects redirectConfig;
    public HttpClient httpClient;
    public int currentRedirectCount = 0;

    # Creates a redirect client with the given configurations.
    #
    # + url - Target service url
    # + config - HTTP ClientConfiguration to be used for HTTP client invocation
    # + redirectConfig - Configurations associated with redirect
    # + httpClient - HTTP client for outbound HTTP requests
    # + return - The `client` or an `http:ClientError` if the initialization failed
    function init(string url, ClientConfiguration config, FollowRedirects redirectConfig, HttpClient httpClient)
            returns ClientError? {
        self.url = url;
        self.config = config;
        self.redirectConfig = redirectConfig;
        self.httpClient = httpClient;
    }

    # If the received response for the `RedirectClient.get()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.get()` function.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function get(string path, RequestMessage message = ()) returns @tainted Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_GET);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # If the received response for the `RedirectClient.post()` remote function is redirect eligible, redirect will
    # be performed automatically by this `RedirectClient.post()` function.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function post(string path, RequestMessage message) returns @tainted Response|ClientError {
        var result =  performRedirectIfEligible(self, path, <Request>message, HTTP_POST);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # If the received response for the `RedirectClient.head()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.head()` function.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function head(@untainted string path, RequestMessage message = ()) returns @tainted
            Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_HEAD);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # If the received response for the `RedirectClient.put()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.put()` function.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function put(string path, RequestMessage message) returns @tainted Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_PUT);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # The `RedirectClient.forward()` function is used to invoke an HTTP call with inbound request's HTTP verb.
    #
    # + path - Resource path
    # + request - An HTTP inbound request message
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function forward(string path, Request request) returns @tainted Response|ClientError {
        return self.httpClient->forward(path, request);
    }

    # The `RedirectClient.execute()` sends an HTTP request to a service with the specified HTTP verb. Redirect will be
    # performed only for HTTP methods.
    #
    # + httpVerb - The HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function execute(string httpVerb, string path, RequestMessage message) returns @tainted Response|ClientError {
        Request request = <Request>message;
        //Redirection is performed only for HTTP methods
        if (HTTP_NONE == extractHttpOperation(httpVerb)) {
            return self.httpClient->execute(httpVerb, path, request);
        } else {
            var result = performRedirectIfEligible(self, path, request, extractHttpOperation(httpVerb));
            if (result is HttpFuture) {
                return getInvalidTypeError();
            } else {
                return result;
            }
        }
    }

    # If the received response for the `RedirectClient.patch()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.patch()` function.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function patch(string path, RequestMessage message) returns @tainted Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_PATCH);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # If the received response for the `RedirectClient.delete()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.delete()` function.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function delete(string path, RequestMessage message = ()) returns @tainted Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_DELETE);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # If the received response for the `RedirectClient.options()` remote function is redirect eligible, redirect will be
    # performed automatically by this `RedirectClient.options()` function.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function options(string path, RequestMessage message = ()) returns @tainted Response|ClientError {
        var result = performRedirectIfEligible(self, path, <Request>message, HTTP_OPTIONS);
        if (result is HttpFuture) {
            return getInvalidTypeError();
        } else {
            return result;
        }
    }

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `RedirectClient.submit()` function does not give out a `Response` as the result,
    # rather it returns an `HttpFuture` which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission fails
    remote function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        return self.httpClient->submit(httpVerb, path, <Request>message);
    }

    # Retrieves the `http:Response` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        return self.httpClient->getResponse(httpFuture);
    }

    # Checks whether an `http:PushPromise` exists for a previously-submitted request.
    #
    # + httpFuture - The `HttpFuture` relates to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote function hasPromise(HttpFuture httpFuture) returns (boolean) {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Retrieves the next available `http:PushPromise` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Retrieves the promised server push `http:Response` message.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return self.httpClient->getPromisedResponse(promise);
    }

    # Rejects an `http:PushPromise`.
    # When an `http:PushPromise` is rejected, there is no chance of fetching a promised response using the rejected promise.
    #
    # + promise - The Push Promise to be rejected
    remote function rejectPromise(PushPromise promise) {
        self.httpClient->rejectPromise(promise);
    }
}

//Invoke relevant HTTP client action and check the response for redirect eligibility.
function performRedirectIfEligible(RedirectClient redirectClient, string path, Request request,
                                   HttpOperation httpOperation) returns @tainted HttpResponse|ClientError {
    final string originalUrl = redirectClient.url + path;
    log:printDebug("Checking redirect eligibility for original request " + originalUrl);

    Request inRequest = request;
    if !(httpOperation is safeHttpOperation) {
        // When performing redirect operation for non-safe method, message needs to be built before sending out the
        // to keep the request message to subsequent redirect.
        var binaryPayload = check inRequest.getBinaryPayload();
        // Build message for for multipart requests
        inRequest = check populateMultipartRequest(inRequest);
    }
    HttpResponse|ClientError result = invokeEndpoint(path, inRequest, httpOperation, redirectClient.httpClient);
    return checkRedirectEligibility(result, originalUrl, httpOperation, inRequest, redirectClient);
}

//Inspect the response for redirect eligibility.
function checkRedirectEligibility(HttpResponse|ClientError response, string resolvedRequestedURI,
                                  HttpOperation httpVerb, Request request, RedirectClient redirectClient)
                                    returns @untainted HttpResponse|ClientError {
    if (response is Response) {
        if (isRedirectResponse(response.statusCode)) {
            return redirect(response, httpVerb, request, redirectClient, resolvedRequestedURI);
        } else {
            setCountAndResolvedURL(redirectClient, response, resolvedRequestedURI);
            return response;
        }
    } else {
        redirectClient.currentRedirectCount = 0;
        return response;
    }
}

//Check the response status for redirect eligibility.
isolated function isRedirectResponse(int statusCode) returns boolean {
    final string statusCodeValue = statusCode.toString();
    log:printDebug("Response Code : " + statusCodeValue);
    return (statusCode == 300 || statusCode == 301 || statusCode == 302 || statusCode == 303 || statusCode == 305 ||
        statusCode == 307 || statusCode == 308);
}

//If max redirect count is not reached, perform redirection.
function redirect(Response response, HttpOperation httpVerb, Request request,
                  RedirectClient redirectClient, string resolvedRequestedURI) returns @untainted HttpResponse|ClientError {
    int currentCount = redirectClient.currentRedirectCount;
    int maxCount = redirectClient.redirectConfig.maxCount;
    if (currentCount >= maxCount) {
        log:printDebug("Maximum redirect count reached!");
        setCountAndResolvedURL(redirectClient, response, resolvedRequestedURI);
    } else {
        currentCount += 1;
        final string currentCountValue = currentCount.toString();
        log:printDebug("Redirect count : " + currentCountValue);
        redirectClient.currentRedirectCount = currentCount;
        var redirectMethod = getRedirectMethod(httpVerb, response);
        if (redirectMethod is HttpOperation) {
             var location = response.getHeader(LOCATION);
             if (location is string) {
                log:printDebug("Location header value: " + location);
                if (!isAbsolute(location)) {
                    var resolvedURI = resolve(resolvedRequestedURI, location);
                    if (resolvedURI is string) {
                        return performRedirection(resolvedURI, redirectClient, redirectMethod, request,
                            response);
                    } else {
                        redirectClient.currentRedirectCount = 0;
                        return resolvedURI;
                    }
                } else {
                    return performRedirection(location, redirectClient, redirectMethod, request, response);
                }
            } else {
                redirectClient.currentRedirectCount = 0;
                return error GenericClientError("Location header not available!");
            }
        } else {
            setCountAndResolvedURL(redirectClient, response, resolvedRequestedURI);
        }
    }
    return response;
}

function performRedirection(string location, RedirectClient redirectClient, HttpOperation redirectMethod,
                            Request request, Response response) returns @untainted HttpResponse|ClientError {
    CookieStore? cookieStore = ();
    var cookieConfigVal = redirectClient.config.cookieConfig;
    if (cookieConfigVal is CookieConfig) {
        if (cookieConfigVal.enabled) {
            cookieStore = new(cookieConfigVal?.persistentCookieHandler);
        }
    }
    var retryClient = createRetryClient(location, createNewEndpointConfig(redirectClient.config), cookieStore);
    if (retryClient is HttpClient) {
        final string locationValue = location;
        log:printDebug("Redirect using new clientEP : " + locationValue);
        HttpResponse|ClientError result = invokeEndpoint("",
            createRedirectRequest(request, redirectClient.redirectConfig.allowAuthHeaders),
            redirectMethod, retryClient);
        return checkRedirectEligibility(result, location, redirectMethod, request, redirectClient);
    } else {
        return retryClient;
    }
}

//Create a new HTTP client endpoint configuration with a given location as the url.
isolated function createNewEndpointConfig(ClientConfiguration config) returns ClientConfiguration {
    ClientConfiguration newEpConfig = {
        http1Settings: config.http1Settings,
        http2Settings: config.http2Settings,
        circuitBreaker: config.circuitBreaker,
        timeoutInMillis: config.timeoutInMillis,
        httpVersion: config.httpVersion,
        forwarded: config.forwarded,
        followRedirects: config.followRedirects,
        retryConfig: config.retryConfig,
        poolConfig: config.poolConfig,
        secureSocket: config.secureSocket,
        cache: config.cache,
        compression: config.compression,
        auth: config.auth
    };
    return newEpConfig;
}

// Get the HTTP method that should be used for redirection based on the status code.
// As per rfc7231 and rfc7538,
// +-------------------------------------------+-----------+-----------+
// |                                           | Permanent | Temporary |
// +-------------------------------------------+-----------+-----------+
// | Allows changing the request method from   | 301       | 302       |
// | POST to GET                               |           |           |
// | Does not allow changing the request       | 308       | 307       |
// | method from POST to GET                   |           |           |
// +-------------------------------------------+-----------+-----------+
isolated function getRedirectMethod(HttpOperation httpVerb, Response response) returns HttpOperation|() {
    int statusCode = response.statusCode;
    if (statusCode == STATUS_MOVED_PERMANENTLY || statusCode == STATUS_FOUND || statusCode == STATUS_SEE_OTHER) {
        return HTTP_GET;
    }
    if (statusCode == STATUS_TEMPORARY_REDIRECT || statusCode == STATUS_PERMANENT_REDIRECT ||
               statusCode == STATUS_MULTIPLE_CHOICES || statusCode == STATUS_USE_PROXY) {
        return httpVerb;
    }
    final string statusCodeValue = statusCode.toString();
    log:printDebug("unsupported redirect status code" + statusCodeValue);
    return ();
}

isolated function createRedirectRequest(Request request, boolean allowAuthHeaders) returns Request {
    if (allowAuthHeaders) {
        return request;
    }
    request.removeHeader(AUTHORIZATION);
    request.removeHeader(PROXY_AUTHORIZATION);
    return request;
}

isolated function isAbsolute(string locationUrl) returns boolean {
    return (locationUrl.startsWith(HTTP_SCHEME) || locationUrl.startsWith(HTTPS_SCHEME));
}

//Reset the current redirect count to 0 and set the resolved requested URI.
isolated function setCountAndResolvedURL(RedirectClient redirectClient, Response response, string resolvedRequestedURI) {
    final string resolvedRequestedURIValue = resolvedRequestedURI;
    log:printDebug("ultimate response coming from the request: " + resolvedRequestedURIValue);
    redirectClient.currentRedirectCount = 0;
    response.resolvedRequestedURI = resolvedRequestedURI;
}
