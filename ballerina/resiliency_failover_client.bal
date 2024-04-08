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
import ballerina/lang.runtime as runtime;
import ballerina/mime;
import ballerina/log;

# Represents the inferred failover configurations passed into the failover client.
type FailoverInferredConfig record {|
    # An array of HTTP response status codes for which the failover mechanism triggers
    int[] failoverCodes = [];
    # Failover delay interval in seconds
    decimal failoverInterval = 0;
|};

# An HTTP client endpoint which provides failover support over multiple HTTP clients.
#
# + succeededEndpointIndex - Index of the `CallerActions[]` array which given a successful response
# + failoverInferredConfig - Configurations derived from `FailoverConfig`
# + failoverClientsArray - Array of `Client` for target endpoints
# + requireValidation - Enables the inbound payload validation functionalty which provided by the constraint package
public client isolated class FailoverClient {
    *ClientObject;

    private int succeededEndpointIndex;
    private final FailoverInferredConfig & readonly failoverInferredConfig;
    private final Client?[] failoverClientsArray;
    private final boolean requireValidation;

    # Failover caller actions which provides failover capabilities to an HTTP client endpoint.
    #
    # + failoverClientConfig - The configurations of the client endpoint associated with this `Failover` instance
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public isolated function init(*FailoverClientConfiguration failoverClientConfig) returns ClientError? {
        self.succeededEndpointIndex = 0;
        self.failoverClientsArray = [];
        Client clientEp;
        int i = 0;
        foreach var target in failoverClientConfig.targets {
            ClientConfiguration epConfig = createClientEPConfigFromFailoverEPConfig(failoverClientConfig, target);
            clientEp = check new(target.url, epConfig);
            lock {
                self.failoverClientsArray[i] = clientEp;
            }
            i += 1;
        }
        FailoverInferredConfig failoverInferredConfig = {
            failoverCodes:failoverClientConfig.failoverCodes,
            failoverInterval:failoverClientConfig.interval
        };
        self.failoverInferredConfig = failoverInferredConfig.cloneReadOnly();
        self.requireValidation = failoverClientConfig.validation;
        return;
    }

    # The POST resource function implementation of the Failover Connector.
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

    # The POST remote function implementation of the Failover Connector.
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
            string? mediaType, map<string|string[]>? headers) returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performFailoverAction(path, req, HTTP_POST);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The PUT resource function implementation of the Failover Connector.
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

    # The PUT remote function  implementation of the Failover Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
    
    private isolated function processPut(string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performFailoverAction(path, req, HTTP_PUT);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The PATCH resource function implementation of the Failover Connector.
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

    # The PATCH remote function implementation of the Failover Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
    
    private isolated function processPatch(string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performFailoverAction(path, req, HTTP_PATCH);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The DELETE resource function implementation of the Failover Connector.
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

    # The DELETE remote function implementation of the Failover Connector.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
    
    private isolated function processDelete(string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performFailoverAction(path, req, HTTP_DELETE);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The HEAD resource function implementation of the Failover Connector.
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

    # The HEAD remote function implementation of the Failover Connector.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = self.performFailoverAction(path, req, HTTP_HEAD);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is Response || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The GET resource function implementation of the Failover Connector.
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

    # The GET remote function implementation of the Failover Connector.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
        
    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = self.performFailoverAction(path, req, HTTP_GET);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # The OPTIONS resource function implementation of the Failover Connector.
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

    # The OPTIONS remote function implementation of the Failover Connector.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
    
    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = self.performFailoverAction(path, req, HTTP_OPTIONS);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Invokes an HTTP call with the specified HTTP method.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
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
            returns Response|StatusCodeResponse|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performExecuteAction(path, req, httpVerb);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Invokes an HTTP call using the incoming request's HTTP method.
    #
    # + path - Resource path
    # + request - An HTTP request
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;
    
    private isolated function processForward(string path, Request request, TargetType targetType)
            returns Response|StatusCodeResponse|anydata|ClientError {
        var result = self.performFailoverAction(path, request, HTTP_FORWARD);
        if result is HttpFuture {
            return getInvalidTypeError();
        } else if result is ClientError|Response {
            return processResponse(result, targetType, self.requireValidation);
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Submits an HTTP request to a service with the specified HTTP verb. The `FailoverClient.submit()` function does not
    # return an `http:Response` as the result. Rather it returns an `http:HttpFuture` which can be used for subsequent interactions
    # with the HTTP endpoint.
    #
    # + httpVerb - The HTTP verb value
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission
    #            fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = check buildRequest(message, ());
        var result = self.performExecuteAction(path, req, "SUBMIT", verb = httpVerb);
        if result is Response {
            return getInvalidTypeError();
        } else if result is HttpFuture || result is ClientError {
            return result;
        } else {
            panic error ClientError("invalid response type received");
        }
    }

    # Retrieves the `http:Response` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        Client foClient = self.getLastSuceededClientEP();
        return foClient->getResponse(httpFuture);
    }

    # Checks whether an `http:PushPromise` exists for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return false;
    }

    # Retrieves the next available `http:PushPromise` for a previously-submitted request.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return error UnsupportedActionError("Failover client not supported for getNextPromise action");
    }

    # Retrieves the promised server push `http:Response` message.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return error UnsupportedActionError("Failover client not supported for getPromisedResponse action");
    }

    # Rejects an `http:PushPromise`. When an `http:PushPromise` is rejected, there is no chance of fetching a promised
    # response using the rejected promise.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
    }

    # Gets the index of the `TargetService[]` array which given a successful response.
    #
    # + return - The successful target endpoint index
    public isolated function getSucceededEndpointIndex() returns int {
        lock {
            return self.succeededEndpointIndex;
        }
    }

    isolated function setSucceededEndpointIndex(int succeededEndpointIndex) {
        lock {
            self.succeededEndpointIndex = succeededEndpointIndex;
        }
    }

    // Performs execute action of the Failover connector. extract the corresponding http integer value representation
    // of the http verb and invokes the perform action method.
    // `verb` is used for HTTP `submit()` method.
    isolated function performExecuteAction (string path, Request request, string httpVerb,
            string verb = "") returns HttpResponse|ClientError {
        HttpOperation connectorAction = extractHttpOperation(httpVerb);
        return self.performFailoverAction(path, request, connectorAction, verb = verb);
    }

    // Handles all the actions exposed through the Failover connector.
    isolated function performFailoverAction (string path, Request request, HttpOperation requestAction,
            string verb = "") returns HttpResponse|ClientError {

        Client foClient = self.getLastSuceededClientEP();
        FailoverInferredConfig failoverInferredConfig = self.failoverInferredConfig;
        int[] failoverCodes = failoverInferredConfig.failoverCodes;
        int noOfEndpoints = 0;
        lock {
            noOfEndpoints = self.failoverClientsArray.length();
        }
        // currentIndex and initialIndex are need to set to last succeeded endpoint index to start failover with
        // the endpoint which gave the expected results.
        int currentIndex = self.getSucceededEndpointIndex();
        int initialIndex = self.getSucceededEndpointIndex();
        int startIndex = -1;
        decimal failoverInterval = failoverInferredConfig.failoverInterval;

        Response inResponse = new;
        HttpFuture inFuture = new;
        Request failoverRequest = request;
        ClientError?[] failoverActionErrData = [];
        mime:Entity requestEntity = new;

        if isMultipartRequest(failoverRequest) {
            failoverRequest = check populateMultipartRequest(failoverRequest);
        } else {
            // When performing passthrough scenarios using Failover connector, message needs to be built before trying
            // out the failover endpoints to keep the request message to failover the messages.
            if !failoverRequest.hasMsgDataSource() {
                byte[]|error binaryPayload = failoverRequest.getBinaryPayload();
                if binaryPayload is error {
                    log:printDebug("Error building payload for request failover: " + binaryPayload.message());
                }
            }
            requestEntity = check failoverRequest.getEntity();
        }
        while (startIndex != currentIndex) {
            startIndex = initialIndex;
            currentIndex = currentIndex + 1;
            var endpointResponse = invokeEndpoint(path, failoverRequest, requestAction, foClient.httpClient, verb = verb);
            if endpointResponse is Response {
                inResponse = endpointResponse;
                int httpStatusCode = endpointResponse.statusCode;
                // Check whether HTTP status code of the response falls into configured `failoverCodes`
                if failoverCodes.indexOf(httpStatusCode) is int {
                    ClientError? result = ();
                    [currentIndex, result] = handleResponseWithErrorCode(endpointResponse, initialIndex, noOfEndpoints,
                                                                                    currentIndex, failoverActionErrData);
                    if result is ClientError {
                        return result;
                    }
                } else {
                    // If the execution reaches here, that means the first endpoint configured in the failover endpoints
                    // gives the expected response.
                    self.setSucceededEndpointIndex(currentIndex - 1);
                    break;
                }
            } else if endpointResponse is HttpFuture {
                // Response came from the `submit()` method.
                inFuture = endpointResponse;
                var futureResponse = foClient->getResponse(endpointResponse);
                if futureResponse is Response {
                    inResponse = futureResponse;
                    int httpStatusCode = futureResponse.statusCode;
                    // Check whether HTTP status code of the response falls into configured `failoverCodes`
                    if failoverCodes.indexOf(httpStatusCode) is int {
                        ClientError? result = ();
                        [currentIndex, result] = handleResponseWithErrorCode(futureResponse, initialIndex, noOfEndpoints,
                                                                                    currentIndex, failoverActionErrData);
                        if result is ClientError {
                            return result;
                        }
                    } else {
                        // If the execution reaches here, that means the first endpoint configured in the failover endpoints
                        // gives the expected response.
                        self.setSucceededEndpointIndex(currentIndex - 1);
                        break;
                    }
                } else {
                    ClientError? httpConnectorErr = ();
                    [currentIndex, httpConnectorErr] = handleError(futureResponse, initialIndex, noOfEndpoints,
                                                                                    currentIndex, failoverActionErrData);

                    if httpConnectorErr is ClientError {
                        return httpConnectorErr;
                    }
                }
            } else if endpointResponse is ClientError {
                ClientError? httpConnectorErr = ();
                [currentIndex, httpConnectorErr] = handleError(endpointResponse, initialIndex, noOfEndpoints,
                                                                                    currentIndex, failoverActionErrData);

                if httpConnectorErr is ClientError {
                    return httpConnectorErr;
                }
            } else {
                panic error ClientError("invalid response type received");
            }
            failoverRequest = check createFailoverRequest(failoverRequest, requestEntity);
            runtime:sleep(failoverInterval);

            Client? tmpClnt;
            lock {
                tmpClnt = self.failoverClientsArray[currentIndex];
            }
            if tmpClnt is Client {
                foClient = tmpClnt;
            } else {
                error err = error("Unexpected type found for failover client.");
                panic err;
            }
        }
        if HTTP_SUBMIT == requestAction {
            return inFuture;
        }
        return inResponse;
    }

    isolated function getLastSuceededClientEP() returns Client {
        Client? lastSuccessClient;
        lock {
            lastSuccessClient = self.failoverClientsArray[self.succeededEndpointIndex];
        }
        if lastSuccessClient is Client {
            // We don't have to check this again as we already check for the response when we get the future.
            return lastSuccessClient;
        } else {
            // This should not happen as we only fill Client objects to the Clients array
            error err = error("Unexpected type found for failover client");
            panic err;
        }
    }
}

