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

# Lies inside every type of client in the chain holding the native client connector. More complex and specific
# endpoint types are created by wrapping this generic HTTP actions implementation internally.
client isolated class HttpClient {

    # Gets invoked to initialize the native `client`. During the initialization, the configurations are provided through the
    # `config`. The `HttpClient` lies inside every type of client in the chain holding the native client connector.
    #
    # + url - URL of the target service
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or an `http:ClientError` if the initialization failed
    isolated function init(string url, ClientConfiguration? config = ()) returns ClientError? {
        ClientConfiguration options = config ?: {};
        return createSimpleHttpClient(self, globalHttpClientConnPool, url, options, options.toString());
    }

    # Create a new resource or submit data to a resource for processing.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function post(string path, RequestMessage message) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_POST);
    }

    # Get the metadata of a resource in the form of headers without the body. Often used for testing the resource existence or finding recent modifications.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, RequestMessage message = ()) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_HEAD);
    }

    # Create a new resource or replace a representation of a specified resource.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function put(string path, RequestMessage message) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_PUT);
    }

    # Send a request using any HTTP method. Can be used to invoke the endpoint with a custom or less common HTTP method.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function execute(string httpVerb,  string path, RequestMessage message)
             returns Response|ClientError {
        return externExecute(self, httpVerb, path, <Request>message);
    }

    # Partially update an existing resource in an HTTP endpoint.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function patch(string path, RequestMessage message) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_PATCH);
    }

    # Remove a specified resource from an HTTP endpoint.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function delete(string path, RequestMessage message = ()) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_DELETE);
    }

    # Retrieve a representation of a specified resource from an HTTP endpoint.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function get(string path, RequestMessage message = ()) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_GET);
    }

    # Get the communication options for a specified resource.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function options(string path, RequestMessage message = ()) returns Response|ClientError {
        return externExecuteClientAction(self, path, <Request>message, HTTP_OPTIONS);
    }

    # Forward an incoming request to another endpoint using the same HTTP method. Can be used in proxy or gateway scenarios.
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function forward(string path, Request request) returns Response|ClientError {
        return externForward(self, path, request);
    }

    # Send an asynchronous HTTP request that does not wait for the response immediately. Can be used for non-blocking operations.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation, or else an `http:ClientError` if the submission fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        return externSubmit(self, httpVerb, path, <Request>message);
    }

    # Get the response from a previously submitted asynchronous request. Can be used after calling `submit()` action to retrieve the actual response.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        return externGetResponse(self, httpFuture);
    }

    # Check if the server has sent a push promise for additional resources. Should be used with HTTP/2 server push functionality.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return externHasPromise(self, httpFuture);
    }

    # Get the next server push promise that contains information about additional resources the server wants to send.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return externGetNextPromise(self, httpFuture);
    }

    # Get the actual response data from a server push promise. Can be used to receive resources that the server proactively sends.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return externGetPromisedResponse(self, promise);
    }

    # Reject a server push promise to decline receiving the additional resource.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return externRejectPromise(self, promise);
    }
}

isolated function createSimpleHttpClient(HttpClient caller, PoolConfiguration globalPoolConfig, string clientUrl,
ClientConfiguration clientEndpointConfig, string optionsString) returns ClientError? = @java:Method {
   'class: "io.ballerina.stdlib.http.api.client.endpoint.CreateSimpleHttpClient",
   name: "createSimpleHttpClient"
} external;

isolated function externGetResponse(HttpClient httpClient, HttpFuture httpFuture) returns Response|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.GetResponse",
    name: "getResponse"
} external;

isolated function externHasPromise(HttpClient httpClient, HttpFuture httpFuture) returns boolean =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.HasPromise",
    name: "hasPromise"
} external;

isolated function externGetNextPromise(HttpClient httpClient, HttpFuture httpFuture) returns PushPromise|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.GetNextPromise",
    name: "getNextPromise"
} external;

isolated function externGetPromisedResponse(HttpClient httpClient, PushPromise promise) returns Response|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.GetPromisedResponse",
    name: "getPromisedResponse"
} external;

isolated function externRejectPromise(HttpClient httpClient, PushPromise promise) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
    name: "rejectPromise"
} external;

isolated function externExecute(HttpClient caller, string httpVerb, string path, Request req) returns Response|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.Execute",
    name: "execute"
} external;

isolated function externSubmit(HttpClient caller, string httpVerb, string path, Request req) returns HttpFuture|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.Submit",
    name: "submit"
} external;

isolated function externForward(HttpClient caller, string path, Request req) returns Response|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.Forward",
    name: "forward"
} external;

isolated function externExecuteClientAction(HttpClient caller, string path, Request req, string httpMethod)
                                  returns Response|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.actions.HttpClientAction",
    name: "executeClientAction"
} external;

isolated function createClient(string url, ClientConfiguration config) returns HttpClient|ClientError {
    HttpClient simpleClient = check new(url, config);
    return simpleClient;
}
