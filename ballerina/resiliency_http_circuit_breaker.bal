// Copyright (c) 2018 WSO2 Inc. (//www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/time;

# A finite type for modeling the states of the Circuit Breaker. The Circuit Breaker starts in the `CLOSED` state.
# If any failure thresholds are exceeded during execution, the circuit trips and goes to the `OPEN` state. After
# the specified timeout period expires, the circuit goes to the `HALF_OPEN` state. If the trial request sent while
# in the `HALF_OPEN` state succeeds, the circuit goes back to the `CLOSED` state.
public type CircuitState CB_OPEN_STATE|CB_HALF_OPEN_STATE|CB_CLOSED_STATE;

# Represents the open state of the circuit. When the Circuit Breaker is in `OPEN` state, requests will fail
# immediately.
public const CB_OPEN_STATE = "OPEN";

# Represents the half-open state of the circuit. When the Circuit Breaker is in `HALF_OPEN` state, a trial request
# will be sent to the upstream service. If it fails, the circuit will trip again and move to the `OPEN` state. If not,
# it will move to the `CLOSED` state.
public const CB_HALF_OPEN_STATE = "HALF_OPEN";

# Represents the closed state of the circuit. When the Circuit Breaker is in `CLOSED` state, all requests will be
# allowed to go through to the upstream service. If the failures exceed the configured threhold values, the circuit
# will trip and move to the `OPEN` state.
public const CB_CLOSED_STATE = "CLOSED";

# Maintains the health of the Circuit Breaker.
public type CircuitHealth record {|
    # Whether last request is success or not
    boolean lastRequestSuccess = false;
    # Total request count received within the `RollingWindow`
    int totalRequestCount = 0;
    # ID of the last bucket used in Circuit Breaker calculations
    int lastUsedBucketId = 0;
    # Circuit Breaker start time
    time:Utc startTime = time:utcNow();
    # The time that the last request received
    time:Utc lastRequestTime?;
    # The time that the last error occurred
    time:Utc lastErrorTime?;
    # The time that circuit forcefully opened at last
    time:Utc lastForcedOpenTime?;
    # The discrete time buckets into which the time window is divided
    Bucket?[] totalBuckets = [];
|};

# Provides a set of configurations for controlling the behaviour of the Circuit Breaker.
public type CircuitBreakerConfig record {|
    # The `http:RollingWindow` options of the `CircuitBreaker`
    RollingWindow rollingWindow = {};
    # The threshold for request failures. When this threshold exceeds, the circuit trips. The threshold should be a
    # value between 0 and 1
    float failureThreshold = 0.0;
    # The time period (in seconds) to wait before attempting to make another request to the upstream service
    decimal resetTime = 0;
    # Array of HTTP response status codes which are considered as failures
    int[] statusCodes = [];
|};

# Represents a rolling window in the Circuit Breaker.
#
public type RollingWindow record {|
    # Minimum number of requests in a `RollingWindow` that will trip the circuit.
    int requestVolumeThreshold = 10;
    # Time period in seconds for which the failure threshold is calculated
    decimal timeWindow = 60;
    # The granularity at which the time window slides. This is measured in seconds.
    decimal bucketSize = 10;
|};

# Represents a discrete sub-part of the time window (Bucket).
#
# + totalCount - Total number of requests received during the sub-window time frame
# + failureCount - Number of failed requests during the sub-window time frame
# + rejectedCount - Number of rejected requests during the sub-window time frame
# + lastUpdatedTime - The time that the `Bucket` is last updated.
public type Bucket record {|
    int totalCount = 0;
    int failureCount = 0;
    int rejectedCount = 0;
    time:Utc lastUpdatedTime?;
|};