// Populates an error specific to the Failover connector by including all the errors returned from endpoints.
isolated function populateGenericFailoverActionError (ClientError?[] failoverActionErr, ClientError httpActionErr, int index)
                                                                            returns FailoverAllEndpointsFailedError {

    failoverActionErr[index] = httpActionErr;
    error err = httpActionErr;
    string lastErrorMsg = err.message();
    string failoverMessage = "All the failover endpoints failed. Last error was: " + lastErrorMsg;
    return error FailoverAllEndpointsFailedError(failoverMessage, failoverErrors = failoverActionErr);
}

// If leaf endpoint returns a response with status code configured to retry in the failover connector, failover error
// will be generated with last response status code and generic failover response.
isolated function populateFailoverErrorHttpStatusCodes (Response inResponse, ClientError?[] failoverActionErr, int index) {
    string failoverMessage = "Endpoint " + index.toString() + " returned response is: " +
                                inResponse.statusCode.toString() + " " + inResponse.reasonPhrase;
    FailoverActionFailedError httpActionErr = error FailoverActionFailedError(failoverMessage);
    failoverActionErr[index] = httpActionErr;
}

isolated function populateErrorsFromLastResponse (Response inResponse, ClientError?[] failoverActionErr, int index)
                                                                            returns (ClientError) {
    string message = "Last endpoint returned response: " + inResponse.statusCode.toString() + " " +
                        inResponse.reasonPhrase;
    FailoverActionFailedError lastHttpConnectorErr = error FailoverActionFailedError(message);
    failoverActionErr[index] = lastHttpConnectorErr;
    string failoverMessage = "All the failover endpoints failed. Last endpoint returned response is: "
                                + inResponse.statusCode.toString() + " " + inResponse.reasonPhrase;
    return error FailoverAllEndpointsFailedError(failoverMessage, failoverErrors = failoverActionErr);
}

