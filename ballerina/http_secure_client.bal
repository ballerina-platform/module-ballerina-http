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
# + httpClient - The underlying `HttpActions` instance, which will make the actual network calls
client isolated class HttpSecureClient {

    private final HttpClient httpClient;
    private final ClientAuthHandler clientAuthHandler;

    # Gets invoked to initialize the secure `client`. Due to the secure client related configurations provided
    # through the `config` record, the `HttpSecureClient` is initialized.
    #
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or an `http:ClientError` if the initialization failed
    isolated function init(string url, ClientConfiguration config) returns ClientError? {
        self.clientAuthHandler = initClientAuthHandler(config);
        HttpClient|ClientError simpleClient = createClient(url, config);
        if simpleClient is HttpClient {
            self.httpClient = simpleClient;
        } else {
            return simpleClient;
        }
        return;
    }

    # This wraps the `HttpSecureClient.post()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function post(string path, RequestMessage message) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->post(path, req);
    }

    # This wraps the `HttpSecureClient.head()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head( string path, RequestMessage message = ()) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->head(path, message = req);
    }

    # This wraps the `HttpSecureClient.put()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function put(string path, RequestMessage message) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->put(path, req);
    }

    # This wraps the `HttpSecureClient.execute()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers o the request and send the request to actual network call.
    #
    # + httpVerb - HTTP verb value
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function execute(string httpVerb, string path, RequestMessage message) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->execute(httpVerb, path, req);
    }

    # This wraps the `HttpSecureClient.patch()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function patch(string path, RequestMessage message) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->patch(path, req);
    }

    # This wraps the `HttpSecureClient.delete()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function delete(string path, RequestMessage message = ()) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->delete(path, req);
    }

    # This wraps the `HttpSecureClient.get()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function get(string path, RequestMessage message = ()) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->get(path, message = req);
    }

    # This wraps the `HttpSecureClient.options()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function options(string path, RequestMessage message = ()) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->options(path, message = req);
    }

    # This wraps the `HttpSecureClient.forward()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + path - Request path
    # + request - An HTTP inbound request message
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function forward(string path, Request request) returns Response|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, request);
        return self.httpClient->forward(path, req);
    }

    # This wraps the `HttpSecureClient.submit()` function of the underlying HTTP remote functions provider. Add relevant authentication
    # headers to the request and send the request to actual network call.
    #
    # + httpVerb - The HTTP verb value. The HTTP verb is case-sensitive. Use the `http:Method` type to specify the
    #              the standard HTTP methods.
    # + path - The resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - An `http:HttpFuture` that represents an asynchronous service invocation, or else an `http:ClientError` if the submission fails
    remote isolated function submit(string httpVerb, string path, RequestMessage message) returns HttpFuture|ClientError {
        Request req = check enrichRequest(self.clientAuthHandler, <Request>message);
        return self.httpClient->submit(httpVerb, path, req);
    }

    # This just passes the request to the actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError {
        return self.httpClient->getResponse(httpFuture);
    }

    # Passes the request to an actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - A `boolean`, which represents whether an `http:PushPromise` exists
    remote isolated function hasPromise(HttpFuture httpFuture) returns boolean {
        return self.httpClient->hasPromise(httpFuture);
    }

    # Passes the request to an actual network call.
    #
    # + httpFuture - The `http:HttpFuture` related to a previous asynchronous invocation
    # + return - An `http:PushPromise` message or else an `http:ClientError` if the invocation fails
    remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError {
        return self.httpClient->getNextPromise(httpFuture);
    }

    # Passes the request to an actual network call.
    #
    # + promise - The related `http:PushPromise`
    # + return - A promised `http:Response` message or else an `http:ClientError` if the invocation fails
    remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError {
        return self.httpClient->getPromisedResponse(promise);
    }

    # Passes the request to an actual network call.
    #
    # + promise - The Push Promise to be rejected
    remote isolated function rejectPromise(PushPromise promise) {
        return self.httpClient->rejectPromise(promise);
    }
}

# Creates an HTTP client capable of securing HTTP requests with authentication.
#
# + url - Base URL
# + config - Client endpoint configurations
# + return - Created secure HTTP client
public isolated function createHttpSecureClient(string url, ClientConfiguration config) returns HttpClient|ClientError {
    HttpSecureClient httpSecureClient;
    if config.auth is ClientAuthConfig {
        httpSecureClient = check new(url, config);
        return httpSecureClient;
    } else {
        return createClient(url, config);
    }
}

// Enriches the request using the relevant client auth handler.
isolated function enrichRequest(ClientAuthHandler clientAuthHandler, Request req) returns Request|ClientError {
    if clientAuthHandler is ClientBasicAuthHandler {
        return clientAuthHandler.enrich(req);
    } else if clientAuthHandler is ClientBearerTokenAuthHandler {
        return clientAuthHandler.enrich(req);
    } else if clientAuthHandler is ClientSelfSignedJwtAuthHandler {
        return clientAuthHandler.enrich(req);
    } else if clientAuthHandler is ClientOAuth2Handler {
        return clientAuthHandler->enrich(req);
    } else {
        string errorMsg = "Invalid client auth-handler found. Expected one of http:ClientBasicAuthHandler|http:ClientBearerTokenAuthHandler|http:ClientSelfSignedJwtAuthHandler|http:ClientOAuth2Handler.";
        panic error ClientError(errorMsg);
    }
}

// Initialize the client auth handler based on the provided configurations
isolated function initClientAuthHandler(ClientConfiguration config) returns ClientAuthHandler {
    // The existence of auth configuration is already validated.
    ClientAuthConfig authConfig = <ClientAuthConfig>(config.auth);
    if authConfig is CredentialsConfig {
        ClientBasicAuthHandler handler = new(authConfig);
        return handler;
    } else if authConfig is BearerTokenConfig {
        ClientBearerTokenAuthHandler handler = new(authConfig);
        return handler;
    } else if authConfig is JwtIssuerConfig {
        ClientSelfSignedJwtAuthHandler handler = new(authConfig);
        return handler;
    } else {
        // Here, `authConfig` is `OAuth2GrantConfig`
        ClientOAuth2Handler handler = new(authConfig);
        return handler;
    }
}
