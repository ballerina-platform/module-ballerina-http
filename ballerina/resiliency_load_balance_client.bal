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
import ballerina/log;

# LoadBalanceClient endpoint provides load balancing functionality over multiple HTTP clients.
#
# + loadBalanceClientsArray - Array of HTTP clients for load balancing
# + lbRule - Load balancing rule
# + failover - Whether to fail over in case of a failure
# + requireValidation - Enables the inbound payload validation functionalty which provided by the constraint package
# + requireLaxDataBinding - Enables or disalbles relaxed data binding.
public client isolated class LoadBalanceClient {
    *ClientObject;

    private final Client?[] loadBalanceClientsArray;
    private LoadBalancerRule lbRule;
    private final boolean failover;
    private final boolean requireValidation;
    private final boolean requireLaxDataBinding;

    # Load Balancer adds an additional layer to the HTTP client to make network interactions more resilient.
    #
    # + loadBalanceClientConfig - The configurations for the load balance client endpoint
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public isolated function init(*LoadBalanceClientConfiguration loadBalanceClientConfig) returns ClientError? {
        self.failover = loadBalanceClientConfig.failover;
        self.loadBalanceClientsArray = [];
        Client clientEp;
        int i = 0;
        foreach var target in loadBalanceClientConfig.targets {
            ClientConfiguration epConfig = createClientEPConfigFromLoalBalanceEPConfig(loadBalanceClientConfig, target);
            clientEp = check new(target.url , epConfig);
            lock {
                self.loadBalanceClientsArray[i] = clientEp;
            }
            i += 1;
        }
        var lbRule = loadBalanceClientConfig.lbRule;
        if lbRule is LoadBalancerRule {
            self.lbRule = lbRule;
        } else {
            LoadBalancerRoundRobinRule loadBalancerRoundRobinRule = new;
            self.lbRule = loadBalancerRoundRobinRule;
        }
        self.requireValidation = loadBalanceClientConfig.validation;
        self.requireLaxDataBinding = loadBalanceClientConfig.laxDataBinding;
        return;
    }

    # The POST resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function post [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (),TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "postResource"
    } external;

    # The POST remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
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
        populateOptions(req, mediaType, headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_POST);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The PUT resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function put [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "putResource"
    } external;

    # The PUT remote function implementation of the Load Balance Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
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
        populateOptions(req, mediaType, headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_PUT);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The PATCH resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function patch [PathParamType ...path](RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (),TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "patchResource"
    } external;

    # The PATCH remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
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
        populateOptions(req, mediaType, headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_PATCH);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The DELETE resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function delete [PathParamType ...path](RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>, *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "deleteResource"
    } external;

    # The DELETE remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processDelete(string path, RequestMessage message, TargetType targetType,
            string? mediaType, map<string|string[]>? headers) returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = check buildRequest(message, mediaType);
        populateOptions(req, mediaType, headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_DELETE);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The HEAD resource function implementation of the LoadBalancer Connector.
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

    # The HEAD remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        return self.performLoadBalanceAction(path, req, HTTP_HEAD);
    }

    # The GET resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function get [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "getResource"
    } external;

    # The GET remote function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_GET);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The OPTIONS resource function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    isolated resource function options [PathParamType ...path](map<string|string[]>? headers = (), TargetType targetType = <>,
            *QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
        name: "optionsResource"
    } external;

    # The OPTIONS remote function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = self.performLoadBalanceAction(path, req, HTTP_OPTIONS);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The EXECUTE remote function implementation of the LoadBalancer Connector.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
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
        populateOptions(req, mediaType, headers);
        var result = self.performLoadBalanceExecuteAction(path, req, httpVerb);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The FORWARD remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + request - An HTTP request
    # + targetType - HTTP response, `anydata` or stream of HTTP SSE, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(string path, Request request, TargetType targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, TargetType targetType)
            returns Response|stream<SseEvent, error?>|anydata|ClientError {
        var result = self.performLoadBalanceAction(path, request, HTTP_FORWARD);
        return processResponse(result, targetType, self.requireValidation, self.requireLaxDataBinding);
    }

    # The submit implementation of the LoadBalancer Connector.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission
    #            fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        return error UnsupportedActionError("Load balancer client not supported for submit action");
    }

    # The getResponse implementation of the LoadBalancer Connector.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        return error UnsupportedActionError("Load balancer client not supported for getResponse action");
    }

    # The hasPromise implementation of the LoadBalancer Connector.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return false;
    }

    # The getNextPromise implementation of the LoadBalancer Connector.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return error UnsupportedActionError("Load balancer client not supported for getNextPromise action");
    }

    # The getPromisedResponse implementation of the LoadBalancer Connector.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return error UnsupportedActionError("Load balancer client not supported for getPromisedResponse action");
    }

    # The rejectPromise implementation of the LoadBalancer Connector.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {}

    // Performs execute action of the Load Balance connector. extract the corresponding http integer value representation
    // of the http verb and invokes the perform action method.
    isolated function performLoadBalanceExecuteAction(string path, Request request,
                                             string httpVerb) returns Response|ClientError {
        HttpOperation connectorAction = extractHttpOperation(httpVerb);
        if connectorAction != HTTP_NONE {
            return self.performLoadBalanceAction(path, request, connectorAction);
        } else {
            return error UnsupportedActionError("Load balancer client not supported for http method: " + httpVerb);
        }
    }

    // Handles all the actions exposed through the Load Balance connector.
    isolated function performLoadBalanceAction(string path, Request request, HttpOperation requestAction)
             returns Response|ClientError {
        int loadBalanceTermination = 0; // Tracks at which point failover within the load balancing should be terminated.
        //TODO: workaround to initialize a type inside a function. Change this once fix is available.
        LoadBalanceActionErrorData loadBalanceActionErrorData = {httpActionErr:[]};
        int lbErrorIndex = 0;
        Request loadBalancerInRequest = request;
        mime:Entity requestEntity = new;

        if self.failover {
            if isMultipartRequest(loadBalancerInRequest) {
                loadBalancerInRequest = check populateMultipartRequest(loadBalancerInRequest);
            } else {
                // When performing passthrough scenarios using Load Balance connector,
                // message needs to be built before trying out the load balance endpoints to keep the request message
                // to load balance the messages in case of failure.
                if !loadBalancerInRequest.hasMsgDataSource() {
                    byte[]|error binaryPayload = loadBalancerInRequest.getBinaryPayload();
                    if binaryPayload is error {
                        log:printDebug("Error building payload for request load balance: " + binaryPayload.message());
                    }
                }
                requestEntity = check loadBalancerInRequest.getEntity();
            }
        }

        int arrLength;
        lock {
            arrLength = self.loadBalanceClientsArray.length();
        }
        while (loadBalanceTermination < arrLength) {
            Client|ClientError loadBalanceClient;
            lock {
                loadBalanceClient = self.lbRule.getNextClient(self.loadBalanceClientsArray);
            }
            if loadBalanceClient is Client {
                var serviceResponse = invokeEndpoint(path, request, requestAction, loadBalanceClient.httpClient);
                if serviceResponse is Response {
                    return serviceResponse;
                } else if serviceResponse is HttpFuture {
                    return getInvalidTypeError();
                } else if serviceResponse is ClientError {
                    if self.failover {
                        loadBalancerInRequest = check createFailoverRequest(loadBalancerInRequest, requestEntity);
                        loadBalanceActionErrorData.httpActionErr[lbErrorIndex] = serviceResponse;
                        lbErrorIndex += 1;
                        loadBalanceTermination = loadBalanceTermination + 1;
                    } else {
                        return serviceResponse;
                    }
                } else {
                    panic error ClientError("invalid response type received");
                }
            } else {
                return loadBalanceClient;
            }
        }
        return populateGenericLoadBalanceActionError(loadBalanceActionErrorData);
    }
}

