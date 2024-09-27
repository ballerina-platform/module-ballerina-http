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

import ballerina/lang.runtime as runtime;
import ballerina/log;

# Derived set of configurations from the `RetryConfig`.
#
# + count - Number of retry attempts before giving up
# + interval - Retry interval in seconds
# + backOffFactor - Multiplier of the retry interval to exponentially increase retry interval
# + maxWaitInterval - Maximum time of the retry interval in seconds
# + statusCodes - HTTP response status codes which are considered as failures
type RetryInferredConfig record {|
    int count = 0;
    decimal interval = 0;
    float backOffFactor = 0.0;
    decimal maxWaitInterval = 0;
    int[] statusCodes = [];
|};

# Provides the HTTP remote functions for interacting with an HTTP endpoint. This is created by wrapping the HTTP client
# to provide retrying over HTTP requests.
#
# + retryInferredConfig - Derived set of configurations associated with retry
# + httpClient - Chain of different HTTP clients which provides the capability for initiating contact with a remote
#                HTTP service in resilient manner.
client isolated class RetryClient {

    final RetryInferredConfig & readonly retryInferredConfig;
    final HttpClient httpClient;

    # Provides the HTTP remote functions for interacting with an HTTP endpoint. This is created by wrapping the HTTP
    # client to provide retrying over HTTP requests.
    #
    # + url - Target service url
    # + config - HTTP ClientConfiguration to be used for HTTP client invocation
    # + retryInferredConfig - Derived set of configurations associated with retry
    # + httpClient - HTTP client for outbound HTTP requests
    # + return - The `client` or an `http:ClientError` if the initialization failed
    isolated function init(string url, ClientConfiguration config, RetryInferredConfig retryInferredConfig,
                                        HttpClient httpClient) returns ClientError? {
        self.retryInferredConfig = retryInferredConfig.cloneReadOnly();
        self.httpClient = httpClient;
        return;
    }

    # The `RetryClient.post()` function wraps the underlying HTTP remote functions in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function post(string path, RequestMessage message) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_POST, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.head()` function wraps the underlying HTTP remote functions in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_HEAD, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.put()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function put(string path, RequestMessage message) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_PUT, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.forward()` function wraps the underlying HTTP remote function in a way to provide retrying
    # functionality for a given endpoint with inbound request's HTTP verb to recover from network level failures.
    #
    # + path - Resource path
    # + request - An HTTP inbound request message
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function forward(string path, Request request) returns Response|ClientError {
        var result = performRetryAction(path, request, HTTP_FORWARD, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.execute()` sends an HTTP request to a service with the specified HTTP verb. The function wraps
    # the underlying HTTP remote function in a way to provide retrying functionality for a given endpoint to recover
    # from network level failures.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function execute(string httpVerb, string path, RequestMessage message) returns Response|ClientError {
        var result = performRetryClientExecuteAction(path, <Request>message, httpVerb, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.patch()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function patch(string path, RequestMessage message) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_PATCH, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.delete()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function delete(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_DELETE, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.get()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function get(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_GET, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The `RetryClient.options()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function options(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = performRetryAction(path, <Request>message, HTTP_OPTIONS, self);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `RetryClient.submit()` function does not give out a `http:Response` as the result.
    # Rather it returns an `http:HttpFuture`, which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        var result = performRetryClientExecuteAction(path, <Request>message, HTTP_SUBMIT, self, verb = httpVerb);
        if result is Response {
            return getInvalidTypeError();
        } else if result is HttpFuture || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Retrieves the `http:Response` for a previously submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        // This need not be retried as the response is already checked when submit is called.
        return self.httpClient->getResponse(httpFuture);
    }

    # Checks whether an `http:PushPromise` exists for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns (boolean) {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Retrieves the next available `http:PushPromise` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Retrieves the promised server push `http:Response` message.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return self.httpClient->getPromisedResponse(promise);
    }

    # Rejects an `http:PushPromise`.
    # When an `http:PushPromise` is rejected, there is no chance of fetching a promised response using the rejected promise.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }
}


// Performs execute remote function of the retry client. extract the corresponding http integer value representation
// of the http verb and invokes the perform action method.
// verb is used for submit methods only.
isolated function performRetryClientExecuteAction(string path, Request request, string httpVerb,
                                         RetryClient retryClient, string verb = "") returns HttpResponse|ClientError {
    HttpOperation connectorAction = extractHttpOperation(httpVerb);
    return performRetryAction(path, request, connectorAction, retryClient, verb = verb);
}

// Handles all the actions exposed through the retry client.
isolated function performRetryAction(string path, Request request, HttpOperation requestAction,
                            RetryClient retryClient, string verb = "") returns HttpResponse|ClientError {
    HttpClient httpClient = retryClient.httpClient;
    int currentRetryCount = 0;
    int retryCount = retryClient.retryInferredConfig.count;
    decimal interval = retryClient.retryInferredConfig.interval;
    int[] statusCodes = retryClient.retryInferredConfig.statusCodes;
    //initializeBackOffFactorAndMaxWaitInterval(retryClient);
    float inputBackOffFactor = retryClient.retryInferredConfig.backOffFactor;
    float backOffFactor = inputBackOffFactor <= 0.0 ? 1.0 : inputBackOffFactor;

    decimal inputMaxWaitInterval = retryClient.retryInferredConfig.maxWaitInterval;
    decimal maxWaitInterval = inputMaxWaitInterval == 0D ? 60 : inputMaxWaitInterval;

    AllRetryAttemptsFailed retryFailedError = error AllRetryAttemptsFailed("All the retry attempts failed.");
    ClientError httpConnectorErr = retryFailedError;
    Request inRequest = request;
    // When performing passthrough scenarios using retry client, message needs to be built before sending out the
    // to keep the request message to retry.
    if !inRequest.hasMsgDataSource() {
        byte[]|error binaryPayload = inRequest.getBinaryPayload();
        if binaryPayload is error {
            log:printDebug("Error building payload for request retry: " + binaryPayload.message());
        }
    }

    while (currentRetryCount < (retryCount + 1)) {
        inRequest = check populateMultipartRequest(inRequest);
        var backendResponse = invokeEndpoint(path, inRequest, requestAction, httpClient, verb = verb);
        if backendResponse is Response {
            int responseStatusCode = backendResponse.statusCode;
            if (statusCodes.indexOf(responseStatusCode) is int) && currentRetryCount < (retryCount) {
                [interval, currentRetryCount] =
                                calculateEffectiveIntervalAndRetryCount(retryClient, currentRetryCount, interval,
                                backOffFactor, maxWaitInterval);
            } else {
                return backendResponse;
            }
        } else if backendResponse is HttpFuture {
            var response = httpClient->getResponse(backendResponse);
            if response is Response {
                int responseStatusCode = response.statusCode;
                if (statusCodes.indexOf(responseStatusCode) is int) && currentRetryCount < (retryCount) {
                    [interval, currentRetryCount] =
                                    calculateEffectiveIntervalAndRetryCount(retryClient, currentRetryCount, interval,
                                    backOffFactor, maxWaitInterval);
                } else {
                    // We return the HttpFuture object as this is called by submit method.
                    return backendResponse;
                }
            } else {
                [interval, currentRetryCount] =
                                calculateEffectiveIntervalAndRetryCount(retryClient, currentRetryCount, interval,
                                backOffFactor, maxWaitInterval);
                httpConnectorErr = response;
            }
        } else if backendResponse is ClientError {
            [interval, currentRetryCount] =
                            calculateEffectiveIntervalAndRetryCount(retryClient, currentRetryCount, interval,
                            backOffFactor, maxWaitInterval);
            httpConnectorErr = backendResponse;
        } else {
            panic error ClientError("invalid response type received");
        }
        runtime:sleep(interval);
    }
    return httpConnectorErr;
}

isolated function calculateEffectiveIntervalAndRetryCount(RetryClient retryClient, int currentRetryCount,
        decimal currentDelay, float backOffFactor, decimal maxWaitInterval) returns [decimal, int] {
    decimal interval = currentDelay;
    if currentRetryCount != 0 {
        interval = getWaitTime(backOffFactor, maxWaitInterval, interval);
    }
    int retryCount = currentRetryCount + 1;
    return [interval, retryCount];
}


isolated function getWaitTime(float backOffFactor, decimal maxWaitTime, decimal interval) returns decimal {
    decimal waitTime = interval * <decimal> backOffFactor;
    return (waitTime > maxWaitTime) ? maxWaitTime : waitTime;
}
