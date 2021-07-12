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

import ballerina/log;
import ballerina/test;
import ballerina/http;

isolated int http2RetryCount = 0;

isolated function retrieveAndIncrementHttp2RetryCounter() returns int {
    lock {
        int currentCounter = http2RetryCount;
        http2RetryCount += 1;
        return currentCounter;
    }
}

listener http:Listener http2RetryTestserviceEndpoint1 = new(http2RetryFunctionTestPort1, { httpVersion: "2.0" });

http:Client http2RetryFunctionTestClient = check new("http://localhost:" + http2RetryFunctionTestPort1.toString(), { httpVersion: "2.0" });

// Define the end point to the call the `mockHelloService`.
http:Client http2RetryBackendClientEP = check new("http://localhost:9606", {
    // Retry configuration options.
    retryConfig: {
        interval: 3,
        count: 4,
        backOffFactor: 0.5
    },
    timeout: 2,
    httpVersion: "2.0"
});

service /retryDemoService on http2RetryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function 'default .(http:Caller caller, http:Request request) {
        var backendFuture = http2RetryBackendClientEP->submit("GET", "/mockHelloService", request);
        if (backendFuture is http:HttpFuture) {
            http:Response|error backendResponse = http2RetryBackendClientEP->getResponse(backendFuture);
            if (backendResponse is http:Response) {
                error? responseToCaller = caller->respond(backendResponse);
                if (responseToCaller is error) {
                    log:printError("Error sending response", 'error = responseToCaller);
                }
            } else {
                respondWithError(caller, backendResponse);
            }
        } else {
            respondWithError(caller, <error>backendFuture);
        }
    }

    resource function get .(http:Caller caller, http:Request request) {
        var backendFuture = http2RetryBackendClientEP->submit("POST", "/mockHelloService", request);
        if (backendFuture is http:HttpFuture) {
            // Check whether promises exists
            http:PushPromise?[] promises = [];
            int promiseCount = 0;
            boolean hasPromise = http2RetryBackendClientEP->hasPromise(backendFuture);
            while (hasPromise) {
                http:PushPromise pushPromise = new;
                // Get the next promise
                var nextPromiseResult = http2RetryBackendClientEP->getNextPromise(backendFuture);
                if (nextPromiseResult is http:PushPromise) {
                    pushPromise = nextPromiseResult;
                } else {
                    log:printError("Error occurred while fetching a push promise");
                    json errMsg = { "error": "error occurred while fetching a push promise" };
                    checkpanic caller->respond(errMsg);
                    return;
                }
                log:printInfo(string`Received Promise for path [${pushPromise.path}]`);
                // Store required promises
                promises[promiseCount] = pushPromise;
                promiseCount = promiseCount + 1;
                hasPromise = http2RetryBackendClientEP->hasPromise(backendFuture);
            }

            // By this time 1 promise should be received, if not send an error response
            if (promiseCount <= 0) {
                json errMsg = { "error": "expected number of promises not received" };
                checkpanic caller->respond(errMsg);
                return;
            }

            // Get the requested resource
            http:Response response = new;
            var result = http2RetryBackendClientEP->getResponse(backendFuture);
            if (result is http:Response) {
                response = result;
            } else {
                log:printError("Error occurred while fetching response");
                json errMsg = { "error": "error occurred while fetching response" };
                checkpanic caller->respond(errMsg);
                return;
            }

            var responsePayload = response.getJsonPayload();
            json responseJsonPayload = {};
            if (responsePayload is json) {
                log:printInfo("Received main response ", mainMsg = responsePayload);
                responseJsonPayload = responsePayload;
            } else {
                log:printError("Received Error response ", errorMsg = responsePayload.message());
                json errMsg = { "error": "expected response message not received" };
                checkpanic caller->respond(errMsg);
                return;
            }

            // Fetch required promised responses
            json[] retrievedPromises = [];
            foreach var p in promises {
                http:PushPromise promise = <http:PushPromise>p;
                http:Response promisedResponse = new;
                var promisedResponseResult = http2RetryBackendClientEP->getPromisedResponse(promise);
                if (promisedResponseResult is http:Response) {
                    promisedResponse = promisedResponseResult;
                } else {
                    log:printError("Error occurred while fetching promised response");
                    json errMsg = { "error": "error occurred while fetching promised response" };
                    checkpanic caller->respond(errMsg);
                    return;
                }

                json promisedJsonPayload = {};
                var promisedPayload = promisedResponse.getJsonPayload();
                if (promisedPayload is json) {
                    promisedJsonPayload = promisedPayload;
                } else {
                    json errMsg = { "error": "expected promised response not received" };
                    checkpanic caller->respond(errMsg);
                    return;
                }
                retrievedPromises.push(promisedJsonPayload);
            }
            json constructedResponse = {
                "main": responseJsonPayload,
                "promises": retrievedPromises
            };
            error? responseToCaller = caller->respond(constructedResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            respondWithError(caller, <error>backendFuture);
        }
    }
}

isolated function respondWithError(http:Caller caller, error currentError) {
    http:Response response = new;
    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
    response.setPayload(currentError.message());
    error? responseToCaller = caller->respond(response);
    if (responseToCaller is error) {
        log:printError("Error sending response", 'error = responseToCaller);
    }
}

// This sample service is used to mock connection timeouts and service outages.
// The service outage is mocked by stopping/starting this service.
// This should run separately from the `retryDemoService` service.
service /mockHelloService on http2RetryTestserviceEndpoint1 {
    isolated resource function get .(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementHttp2RetryCounter();
        waitForRetry(counter);
        error? responseToCaller = caller->respond("Hello World!!!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    isolated resource function post .(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementHttp2RetryCounter();
        waitForRetry(counter);
        // Send a Push Promise
        http:PushPromise promise = new("/resource1", "POST");
        checkpanic caller->promise(promise);
        // Construct requested resource
        json mainResponseMsg = {
            "response": {
                "name": "main resource"
            }
        };
        // Send the requested resource
        checkpanic caller->respond(mainResponseMsg);
        http:Response pushResponse = new;
        json msg = { "push": { "name": "resource3" } };
        pushResponse.setJsonPayload(msg);
        checkpanic caller->pushPromisedResponse(promise, pushResponse);
    }
}

//Test basic retry functionality with HTTP2
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2SimpleRetry() {
    json payload = {Name:"Ballerina"};
    http:Response|error response = http2RetryFunctionTestClient->post("/retryDemoService", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test basic retry functionality with HTTP2 Server Push
@test:Config {
    enable: false,
    groups: ["http2RetryClientTest"]
}
function testHttp2RetryWithServerPush() {
    string expectedPayload = "{\"main\":{\"response\":{\"name\":\"main resource\"}}, \"promises\":[{\"push\":{\"name\":\"resource3\"}}]}";
    http:Response|error response = http2RetryFunctionTestClient->get("/retryDemoService");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertTextPayload(response.getTextPayload(), expectedPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
