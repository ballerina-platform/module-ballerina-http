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
// import ballerina/log;
import ballerina/mime;
import ballerina/io;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener retryTestserviceEndpoint1 = new (retryFunctionTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener retryTestserviceEndpoint2 = new (retryFunctionTestPort2, httpVersion = http:HTTP_1_1);
final http:Client retryFunctionTestClient = check new ("http://localhost:" + retryFunctionTestPort1.toString(), httpVersion = http:HTTP_1_1);

// Define the end point to the call the `mockHelloService`.
final http:Client retryBackendClientEP = check new ("http://localhost:" + retryFunctionTestPort1.toString(),
    httpVersion = http:HTTP_1_1,
    retryConfig = {
    interval: 3,
    count: 3,
    backOffFactor: 0.5
},
    timeout = 2
);

final http:Client internalErrorEP = check new ("http://localhost:" + retryFunctionTestPort2.toString(),
    httpVersion = http:HTTP_1_1,
    retryConfig = {
    interval: 3,
    count: 3,
    backOffFactor: 2.0,
    maxWaitInterval: 20,
    statusCodes: [501, 502, 503]
},
    timeout = 2
);

service /retryDemoService on retryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function 'default .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->forward("/mockHelloService", request);
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function get .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->execute("GET", "/mockHelloService", request);
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function head .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->head("/mockHelloService");
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function put .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->put("/mockHelloService", request);
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function patch .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->patch("/mockHelloService", request);
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function options .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->options("/mockHelloService");
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function delete .(http:Caller caller, http:Request request) {
        http:Response|error backendResponse = retryBackendClientEP->delete("/mockHelloService", request);
        if backendResponse is http:Response {
            error? responseToCaller = caller->respond(backendResponse);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }
}

int retryCount = 0;
int httpGetRetryCount = 0;
int httpHeadRetryCount = 0;
int httpPutRetryCount = 0;
int httpPatchRetryCount = 0;
int httpDeleteRetryCount = 0;
int httpOptionsRetryCount = 0;

// This sample service is used to mock connection timeouts and service outages.
// The service outage is mocked by stopping/starting this service.
// This should run separately from the `retryDemoService` service.
service /mockHelloService on retryTestserviceEndpoint1 {
    resource function 'default .(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            retryCounter += 1;
            count = retryCounter;
        }
        if (count % 4 != 0) {
            // log:printInfo("Request received from the client to delayed service.");
            // Delay the response by 5000 milliseconds to
            // mimic network level delays.
            runtime:sleep(5);
            http:Response res = new;
            res.setPayload("Hello World!!!");
            error? result = caller->respond(res);

            if result is error {
                // log:printError("Error sending response from mock service", 'error = result);
            }
        } else {
            // log:printInfo("Request received from the client to healthy service.");
            http:Response response = new;
            if (req.hasHeader(mime:CONTENT_TYPE)
                && req.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
                var bodyParts = req.getBodyParts();
                if (bodyParts is mime:Entity[]) {
                    foreach var bodyPart in bodyParts {
                        if (bodyPart.hasHeader(mime:CONTENT_TYPE)
                            && bodyPart.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
                            var nestedParts = bodyPart.getBodyParts();
                            if (nestedParts is error) {
                                // log:printError(nestedParts.message());
                                response.setPayload("Error in decoding nested multiparts!");
                                response.statusCode = 500;
                            } else {
                                mime:Entity[] childParts = nestedParts;
                                foreach var childPart in childParts {
                                    // When performing passthrough scenarios, message needs to be built before
                                    // invoking the endpoint to create a message datasource.
                                    byte[]|error childBlobContent = childPart.getByteArray();
                                    if childBlobContent is error {
                                        // log:printError("Error reading payload", 'error = childBlobContent);
                                    }
                                }
                                io:println(bodyPart.getContentType());
                                bodyPart.setBodyParts(childParts, bodyPart.getContentType());
                            }
                        } else {
                            byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
                            if bodyPartBlobContent is error {
                                // log:printError("Error reading payload", 'error = bodyPartBlobContent);
                            }
                        }
                    }
                    response.setBodyParts(bodyParts, req.getContentType());
                } else {
                    // log:printError(bodyParts.message());
                    response.setPayload("Error in decoding multiparts!");
                    response.statusCode = 500;
                }
            } else {
                response.setPayload("Hello World!!!");
            }
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                // log:printError("Error sending response from mock service", 'error = responseToCaller);
            }
        }
    }

    resource function get .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpGetRetryCount += 1;
            count = httpGetRetryCount;
        }
        waitForRetry(count);
        error? responseToCaller = caller->respond("HTTP GET method invocation is successful");
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function head .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpHeadRetryCount += 1;
            count = httpHeadRetryCount;
        }
        waitForRetry(count);
        http:Response res = new;
        res.setHeader("X-Head-Retry-Count", count.toString());
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function put .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpPutRetryCount += 1;
            count = httpPutRetryCount;
        }
        waitForRetry(count);
        http:Response res = new;
        res.setTextPayload("HTTP PUT method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            // log:printError("Error sending response from put mock service", 'error = responseToCaller);
        }
    }

    resource function patch .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpPatchRetryCount += 1;
            count = httpPatchRetryCount;
        }
        waitForRetry(count);
        http:Response res = new;
        res.setTextPayload("HTTP PATCH method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function delete .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpDeleteRetryCount += 1;
            count = httpDeleteRetryCount;
        }
        waitForRetry(count);
        http:Response res = new;
        res.setTextPayload("HTTP DELETE method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function options .(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            httpOptionsRetryCount += 1;
            count = httpOptionsRetryCount;
        }
        waitForRetry(count);
        http:Response res = new;
        res.setHeader("Allow", "OPTIONS, GET, HEAD, POST");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