// Populates generic error specific to Load Balance connector by including all the errors returned from endpoints.
isolated function populateGenericLoadBalanceActionError(LoadBalanceActionErrorData loadBalanceActionErrorData)
                                                    returns ClientError {
    error[]? errArray = loadBalanceActionErrorData?.httpActionErr;
    if errArray is () {
        panic error("Unexpected nil");
    } else {
        int nErrs = errArray.length();
        error actError = errArray[nErrs - 1];
        string lastErrorMessage = actError.message();
        string message = "All the load balance endpoints failed. Last error was: " + lastErrorMessage;
        return error AllLoadBalanceEndpointsFailedError(message, httpActionError = errArray);
    }
}


# The configurations related to the load balancing client endpoint. The following fields are inherited from the other
# configuration records in addition to the load balancing client specific configs.
#
# + targets - The upstream HTTP endpoints among which the incoming HTTP traffic load should be distributed
# + lbRule - The `LoadBalancing` rule
# + failover - Configuration for the load balancer whether to fail over a failure
public type LoadBalanceClientConfiguration record {|
    *CommonClientConfiguration;
    TargetService[] targets = [];
    LoadBalancerRule? lbRule = ();
    boolean failover = true;
|};

isolated function createClientEPConfigFromLoalBalanceEPConfig(LoadBalanceClientConfiguration lbConfig,
                                                     TargetService target) returns ClientConfiguration {
    ClientConfiguration clientEPConfig = {
        http1Settings: lbConfig.http1Settings,
        http2Settings: lbConfig.http2Settings,
        circuitBreaker:lbConfig.circuitBreaker,
        timeout:lbConfig.timeout,
        httpVersion:lbConfig.httpVersion,
        forwarded:lbConfig.forwarded,
        followRedirects:lbConfig.followRedirects,
        retryConfig:lbConfig.retryConfig,
        poolConfig:lbConfig.poolConfig,
        secureSocket:target.secureSocket,
        cache:lbConfig.cache,
        compression:lbConfig.compression,
        auth:lbConfig.auth,
        cookieConfig:lbConfig.cookieConfig,
        responseLimits:lbConfig.responseLimits,
        validation:lbConfig.validation,
        socketConfig:lbConfig.socketConfig
    };
    return clientEPConfig;
}
