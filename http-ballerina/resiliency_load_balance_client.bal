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

# LoadBalanceClient endpoint provides load balancing functionality over multiple HTTP clients.
#
# + loadBalanceClientConfig - The configurations for the load balance client endpoint
# + loadBalanceClientsArray - Array of HTTP clients for load balancing
# + lbRule - Load balancing rule
# + failover - Whether to fail over in case of a failure
public client class LoadBalanceClient {
    *ClientObject;

    public LoadBalanceClientConfiguration loadBalanceClientConfig;
    public Client?[] loadBalanceClientsArray;
    public LoadBalancerRule lbRule;
    public boolean failover;

    # Load Balancer adds an additional layer to the HTTP client to make network interactions more resilient.
    #
    # + loadBalanceClientConfig - The configurations for the load balance client endpoint
    # + return - The `client` or an `http:ClientError` if the initialization failed
    public isolated function init(LoadBalanceClientConfiguration loadBalanceClientConfig) returns ClientError? {
        self.loadBalanceClientConfig = loadBalanceClientConfig;
        self.failover = loadBalanceClientConfig.failover;
        var lbClients = createLoadBalanceHttpClientArray(loadBalanceClientConfig);
        if (lbClients is ClientError) {
            return lbClients;
        } else {
            self.loadBalanceClientsArray = lbClients;
            var lbRule = loadBalanceClientConfig.lbRule;
            if (lbRule is LoadBalancerRule) {
                self.lbRule = lbRule;
            } else {
                LoadBalancerRoundRobinRule loadBalancerRoundRobinRule = new;
                self.lbRule = loadBalancerRoundRobinRule;
            }
        }
    }

    # The POST remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function post(@untainted string path, RequestMessage message, string? mediaType = (),
            map<string|string[]>? headers = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processPost(@untainted string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        populateOptions(req, mediaType, headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_POST);
        return processResponse(result, targetType);
    }

    # The PUT remote function implementation of the Load Balance Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function put(@untainted string path, RequestMessage message, string? mediaType = (),
            map<string|string[]>? headers = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processPut(@untainted string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        populateOptions(req, mediaType, headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_PUT);
        return processResponse(result, targetType);
    }

    # The PATCH remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function patch(@untainted string path, RequestMessage message, string? mediaType = (),
            map<string|string[]>? headers = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processPatch(@untainted string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        populateOptions(req, mediaType, headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_PATCH);
        return processResponse(result, targetType);
    }

    # The DELETE remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function delete(@untainted string path, RequestMessage message = (), string? mediaType = (),
            map<string|string[]>? headers = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processDelete(@untainted string path, RequestMessage message, TargetType targetType, 
            string? mediaType, map<string|string[]>? headers) returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        populateOptions(req, mediaType, headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_DELETE);
        return processResponse(result, targetType);
    }

    # The HEAD remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(@untainted string path, map<string|string[]>? headers = ()) returns @tainted
            Response|ClientError {
        Request req = buildRequestWithHeaders(headers);
        return performLoadBalanceAction(self, path, req, HTTP_HEAD);
    }

    # The GET remote function implementation of the LoadBalancer Connector.
    # 
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function get(@untainted string path, map<string|string[]>? headers = (), TargetType targetType = Response)
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processGet(string path, map<string|string[]>? headers, TargetType targetType)
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_GET);
        return processResponse(result, targetType);
    }

    # The OPTIONS remote function implementation of the LoadBalancer Connector.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function options(@untainted string path, map<string|string[]>? headers = (), TargetType targetType = Response)
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processOptions(string path, map<string|string[]>? headers, TargetType targetType)
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequestWithHeaders(headers);
        var result = performLoadBalanceAction(self, path, req, HTTP_OPTIONS);
        return processResponse(result, targetType);
    }

    # The EXECUTE remote function implementation of the LoadBalancer Connector.
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
    remote isolated function execute(@untainted string httpVerb, @untainted string path, RequestMessage message,
            string? mediaType = (), map<string|string[]>? headers = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;
    
    private isolated function processExecute(@untainted string httpVerb, @untainted string path, RequestMessage message,
            TargetType targetType, string? mediaType, map<string|string[]>? headers) 
            returns @tainted Response|PayloadType|ClientError {
        Request req = buildRequest(message);
        populateOptions(req, mediaType, headers);
        var result = performLoadBalanceExecuteAction(self, path, req, httpVerb);
        return processResponse(result, targetType);
    }

    # The FORWARD remote function implementation of the LoadBalancer Connector.
    #
    # + path - Resource path
    # + request - An HTTP request
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote isolated function forward(@untainted string path, Request request, TargetType targetType = Response)
            returns @tainted targetType|ClientError = @java:Method {
        'class: "org.ballerinalang.net.http.client.actions.HttpClientAction"
    } external;

    private isolated function processForward(string path, Request request, TargetType targetType)
            returns @tainted Response|PayloadType|ClientError {
        var result = performLoadBalanceAction(self, path, request, HTTP_FORWARD);
        return processResponse(result, targetType);
    }

    # The submit implementation of the LoadBalancer Connector.
    #
    # + httpVerb - The HTTP verb value
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
}