isolated function waitForRetry(int counter) {
    if (counter % 4 != 0) {
        // log:printInfo("Request received from the client to delayed service.");
        // Delay the response by 5000 milliseconds to
        // mimic network level delays.
        runtime:sleep(5);
    }
}

service /retryStatusService on retryTestserviceEndpoint1 {
    resource function 'default .(http:Caller caller, http:Request request) returns error? {
        if (check request.getHeader("x-retry") == "recover") {
            http:Response|error backendResponse = internalErrorEP->post("/mockStatusCodeService/recover", request);
            if backendResponse is http:Response {
                var responseError = caller->respond(backendResponse);
                if (responseError is error) {
                    // log:printError("Error sending response", 'error = responseError);
                }
            } else {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    // log:printError("Error sending response", 'error = responseError);
                }
            }
        } else if (check request.getHeader("x-retry") == "internalError") {
            http:Response|error backendResponse = internalErrorEP->post("/mockStatusCodeService/internalError", request);
            if backendResponse is http:Response {
                var responseError = caller->respond(backendResponse);
                if (responseError is error) {
                    // log:printError("Error sending response", 'error = responseError);
                }
            } else {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    // log:printError("Error sending response", 'error = responseError);
                }
            }
        }
    }
}

int retryCounter = 0;

service /mockStatusCodeService on retryTestserviceEndpoint2 {
    resource function 'default recover(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            retryCounter = retryCounter + 1;
            count = retryCounter;
        }
        if (count % 4 != 0) {
            http:Response res = new;
            res.statusCode = 502;
            res.setPayload("Gateway Timed out.");
            var responseError = caller->respond(res);
            if (responseError is error) {
                // log:printError("Error sending response from the service", 'error = responseError);
            }
        } else {
            var responseError = caller->respond("Hello World!!!");
            if (responseError is error) {
                // log:printError("Error sending response from the service", 'error = responseError);
            }
        }
    }

    resource function 'default internalError(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = 502;
        res.setPayload("Gateway Timed out.");
        var responseError = caller->respond(res);
        if (responseError is error) {
            // log:printError("Error sending response from the service", 'error = responseError);
        }
    }
}

//Test basic retry functionality
@test:Config {
    groups: ["retryClientTest"]
}
function testSimpleRetry() returns error? {
    json payload = {Name: "Ballerina"};
    http:Response|error response = retryFunctionTestClient->post("/retryDemoService", payload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with HEAD request
@test:Config {
    groups: ["retryClientTest"]
}
function testHeadRequestWithRetries() returns error? {
    http:Response|error response = retryFunctionTestClient->head("/retryDemoService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        string value = "";
        lock {
            value = httpHeadRetryCount.toString();
        }
        common:assertHeaderValue(check response.getHeader("X-Head-Retry-Count"), value);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PUT request
@test:Config {
    groups: ["retryClientTest"]
}
function testPutRequestWithRetries() {
    http:Response|error response = retryFunctionTestClient->put("/retryDemoService", "This is a simple HTTP PUT request");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "HTTP PUT method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PATCH request
@test:Config {
    groups: ["retryClientTest"]
}
function testPatchRequestWithRetries() {
    http:Response|error response = retryFunctionTestClient->patch("/retryDemoService", "This is a simple HTTP PATCH request");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "HTTP PATCH method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with DELETE request
@test:Config {
    groups: ["retryClientTest"]
}
function testDeleteRequestWithRetries() {
    http:Response|error response = retryFunctionTestClient->delete("/retryDemoService", "This is a simple HTTP DELETE request");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "HTTP DELETE method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with OPTIONS request
@test:Config {
    groups: ["retryClientTest"]
}
function testOptionsRequestWithRetries() returns error? {
    http:Response|error response = retryFunctionTestClient->options("/retryDemoService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader("Allow"), "OPTIONS, GET, HEAD, POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test basic retry functionality with Execute
@test:Config {
    groups: ["retryClientTest"]
}
function testExecuteWithRetries() returns error? {
    http:Response|error response = retryFunctionTestClient->execute("GET", "/retryDemoService", new http:Request());
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "HTTP GET method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with multipart requests
@test:Config {
    groups: ["retryClientTest"]
}
function testRetryWithMultiPart() {
    test:assertTrue(externTestMultiPart(retryFunctionTestPort1, "retryDemoService"));
}

//Test retry functionality when request has nested body parts
@test:Config {
    groups: ["retryClientTest"]
}
function testRetryWithNestedMultiPart() {
    test:assertTrue(externTestNestedMultiPart(retryFunctionTestPort1, "retryDemoService"));
}

//Test retry functionality based on HTTP status codes
@test:Config {
    groups: ["retryClientTest"]
}
function testRetryBasedOnHttpStatusCodes() returns error? {
    http:Request req = new;
    req.setHeader("x-retry", "recover");
    req.setJsonPayload({Name: "Ballerina"});
    http:Response|error response = retryFunctionTestClient->post("/retryStatusService", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test continuous 502 response code
@test:Config {
    groups: ["retryClientTest"]
}
function testRetryBasedOnHttpStatusCodesContinuousFailure() returns error? {
    http:Request req = new;
    req.setHeader("x-retry", "internalError");
    req.setJsonPayload({Name: "Ballerina"});
    http:Response|error response = retryFunctionTestClient->post("/retryStatusService", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 502, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Gateway Timed out.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function externTestMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternRetryMultipartTestutil"
} external;

function externTestNestedMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternRetryMultipartTestutil"
} external;
