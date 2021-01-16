// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Provides secure HTTP remote functions for interacting with HTTP endpoints. This will make use of the authentication
# schemes configured in the HTTP client endpoint to secure the HTTP requests.
#
# + url - The URL of the remote HTTP endpoint
# + config - The configurations of the client endpoint associated with this `HttpActions` instance
# + httpClient - The underlying `HttpActions` instance, which will make the actual network calls
public client class HttpSecureClient {

    public string url = "";
    public ClientConfiguration config = {};
    public HttpClient httpClient;
    ClientAuthHandler clientAuthHandler;

    # Gets invoked to initialize the secure `client`. Due to the secure client releated configurations provided
    # through the `config` record, the `HttpSecureClient` is initialized.
    #
    # + url - URL of the target service
    # + config - The configurations to be used when initializing the `client`
    public function init(string url, ClientConfiguration config) {
        self.url = url;
        self.config = config;
        self.clientAuthHandler = initClientAuthHandler(config);
        HttpClient|ClientError simpleClient = createClient(url, self.config);
        if (simpleClient is HttpClient) {
            self.httpClient = simpleClient;
        } else {
            panic <error> simpleClient;
        }
    }

    # This wraps the `HttpSecureClient.post()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function post(string path, RequestMessage message, TargetType targetType = Response)
            returns Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->post(path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->post(path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.head()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote function head(@untainted string path, RequestMessage message = ()) returns @tainted
            Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response res = check self.httpClient->head(path, message = req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->head(path, message = inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.put()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function put(string path, RequestMessage message, TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->put(path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->put(path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.execute()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers o the request and send the request to actual network call.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function execute(string httpVerb, string path, RequestMessage message, TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->execute(httpVerb, path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->execute(httpVerb, path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.patch()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function patch(string path, RequestMessage message, TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->patch(path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->patch(path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.delete()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function delete(string path, RequestMessage message = (), TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->delete(path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->delete(path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.get()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function get(string path, RequestMessage message = (), TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->get(path, message = req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->get(path, message = inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.options()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel` or `mime:Entity[]`
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function options(string path, RequestMessage message = (), TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        Response|PayloadType res = check self.httpClient->options(path, message = req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->options(path, message = inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.forward()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + targetType - HTTP response or the payload type (`string`, `xml`, `json`, `byte[]`,`record {| anydata...; |}`, or
    #                `record {| anydata...; |}[]`), which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or an `http:ClientError` if failed to
    #            establish the communication with the upstream server or a data binding failure
    remote function forward(string path, Request request, TargetType targetType = Response)
            returns @tainted Response|PayloadType|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, request);
        Response|PayloadType res = check self.httpClient->forward(path, req);
        Request? inspection = check inspectRequest(self.clientAuthHandler, req, res);
        if (inspection is Request) {
            return self.httpClient->forward(path, inspection);
        }
        return res;
    }

    # This wraps the `HttpSecureClient.submit()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + httpVerb - The HTTP verb value
    # + path - The resource path
    # + message - An HTTP outbound request message or any payload of type `string`, `xml`, `json`, `byte[]`,
    #             `io:ReadableByteChannel`, or `mime:Entity[]`
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation, or else an `http:ClientError` if the submission fails
    remote function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->submit(httpVerb, path, req);
    }

    # This just passes the request to the actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        return self.httpClient->getResponse(httpFuture);
    }

    # Passes the request to an actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Passes the request to an actual network call.
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
        return self.httpClient->getPromisedResponse(promise);
    }

    # Passes the request to an actual network call.
    #
    # + promise - The Push Promise to be rejected
    remote function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }
}

# Creates an HTTP client capable of securing HTTP requests with authentication.
#
# + url - Base URL
# + config - Client endpoint configurations
# + return - Created secure HTTP client
public function createHttpSecureClient(string url, ClientConfiguration config) returns HttpClient|ClientError {
    HttpSecureClient httpSecureClient;
    if (config.auth is ClientAuthConfig) {
        httpSecureClient = new(url, config);
        return httpSecureClient;
    } else {
        return createClient(url, config);
    }
}

// Enriches the request using the relevant client auth handler.
isolated function enrichRequest(ClientAuthHandler clientAuthHandler, Request req) returns Request|ClientError {
    if (clientAuthHandler is ClientBasicAuthHandler) {
        return clientAuthHandler.enrich(req);
    } else if (clientAuthHandler is ClientBearerTokenAuthHandler) {
        return clientAuthHandler.enrich(req);
    } else if (clientAuthHandler is ClientSelfSignedJwtAuthHandler) {
        return clientAuthHandler.enrich(req);
    } else {
        // Here, `clientAuthHandler` is `ClientOAuth2Handler`
        return clientAuthHandler->enrich(req);
    }
}

// Inspect the request using the relevant client auth handler.
isolated function inspectRequest(ClientAuthHandler clientAuthHandler, Request req, Response|PayloadType res)
                                 returns Request|ClientAuthError? {
    if (clientAuthHandler is ClientOAuth2Handler && res is Response) {
        return clientAuthHandler->inspect(req, res);
    }
}

// Initialize the client auth handler based on the provided configurations
isolated function initClientAuthHandler(ClientConfiguration config) returns ClientAuthHandler {
    // The existence of auth configuration is already validated.
    ClientAuthConfig authConfig = <ClientAuthConfig>(config.auth);
    if (authConfig is CredentialsConfig) {
        ClientBasicAuthHandler handler = new(authConfig);
        return handler;
    } else if (authConfig is BearerTokenConfig) {
        ClientBearerTokenAuthHandler handler = new(authConfig);
        return handler;
    } else if (authConfig is JwtIssuerConfig) {
        ClientSelfSignedJwtAuthHandler handler = new(authConfig);
        return handler;
    } else {
        // Here, `authConfig` is `OAuth2GrantConfig`
        ClientOAuth2Handler handler = new(authConfig);
        return handler;
    }
}