# Provides a set of HTTP related configurations and failover related configurations.
# The following fields are inherited from the other configuration records in addition to the failover client-specific
# configs.
public type FailoverClientConfiguration record {|
    *CommonClientConfiguration;
    # The upstream HTTP endpoints among which the incoming HTTP traffic load should be sent on failover
    TargetService[] targets = [];
    # Array of HTTP response status codes for which the failover behaviour should be triggered
    int[] failoverCodes = [501, 502, 503, 504];
    # Failover delay interval in seconds
    decimal interval = 0;
|};

isolated function createClientEPConfigFromFailoverEPConfig(FailoverClientConfiguration foConfig,
                                                  TargetService target) returns ClientConfiguration {
    ClientConfiguration clientEPConfig = {
        http1Settings: foConfig.http1Settings,
        http2Settings: foConfig.http2Settings,
        circuitBreaker:foConfig.circuitBreaker,
        timeout:foConfig.timeout,
        httpVersion:foConfig.httpVersion,
        forwarded:foConfig.forwarded,
        followRedirects:foConfig.followRedirects,
        retryConfig:foConfig.retryConfig,
        poolConfig:foConfig.poolConfig,
        secureSocket:target.secureSocket,
        cache:foConfig.cache,
        compression:foConfig.compression,
        auth:foConfig.auth,
        cookieConfig:foConfig.cookieConfig,
        responseLimits:foConfig.responseLimits,
        validation:foConfig.validation,
        socketConfig:foConfig.socketConfig
    };
    return clientEPConfig;
}

