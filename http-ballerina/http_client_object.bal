// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# The representation of the http Client object type for managing resilient clients.
public type ClientObject client object {

    # The `Client.post()` function can be used to send HTTP POST requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function post(@untainted string path, RequestMessage message, TargetType targetType = Response)
            returns @tainted targetType|ClientError;



    # The `Client.head()` function can be used to send HTTP HEAD requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function head(@untainted string path, RequestMessage message = ()) returns @tainted
            Response|ClientError;

    # The `Client.put()` function can be used to send HTTP PUT requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function put(@untainted string path, RequestMessage message, TargetType targetType = Response) 
            returns @tainted targetType|ClientError;


    # Invokes an HTTP call with the specified HTTP verb.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function execute(@untainted string httpVerb, @untainted string path, RequestMessage message,
            TargetType targetType = Response) returns @tainted targetType|ClientError;

    # The `Client.patch()` function can be used to send HTTP PATCH requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function patch(@untainted string path, RequestMessage message, TargetType targetType = Response) 
            returns @tainted targetType|ClientError;

    # The `Client.delete()` function can be used to send HTTP DELETE requests to HTTP endpoints.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function delete(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError;

    # The `Client.get()` function can be used to send HTTP GET requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function get(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError;

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to HTTP endpoints.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function options(@untainted string path, RequestMessage message = (), TargetType targetType = Response) 
            returns @tainted targetType|ClientError;

    # The `Client.forward()` function can be used to invoke an HTTP call with inbound request's HTTP verb
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function forward(@untainted string path, Request request, TargetType targetType = Response) 
            returns @tainted targetType|ClientError;

    # Submits an HTTP request to a service with the specified HTTP verb.
    # The `Client->submit()` function does not give out a `http:Response` as the result.
    # Rather it returns an `http:HttpFuture` which can be used to do further interactions with the endpoint.
    #
    # + httpVerb - The HTTP verb value
    # + path - The resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`
    #             or `mime:Entity[]`
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation or else an `http:ClientError` if the submission fails
    remote function submit(@untainted string httpVerb, string path, RequestMessage message)
        returns HttpFuture|ClientError;

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http: ClientError` if the invocation fails
    remote function getResponse(HttpFuture httpFuture) returns Response|ClientError;

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` relates to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote function hasPromise(HttpFuture httpFuture) returns boolean;

    # This just pass the request to actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError;

    # Passes the request to an actual network call.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote function getPromisedResponse(PushPromise promise) returns Response|ClientError;

    # This just pass the request to actual network call.
    #
    # + promise - The Push Promise to be rejected
    remote function rejectPromise(PushPromise promise);
};
