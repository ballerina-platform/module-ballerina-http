// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

// todo: update doc comments properly
client isolated class ResettableRetryClient {

    final HttpClient httpClient;

    # Provides the HTTP remote functions for interacting with an HTTP endpoint. This is created by wrapping the HTTP
    # client to provide retrying over HTTP requests.
    #
    # + url - Target service url
    # + config - HTTP ClientConfiguration to be used for HTTP client invocation
    # + httpClient - HTTP client for outbound HTTP requests
    # + return - The `client` or an `http:ClientError` if the initialization failed
    isolated function init(string url, ClientConfiguration config, HttpClient httpClient) returns ClientError? {
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
        var result = self.httpClient->post(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->post(path, message);
        }
        return result;
    }

    # The `RetryClient.head()` function wraps the underlying HTTP remote functions in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = self.httpClient->head(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->head(path, message);
        }
        return result;
    }

    # The `RetryClient.put()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function put(string path, RequestMessage message) returns Response|ClientError {
        var result = self.httpClient->put(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->put(path, message);
        }
        return result;
    }

    # The `RetryClient.forward()` function wraps the underlying HTTP remote function in a way to provide retrying
    # functionality for a given endpoint with inbound request's HTTP verb to recover from network level failures.
    #
    # + path - Resource path
    # + request - An HTTP inbound request message
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function forward(string path, Request request) returns Response|ClientError {
        var result = self.httpClient->forward(path, request);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->forward(path, request);
        }
        return result;
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
        var result = self.httpClient->execute(httpVerb, path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->execute(httpVerb, path, message);
        }
        return result;
    }

    # The `RetryClient.patch()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function patch(string path, RequestMessage message) returns Response|ClientError {
        var result = self.httpClient->patch(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->patch(path, message);
        }
        return result;
    }

    # The `RetryClient.delete()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function delete(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = self.httpClient->delete(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->delete(path, message);
        }
        return result;
    }

    # The `RetryClient.get()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function get(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = self.httpClient->get(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->get(path, message);
        }
        return result;
    }

    # The `RetryClient.options()` function wraps the underlying HTTP remote function in a way to provide
    # retrying functionality for a given endpoint to recover from network level failures.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request or any allowed payload
    # + return - The response or an `http:ClientError` if failed to establish the communication with the upstream server
    remote isolated function options(string path, RequestMessage message = ()) returns Response|ClientError {
        var result = self.httpClient->options(path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->options(path, message);
        }
        return result;
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
        var result = self.httpClient->submit(httpVerb, path, message);
        while result is AllRetryAttemptsFailed {
            result = self.httpClient->submit(httpVerb, path, message);
        }
        return result;
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