isolated function handleResponseWithErrorCode(Response response, int initialIndex, int noOfEndpoints, int index,
                                                        ClientError?[] failoverActionErrData) returns [int, ClientError?] {

    ClientError? resultError = ();
    int currentIndex = index;
    // If the initialIndex == DEFAULT_FAILOVER_EP_STARTING_INDEX check successful, that means the first
    // endpoint configured in the failover endpoints gave the response where its HTTP status code
    // falls into configured `failoverCodes`
    if initialIndex == DEFAULT_FAILOVER_EP_STARTING_INDEX {
        if noOfEndpoints > currentIndex {
            // If the execution lands here, that means there are endpoints that haven't tried out by
            // failover endpoint. Hence response will be collected to generate final response.
            populateFailoverErrorHttpStatusCodes(response, failoverActionErrData, currentIndex - 1);
        } else {
            // If the execution lands here, that means all the endpoints has been tried out and final
            // endpoint gave the response where its HTTP status code falls into configured
            // `failoverCodes`. Therefore appropriate error message needs to be generated and should
            // return it to the client.
            resultError = populateErrorsFromLastResponse(response, failoverActionErrData, currentIndex - 1);
        }
    } else {
        // If execution reaches here, that means failover has not started with the default starting index.
        // Failover resumed from the last succeeded endpoint.
        if initialIndex == currentIndex {
            // If the execution lands here, that means all the endpoints has been tried out and final
            // endpoint gives the response where its HTTP status code falls into configured
            // `failoverCodes`. Therefore appropriate error message needs to be generated and should
            // return it to the client.
            resultError = populateErrorsFromLastResponse(response, failoverActionErrData, currentIndex - 1);
        } else if noOfEndpoints == currentIndex {
            // If the execution lands here, that means the last endpoint has been tried out and
            // endpoint gave a response where its HTTP status code falls into configured
            // `failoverCodes`. Since failover resumed from the last succeeded endpoint we need try out
            // remaining endpoints. Therefore currentIndex need to be reset.
            populateFailoverErrorHttpStatusCodes(response, failoverActionErrData, currentIndex - 1);
            currentIndex = DEFAULT_FAILOVER_EP_STARTING_INDEX;
        } else if noOfEndpoints > currentIndex {
            // Collect the response to generate final response.
            populateFailoverErrorHttpStatusCodes(response, failoverActionErrData, currentIndex - 1);
        }
    }
    return [currentIndex, resultError];
}