# Derived set of configurations from the `CircuitBreakerConfig`.
#
# + failureThreshold - The threshold for request failures. When this threshold exceeds, the circuit trips.
#                      The threshold should be a value between 0 and 1
# + resetTime - The time period (in seconds) to wait before attempting to make another request to
#               the upstream service
# + statusCodes - Array of HTTP response status codes which are considered as failures
# + noOfBuckets - Number of buckets derived from the `RollingWindow`
# + rollingWindow - The `http:RollingWindow` options provided in the `http:CircuitBreakerConfig`
public type CircuitBreakerInferredConfig record {|
    float failureThreshold = 0.0;
    decimal resetTime = 0;
    int[] statusCodes = [];
    int noOfBuckets = 0;
    RollingWindow rollingWindow = {};
|};

# A Circuit Breaker implementation which can be used to gracefully handle network failures.
#
# + url - The URL of the target service
# + circuitBreakerInferredConfig - Configurations derived from `CircuitBreakerConfig`
# + httpClient - The underlying `HttpActions` instance which will be making the actual network calls
# + circuitHealth - The circuit health monitor
# + currentCircuitState - The current state the circuit is in
client isolated class CircuitBreakerClient {

    private string url;
    private final CircuitBreakerInferredConfig & readonly circuitBreakerInferredConfig;
    private final CircuitHealth circuitHealth;
    private CircuitState currentCircuitState = CB_CLOSED_STATE;
    final HttpClient httpClient;

    # A Circuit Breaker implementation which can be used to gracefully handle network failures.
    #
    # + url - The URL of the target service
    # + config - The configurations of the client endpoint associated with this `CircuitBreaker` instance
    # + circuitBreakerInferredConfig - Configurations derived from the `http:CircuitBreakerConfig`
    # + httpClient - The underlying `HttpActions` instance, which will be making the actual network calls
    # + circuitHealth - The circuit health monitor
    # + return - The `client` or an `http:ClientError` if the initialization failed
    isolated function init(string url, ClientConfiguration config, CircuitBreakerInferredConfig
        circuitBreakerInferredConfig, HttpClient httpClient, CircuitHealth circuitHealth) returns ClientError? {
        RollingWindow rollingWindow = circuitBreakerInferredConfig.rollingWindow;
        if rollingWindow.timeWindow < rollingWindow.bucketSize {
            return error GenericClientError("Circuit breaker 'timeWindow' value should be greater" +
                " than the 'bucketSize' value.");
        }
        self.url = url;
        self.circuitBreakerInferredConfig = circuitBreakerInferredConfig.cloneReadOnly();
        self.httpClient = httpClient;
        self.circuitHealth = circuitHealth.clone();
        return;
    }

    # The POST remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.post()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function post(string path, RequestMessage message) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->post(path, <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The HEAD remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.head()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, RequestMessage message = ()) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->head(path, message = <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The PUT remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.put()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function put(string path, RequestMessage message) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->put(path, <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # This wraps the `CircuitBreakerClient.post()` function of the underlying HTTP remote functions provider.
    # The `CircuitBreakerClient.execute()` function can be used to invoke an HTTP call with the given HTTP verb.
    #
    # + httpVerb - HTTP verb to be used for the request
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function execute(string httpVerb, string path, RequestMessage message) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->execute(httpVerb, path, <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The PATCH remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.patch()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function patch(string path, RequestMessage message) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->patch(path, <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The DELETE remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.delete()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function delete(string path, RequestMessage message = ()) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->delete(path, <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The GET remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.get()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function get(string path, RequestMessage message = ()) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->get(path, message = <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # The OPTIONS remote function implementation of the Circuit Breaker. This wraps the `CircuitBreakerClient.options()`
    # function of the underlying HTTP remote functions provider.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function options(string path, RequestMessage message = ()) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->options(path, message = <Request>message);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # This wraps the `CircuitBreakerClient.forward()` function of the underlying HTTP remote functions provider.
    # The Forward remote function can be used to forward an incoming request to an upstream service as it is.
    #
    # + path - Resource path
    # + request - A Request struct
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function forward(string path, Request request) returns Response|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceResponse = self.httpClient->forward(path, request);
            return self.updateCircuitHealthAndRespond(serviceResponse);
        }
    }

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `CircuitBreakerClient.submit()` function does not give out a `Response` as the result.
    # Rather it returns an `http:HttpFuture` which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission
    #            fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        self.setCurrentState(self.updateCircuitState());
        if self.getCurrentState() == CB_OPEN_STATE {
            // TODO: Allow the user to handle this scenario. Maybe through a user provided function
            return self.handleOpenCircuit();
        } else {
            var serviceFuture = self.httpClient->submit(httpVerb, path, <Request>message);
            if serviceFuture is HttpFuture {
                var serviceResponse = self.httpClient->getResponse(serviceFuture);
                Response|ClientError result = self.updateCircuitHealthAndRespond(serviceResponse);
                if result is error {
                    log:printDebug("Error receiving response for circuit breaker submit operation: " + result.message());
                }
            } else {
                self.updateCircuitHealthFailure();
            }
            return serviceFuture;
        }
    }

    # Retrieves the `http:Response` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        // No need to check for the response as we already check for the response in the submit method
        return self.httpClient->getResponse(httpFuture);
    }

    # Circuit breaking is not supported. The default value is the `CircuitBreakerClient.hasPromise()` function of the underlying
    # HTTP remote functions provider.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Retrieves the next available `http:PushPromise` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Retrieves the promised server push `Response` message.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return self.httpClient->getPromisedResponse(promise);
    }

    # Circuit breaking is not supported. The default value is the `CircuitBreakerClient.rejectPromise()` function of the underlying
    # HTTP remote functions provider.
    #
    # + promise - The `http:PushPromise` to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }

    # Force the circuit into a closed state in which it will allow requests regardless of the error percentage
    # until the failure threshold exceeds.
    isolated function forceClose() {
        log:printInfo("Circuit forcefully switched to CLOSE state.");
        self.setCurrentState(CB_CLOSED_STATE);
        lock {
            self.reInitializeBuckets(self.circuitHealth);
        }
    }

    # Force the circuit into a open state in which it will suspend all requests
    # until `resetTime` interval exceeds.
    isolated function forceOpen() {
        lock {
            self.currentCircuitState = CB_OPEN_STATE;
            self.circuitHealth.lastForcedOpenTime = time:utcNow();
        }
    }

    # Provides the `http:CircuitState` of the circuit breaker.
    #
    # + return - The current `http:CircuitState` of the circuit breaker
    isolated function getCurrentState() returns CircuitState {
        lock {
            return self.currentCircuitState;
        }
    }

    # Updates the circuit state.
    #
    # + return - State of the circuit
    isolated function updateCircuitState() returns CircuitState {
        lock {
            CircuitState currentState = self.currentCircuitState;
            self.prepareRollingWindow(self.circuitHealth, self.circuitBreakerInferredConfig);
            int currentBucketId = self.getCurrentBucketId(self.circuitHealth);
            self.updateLastUsedBucketId(self.circuitHealth, currentBucketId);
            self.circuitHealth.lastRequestTime = time:utcNow();
            int totalRequestsCount = self.getTotalRequestsCount(self.circuitHealth);
            self.circuitHealth.totalRequestCount = totalRequestsCount;
            if totalRequestsCount >= self.circuitBreakerInferredConfig.rollingWindow.requestVolumeThreshold {
                if currentState == CB_OPEN_STATE {
                    currentState = self.switchCircuitStateOpenToHalfOpenOnResetTime(self.circuitBreakerInferredConfig,
                                                                                    self.circuitHealth, currentState);
                } else if currentState == CB_HALF_OPEN_STATE {
                    if !self.circuitHealth.lastRequestSuccess {
                        // If the trial run has failed, trip the circuit again
                        currentState = CB_OPEN_STATE;
                        log:printInfo("CircuitBreaker trial run has failed. Circuit switched from HALF_OPEN to OPEN state.")
                        ;
                    } else {
                        // If the trial run was successful reset the circuit
                        currentState = CB_CLOSED_STATE;
                        log:printInfo(
                            "CircuitBreaker trial run  was successful. Circuit switched from HALF_OPEN to CLOSE state.");
                    }
                } else {
                    float currentFailureRate = self.getCurrentFailureRatio(self.circuitHealth);

                    if currentFailureRate > self.circuitBreakerInferredConfig.failureThreshold {
                        currentState = CB_OPEN_STATE;
                        log:printInfo("CircuitBreaker failure threshold exceeded. Circuit tripped from CLOSE to OPEN state."
                        );
                    }
                }
            } else {
                currentState = self.switchCircuitStateOpenToHalfOpenOnResetTime(self.circuitBreakerInferredConfig,
                                                                                self.circuitHealth, currentState);
            }
            Bucket bucket = <Bucket> self.circuitHealth.totalBuckets[currentBucketId];
            bucket.totalCount += 1;
            return currentState;
        }
    }

    // Handles open circuit state.
    isolated function handleOpenCircuit() returns ClientError {
        time:Utc effectiveErrorTime = self.getEffectiveErrorTime();
        time:Seconds timeDif = time:utcDiffSeconds(time:utcNow(), effectiveErrorTime);
        int timeRemaining = <int> (self.circuitBreakerInferredConfig.resetTime - <decimal> timeDif);
        self.updateRejectedRequestCount();
        string errorMessage = "Upstream service unavailable. Requests to upstream service will be suspended for "
            + timeRemaining.toString() + " seconds.";
        return error UpstreamServiceUnavailableError(errorMessage);
    }

    isolated function updateCircuitHealthAndRespond(Response|ClientError serviceResponse) returns Response|ClientError {
        if serviceResponse is Response {
            if self.circuitBreakerInferredConfig.statusCodes.indexOf(serviceResponse.statusCode) is int {
                self.updateCircuitHealthFailure();
            } else {
                self.updateCircuitHealthSuccess();
            }
            return serviceResponse;
        } else {
            self.updateCircuitHealthFailure();
            return serviceResponse;
        }
    }

    isolated function updateCircuitHealthFailure() {
        lock {
            int currentBucketId = self.getCurrentBucketId(self.circuitHealth);
            self.circuitHealth.lastRequestSuccess = false;
            self.updateLastUsedBucketId(self.circuitHealth, currentBucketId);
            Bucket bucket = <Bucket> self.circuitHealth.totalBuckets[currentBucketId];
            bucket.failureCount += 1;
            time:Utc lastUpdated = time:utcNow();
            self.circuitHealth.lastErrorTime = lastUpdated;
            Bucket?[] buckets = self.circuitHealth.totalBuckets;
            if buckets is Bucket[] {
                //TODO:Get this verified
                time:Utc? lastUpdatedTime = buckets[currentBucketId]?.lastUpdatedTime;
                if lastUpdatedTime is time:Utc {
                    lastUpdatedTime = lastUpdated;
                }
            }
        }
    }

    isolated function updateCircuitHealthSuccess() {
        lock {
            int currentBucketId = self.getCurrentBucketId(self.circuitHealth);
            time:Utc lastUpdated = time:utcNow();
            self.updateLastUsedBucketId(self.circuitHealth, currentBucketId);
            self.circuitHealth.lastRequestSuccess = true;
            Bucket?[] buckets = self.circuitHealth.totalBuckets;
            if buckets is Bucket[] {
                //TODO:Get this verified
                time:Utc? lastUpdatedTime = buckets[currentBucketId]?.lastUpdatedTime;
                if lastUpdatedTime is time:Utc {
                    lastUpdatedTime = lastUpdated;
                }
            }
        }
    }

    # Calculates a failure at a given point.
    #
    # + circuitHealth - Circuit Breaker health status
    # + return - Current failure ratio
    isolated function getCurrentFailureRatio(CircuitHealth circuitHealth) returns float {
        int totalCount = 0;
        int totalFailures = 0;

        foreach var optBucket in circuitHealth.totalBuckets {
            var bucket = <Bucket>optBucket;
            totalCount =  totalCount + bucket.failureCount +
                                            (bucket.totalCount - (bucket.failureCount + bucket.rejectedCount));
            totalFailures = totalFailures + bucket.failureCount;
        }
        float ratio = 0.0;
        if totalCount > 0 {
            ratio = <float> totalFailures / <float> totalCount;
        }
        return ratio;
    }

    # Calculates the total requests count within a `RollingWindow`.
    #
    # + circuitHealth - Circuit Breaker health status
    # + return - Total requests count
    isolated function getTotalRequestsCount(CircuitHealth circuitHealth) returns int {
        int totalCount = 0;
        foreach var bucket in circuitHealth.totalBuckets {
            Bucket temp = <Bucket>bucket;
            totalCount  =  totalCount + temp.totalCount;
        }
        return totalCount;
    }

    # Calculates the current bucket ID.
    #
    # + circuitHealth - Circuit Breaker health status
    # + return - Current bucket id
    isolated function getCurrentBucketId(CircuitHealth circuitHealth) returns int {
        decimal elapsedTime = time:utcDiffSeconds(time:utcNow(), circuitHealth.startTime) %
            (self.circuitBreakerInferredConfig.rollingWindow.timeWindow);
        int currentBucketId = <int> (((elapsedTime / self.circuitBreakerInferredConfig.rollingWindow.bucketSize) + 1d)
            % <decimal> self.circuitBreakerInferredConfig.noOfBuckets);
        return currentBucketId;
    }

    # Updates the rejected requests count.
    isolated function updateRejectedRequestCount() {
        lock {
            int currentBucketId = self.getCurrentBucketId(self.circuitHealth);
            self.updateLastUsedBucketId(self.circuitHealth, currentBucketId);
            Bucket bucket = <Bucket>self.circuitHealth.totalBuckets[currentBucketId];
            bucket.rejectedCount += 1;
        }
    }

    # Resets the bucket values to the default ones.
    #
    # + circuitHealth - Circuit Breaker health status
    # + bucketId - - Id of the bucket should reset.
    isolated function resetBucketStats(CircuitHealth circuitHealth, int bucketId) {
        circuitHealth.totalBuckets[bucketId] = {};
    }

    isolated function getEffectiveErrorTime() returns time:Utc {
        time:Utc? lastErrorTime;
        time:Utc? lastForcedOpenTime;
        lock {
            lastErrorTime = self.circuitHealth?.lastErrorTime;
            lastForcedOpenTime = self.circuitHealth?.lastForcedOpenTime;
        }
        if lastErrorTime is time:Utc && lastForcedOpenTime is time:Utc {
            return (time:utcDiffSeconds(lastErrorTime, lastForcedOpenTime) > 0d) ? lastErrorTime : lastForcedOpenTime;
        }
        //TODO:What to send?
        return time:utcNow();
    }

    # Populates the `RollingWindow` statistics to handle circuit breaking within the `RollingWindow` time frame.
    #
    # + circuitHealth - Circuit Breaker health status
    # + circuitBreakerInferredConfig - Configurations derived from `CircuitBreakerConfig`
    isolated function prepareRollingWindow(CircuitHealth circuitHealth, CircuitBreakerInferredConfig circuitBreakerInferredConfig) {

        time:Utc currentTime = time:utcNow();
        time:Utc? lastRequestTime = circuitHealth?.lastRequestTime;
        //TODO:Get this logic verified
        decimal idleTime = 0;
        if lastRequestTime is time:Utc {
            idleTime = time:utcDiffSeconds(currentTime, lastRequestTime);
        }
        RollingWindow rollingWindow = circuitBreakerInferredConfig.rollingWindow;
        // If the time duration between two requests greater than timeWindow values, reset the buckets to default.
        if idleTime > rollingWindow.timeWindow {
            self.reInitializeBuckets(circuitHealth);
        } else {
            int currentBucketId = self.getCurrentBucketId(circuitHealth);
            int lastUsedBucketId = circuitHealth.lastUsedBucketId;
            // Check whether subsequent requests received within same bucket(sub time window). If the idle time is greater
            // than bucketSize means subsequent calls are received time exceeding the rolling window. if we need to
            // reset the buckets to default.
            if currentBucketId == circuitHealth.lastUsedBucketId && idleTime > rollingWindow.bucketSize {
                self.reInitializeBuckets(circuitHealth);
            // If the current bucket (sub time window) is less than last updated bucket. Stats of the current bucket to
            // zeroth bucket and Last bucket to last used bucket needs to be reset to default.
            } else if currentBucketId < lastUsedBucketId {
                int index = currentBucketId;
                while (index >= 0) {
                    self.resetBucketStats(circuitHealth, index);
                    index -= 1;
                }
                int lastIndex = (circuitHealth.totalBuckets.length()) - 1;
                while (lastIndex > lastUsedBucketId) {
                    self.resetBucketStats(circuitHealth, lastIndex);
                    lastIndex -= 1;
                }
            } else {
                // If the current bucket (sub time window) is greater than last updated bucket. Stats of current bucket to
                // last used bucket needs to be reset without resetting last used bucket stat.
                while (currentBucketId > lastUsedBucketId && idleTime > rollingWindow.bucketSize) {
                    self.resetBucketStats(circuitHealth, currentBucketId);
                    currentBucketId -= 1;
                }
            }
        }
    }

    # Reinitializes the Buckets to the default state.
    #
    # + circuitHealth - Circuit Breaker health status
    isolated function reInitializeBuckets(CircuitHealth circuitHealth) {
        Bucket?[] bucketArray = [];
        int bucketIndex = 0;
        while (bucketIndex < circuitHealth.totalBuckets.length()) {
            bucketArray[bucketIndex] = {};
            bucketIndex += 1;
        }
        circuitHealth.totalBuckets = bucketArray;
    }

    # Updates the `lastUsedBucketId` in `CircuitHealth`.
    #
    # + circuitHealth - Circuit Breaker health status
    # + bucketId - Position of the currently used bucket
    isolated function updateLastUsedBucketId(CircuitHealth circuitHealth, int bucketId) {
        if bucketId != circuitHealth.lastUsedBucketId {
            self.resetBucketStats(circuitHealth, bucketId);
            circuitHealth.lastUsedBucketId = bucketId;
        }
    }

    # Switches circuit state from open to half open state when reset time exceeded.
    #
    # + circuitBreakerInferredConfig -  Configurations derived from `CircuitBreakerConfig`
    # + circuitHealth - Circuit Breaker health status
    # + currentState - current state of the circuit
    # + return - Calculated state value of the circuit
    isolated function switchCircuitStateOpenToHalfOpenOnResetTime(CircuitBreakerInferredConfig circuitBreakerInferredConfig,
                                            CircuitHealth circuitHealth, CircuitState currentState) returns CircuitState {
        CircuitState currentCircuitState = currentState;
        if currentState == CB_OPEN_STATE {
            time:Utc effectiveErrorTime = self.getEffectiveErrorTime();
            time:Seconds elapsedTime = time:utcDiffSeconds(time:utcNow(), effectiveErrorTime);
            if elapsedTime > circuitBreakerInferredConfig.resetTime {
                currentCircuitState = CB_HALF_OPEN_STATE;
                log:printInfo("CircuitBreaker reset timeout reached. Circuit switched from OPEN to HALF_OPEN state.");
            }
        }
        return currentCircuitState;
    }

    isolated function setCurrentState(CircuitState currentCircuitState) {
        lock {
            self.currentCircuitState = currentCircuitState;
        }
    }
}

// Validates the struct configurations passed to create circuit breaker.
isolated function validateCircuitBreakerConfiguration(CircuitBreakerConfig circuitBreakerConfig) {
    float failureThreshold = circuitBreakerConfig.failureThreshold;
    if failureThreshold < 0f || failureThreshold > 1f {
        string errorMessage = "Invalid failure threshold. Failure threshold value"
            + " should between 0 to 1, found " + failureThreshold.toString();
        panic error CircuitBreakerConfigError(errorMessage);
    }
}