// Performs execute action of the Load Balance connector. extract the corresponding http integer value representation
// of the http verb and invokes the perform action method.
isolated function performLoadBalanceExecuteAction(LoadBalanceClient lb, string path, Request request,
                                         string httpVerb) returns @tainted Response|ClientError {
    HttpOperation connectorAction = extractHttpOperation(httpVerb);
    if (connectorAction != HTTP_NONE) {
        return performLoadBalanceAction(lb, path, request, connectorAction);
    } else {
        return error UnsupportedActionError("Load balancer client not supported for http method: " + httpVerb);
    }
}

// Handles all the actions exposed through the Load Balance connector.
isolated function performLoadBalanceAction(LoadBalanceClient lb, string path, Request request, HttpOperation requestAction)
             returns @tainted Response|ClientError {
    int loadBalanceTermination = 0; // Tracks at which point failover within the load balancing should be terminated.
    //TODO: workaround to initialize a type inside a function. Change this once fix is available.
    LoadBalanceActionErrorData loadBalanceActionErrorData = {httpActionErr:[]};
    int lbErrorIndex = 0;
    Request loadBalancerInRequest = request;
    mime:Entity requestEntity = new;

    if (lb.failover) {
        if (isMultipartRequest(loadBalancerInRequest)) {
            loadBalancerInRequest = check populateMultipartRequest(loadBalancerInRequest);
        } else {
            // When performing passthrough scenarios using Load Balance connector,
            // message needs to be built before trying out the load balance endpoints to keep the request message
            // to load balance the messages in case of failure.
            byte[]|error binaryPayload = loadBalancerInRequest.getBinaryPayload();
            requestEntity = check loadBalancerInRequest.getEntity();
        }
    }

    while (loadBalanceTermination < lb.loadBalanceClientsArray.length()) {
        var loadBalanceClient = lb.lbRule.getNextClient(lb.loadBalanceClientsArray);
        if (loadBalanceClient is Client) {
            var serviceResponse = invokeEndpoint(path, request, requestAction, loadBalanceClient.httpClient);
            if (serviceResponse is Response) {
                return serviceResponse;
            } else if (serviceResponse is HttpFuture) {
                return getInvalidTypeError();
            } else {
                if (lb.failover) {
                    loadBalancerInRequest = check createFailoverRequest(loadBalancerInRequest, requestEntity);
                    loadBalanceActionErrorData.httpActionErr[lbErrorIndex] = serviceResponse;
                    lbErrorIndex += 1;
                    loadBalanceTermination = loadBalanceTermination + 1;
                } else {
                    return serviceResponse;
                }
            }
        } else {
            return loadBalanceClient;
        }
    }
    return populateGenericLoadBalanceActionError(loadBalanceActionErrorData);
}

// Populates generic error specific to Load Balance connector by including all the errors returned from endpoints.
isolated function populateGenericLoadBalanceActionError(LoadBalanceActionErrorData loadBalanceActionErrorData)
                                                    returns ClientError {
    error[]? errArray = loadBalanceActionErrorData?.httpActionErr;
    if (errArray is ()) {
        panic error("Unexpected nil");
    } else {
        int nErrs = errArray.length();
        error actError = errArray[nErrs - 1];
        string lastErrorMessage = actError.message();
        string message = "All the load balance endpoints failed. Last error was: " + lastErrorMessage;
        return error AllLoadBalanceEndpointsFailedError(message, httpActionError = errArray);
    }
}


# The configurations related to the load balance client endpoint. Following fields are inherited from the other
# configuration records in addition to the load balance client specific configs.
#
# |                                                         |
# |:------------------------------------------------------- |
# | httpVersion - Copied from CommonClientConfiguration     |
# | http1Settings - Copied from CommonClientConfiguration   |
# | http2Settings - Copied from CommonClientConfiguration   |
# | timeout - Copied from CommonClientConfiguration |
# | forwarded - Copied from CommonClientConfiguration       |
# | followRedirects - Copied from CommonClientConfiguration |
# | poolConfig - Copied from CommonClientConfiguration      |
# | cache - Copied from CommonClientConfiguration           |
# | compression - Copied from CommonClientConfiguration     |
# | auth - Copied from CommonClientConfiguration            |
# | circuitBreaker - Copied from CommonClientConfiguration  |
# | retryConfig - Copied from CommonClientConfiguration     |
# | cookieConfig - Copied from CommonClientConfiguration    |
# | responseLimits - Copied from CommonClientConfiguration  |
#
# + targets - The upstream HTTP endpoints among which the incoming HTTP traffic load should be distributed
# + lbRule - LoadBalancing rule
# + failover - Configuration for load balancer whether to fail over in case of a failure
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
        responseLimits:lbConfig.responseLimits
    };
    return clientEPConfig;
}

isolated function createLoadBalanceHttpClientArray(LoadBalanceClientConfiguration loadBalanceClientConfig)
                                                                                    returns Client?[]|ClientError {
    Client cl;
    Client?[] httpClients = [];
    int i = 0;
    foreach var target in loadBalanceClientConfig.targets {
        ClientConfiguration epConfig = createClientEPConfigFromLoalBalanceEPConfig(loadBalanceClientConfig, target);
        cl =  check new(target.url , epConfig);
        httpClients[i] = cl;
        i += 1;
    }
    return httpClients;
}