isolated function handleError(ClientError err, int initialIndex, int noOfEndpoints, int index, ClientError?[] failoverActionErrData)
                                                                                        returns [int, ClientError?] {
    ClientError? httpConnectorErr = ();

    int currentIndex = index;
    // If the initialIndex == DEFAULT_FAILOVER_EP_STARTING_INDEX check successful, that means the first
    // endpoint configured in the failover endpoints gave the erroneous response.
    if initialIndex == DEFAULT_FAILOVER_EP_STARTING_INDEX {
        if noOfEndpoints > currentIndex {
            // If the execution lands here, that means there are endpoints that haven't tried out by
            // failover endpoint. Hence error will be collected to generate final response.
            failoverActionErrData[currentIndex - 1] = err;
        } else {
            // If the execution lands here, that means all the endpoints has been tried out and final
            // endpoint gave an erroneous response. Therefore appropriate error message needs to be
            //  generated and should return it to the client.
            httpConnectorErr = populateGenericFailoverActionError(failoverActionErrData, err, currentIndex - 1);
        }
    } else {
        // If execution reaches here, that means failover has not started with the default starting index.
        // Failover resumed from the last succeeded endpoint.
        if initialIndex == currentIndex {
            // If the execution lands here, that means all the endpoints has been tried out and final
            // endpoint gave an erroneous response. Therefore appropriate error message needs to be
            //  generated and should return it to the client.
            httpConnectorErr = populateGenericFailoverActionError(failoverActionErrData, err, currentIndex - 1);
        } else if noOfEndpoints == currentIndex {
            // If the execution lands here, that means the last endpoint has been tried out and endpoint gave
            // a erroneous response. Since failover resumed from the last succeeded endpoint we need try out
            // remaining endpoints. Therefore currentIndex need to be reset.
            failoverActionErrData[currentIndex - 1] = err;
            currentIndex = DEFAULT_FAILOVER_EP_STARTING_INDEX;
        } else if noOfEndpoints > currentIndex {
            // Collect the error to generate final response.
            failoverActionErrData[currentIndex - 1] = err;
        }
    }
    return [currentIndex, httpConnectorErr];
}
