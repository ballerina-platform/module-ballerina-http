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
import ballerina/log;
import ballerina/mime;
import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener retryTestserviceEndpoint1 = new(retryFunctionTestPort1);
listener http:Listener retryTestserviceEndpoint2 = new(retryFunctionTestPort2);
http:Client retryFunctionTestClient = check new("http://localhost:" + retryFunctionTestPort1.toString());

// Define the end point to the call the `mockHelloService`.
http:Client retryBackendClientEP = check new("http://localhost:" + retryFunctionTestPort1.toString(),
    retryConfig= {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    },
    timeout= 2
);

http:Client internalErrorEP = check new("http://localhost:" + retryFunctionTestPort2.toString(), {
    retryConfig: {
        interval: 3,
        count: 3,
        backOffFactor: 2.0,
        maxWaitInterval: 20,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
});

service /retryDemoService on retryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function 'default .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->forward("/mockHelloService", request);
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function get .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->execute("GET", "/mockHelloService", request);
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function head .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->head("/mockHelloService");
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function put .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->put("/mockHelloService", request);
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function patch .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->patch("/mockHelloService", request);
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function options .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->options("/mockHelloService");
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function delete .(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->delete("/mockHelloService", request);
        if (backendResponse is http:Response) {
            error? responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
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
        retryCount = retryCount + 1;
        if (retryCount % 4 != 0) {
            log:printInfo(
                "Request received from the client to delayed service.");
            // Delay the response by 5000 milliseconds to
            // mimic network level delays.
            runtime:sleep(5);
            http:Response res = new;
            res.setPayload("Hello World!!!");
            error? result = caller->respond(res);

            if (result is error) {
                log:printError("Error sending response from mock service", 'error = result);
            }
        } else {
            log:printInfo("Request received from the client to healthy service.");
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
                                log:printError(nestedParts.message());
                                response.setPayload("Error in decoding nested multiparts!");
                                response.statusCode = 500;
                            } else {
                                mime:Entity[] childParts = nestedParts;
                                foreach var childPart in childParts {
                                    // When performing passthrough scenarios, message needs to be built before
                                    // invoking the endpoint to create a message datasource.
                                    byte[]|error childBlobContent = childPart.getByteArray();
                                }
                                io:println(bodyPart.getContentType());
                                bodyPart.setBodyParts(<@untainted> childParts, <@untainted> bodyPart.getContentType());
                            }
                        } else {
                            byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
                        }
                    }
                    response.setBodyParts(<@untainted> bodyParts, <@untainted> req.getContentType());
                } else {
                    log:printError(bodyParts.message());
                    response.setPayload("Error in decoding multiparts!");
                    response.statusCode = 500;
                }
            } else {
                response.setPayload("Hello World!!!");
            }
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response from mock service", 'error = responseToCaller);
            }
        }
    }

    resource function get .(http:Caller caller, http:Request request) {
        httpGetRetryCount = httpGetRetryCount + 1;
        waitForRetry(httpGetRetryCount);
        http:Response res = new;
        error? responseToCaller = caller->respond("HTTP GET method invocation is successful");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function head .(http:Caller caller, http:Request request) {
        httpHeadRetryCount = httpHeadRetryCount + 1;
        waitForRetry(httpHeadRetryCount);
        http:Response res = new;
        res.setHeader("X-Head-Retry-Count", httpHeadRetryCount.toString());
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function put .(http:Caller caller, http:Request request) {
        httpPutRetryCount = httpPutRetryCount + 1;
        waitForRetry(httpPutRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP PUT method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function patch .(http:Caller caller, http:Request request) {
        httpPatchRetryCount = httpPatchRetryCount + 1;
        waitForRetry(httpPatchRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP PATCH method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function delete .(http:Caller caller, http:Request request) {
        httpDeleteRetryCount = httpDeleteRetryCount + 1;
        waitForRetry(httpDeleteRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP DELETE method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function options .(http:Caller caller, http:Request request) {
        httpOptionsRetryCount = httpOptionsRetryCount + 1;
        waitForRetry(httpOptionsRetryCount);
        http:Response res = new;
        res.setHeader("Allow", "OPTIONS, GET, HEAD, POST");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

function waitForRetry(int counter) {
    if (counter % 4 != 0) {
        log:printInfo(
            "Request received from the client to delayed service.");
        // Delay the response by 5000 milliseconds to
        // mimic network level delays.
        runtime:sleep(5);
    }
}

service /retryStatusService on retryTestserviceEndpoint1 {
    resource function 'default .(http:Caller caller, http:Request request) {
        if (checkpanic request.getHeader("x-retry") == "recover") {
            var backendResponse = internalErrorEP->post("/mockStatusCodeService/recover", <@untainted> request);
            if (backendResponse is http:Response) {
                var responseError = caller->respond(<@untainted> backendResponse);
                if (responseError is error) {
                    log:printError("Error sending response", 'error = responseError);
                }
            } else {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(<@untainted> backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    log:printError("Error sending response", 'error = responseError);
                }
            }
        } else if (checkpanic request.getHeader("x-retry") == "internalError") {
            var backendResponse = internalErrorEP->post("/mockStatusCodeService/internalError", <@untainted> request);
            if (backendResponse is http:Response) {
                var responseError = caller->respond(<@untainted> backendResponse);
                if (responseError is error) {
                    log:printError("Error sending response", 'error = responseError);
                }
            } else {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(<@untainted> backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    log:printError("Error sending response", 'error = responseError);
                }
            }
        }
    }
}

int retryCounter = 0;

service /mockStatusCodeService on retryTestserviceEndpoint2 {
    resource function 'default recover(http:Caller caller, http:Request req) {
        retryCounter = retryCounter + 1;
        if (retryCounter % 4 != 0) {
            http:Response res = new;
            res.statusCode = 502;
            res.setPayload("Gateway Timed out.");
            var responseError = caller->respond(res);
            if (responseError is error) {
                log:printError("Error sending response from the service", 'error = responseError);
            }
        } else {
            var responseError = caller->respond("Hello World!!!");
            if (responseError is error) {
                log:printError("Error sending response from the service", 'error = responseError);
            }
        }
    }

    resource function 'default internalError(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = 502;
        res.setPayload("Gateway Timed out.");
        var responseError = caller->respond(res);
        if (responseError is error) {
            log:printError("Error sending response from the service", 'error = responseError);
        }
    }
}


//Test basic retry functionality
@test:Config {
    groups: ["retryClientTest"]
}
function testSimpleRetry() {
    json payload = {Name:"Ballerina"};
    var response = retryFunctionTestClient->post("/retryDemoService", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with HEAD request
@test:Config {
    groups: ["retryClientTest"]
}
function testHeadRequestWithRetries() {
    var response = retryFunctionTestClient->head("/retryDemoService");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader("X-Head-Retry-Count"), httpHeadRetryCount.toString());
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PUT request
@test:Config {
    groups: ["retryClientTest"]
}
function testPutRequestWithRetries() {
    var response = retryFunctionTestClient->put("/retryDemoService", "This is a simple HTTP PUT request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP PUT method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PATCH request
@test:Config {
    groups: ["retryClientTest"]
}
function testPatchRequestWithRetries() {
    var response = retryFunctionTestClient->patch("/retryDemoService", "This is a simple HTTP PATCH request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP PATCH method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with DELETE request
@test:Config {
    groups: ["retryClientTest"]
}
function testDeleteRequestWithRetries() {
    var response = retryFunctionTestClient->delete("/retryDemoService", "This is a simple HTTP DELETE request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP DELETE method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with OPTIONS request
@test:Config {
    groups: ["retryClientTest"]
}
function testOptionsRequestWithRetries() {
    var response = retryFunctionTestClient->options("/retryDemoService");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader("Allow"), "OPTIONS, GET, HEAD, POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test basic retry functionality with Execute
@test:Config {
    groups: ["retryClientTest"]
}
function testExecuteWithRetries() {
    var response = retryFunctionTestClient->execute("GET", "/retryDemoService", new http:Request());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "HTTP GET method invocation is successful");
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
function testRetryBasedOnHttpStatusCodes() {
    http:Request req = new;
    req.setHeader("x-retry", "recover");
    req.setJsonPayload({Name:"Ballerina"});
    var response = retryFunctionTestClient->post("/retryStatusService", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test continuous 502 response code
@test:Config {
    groups: ["retryClientTest"]
}
function testRetryBasedOnHttpStatusCodesContinuousFailure() {
    http:Request req = new;
    req.setHeader("x-retry", "internalError");
    req.setJsonPayload({Name:"Ballerina"});
    var response = retryFunctionTestClient->post("/retryStatusService", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 502, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Gateway Timed out.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function externTestMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternRetryMultipartTestutil"
} external;

function externTestNestedMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternRetryMultipartTestutil"
} external;

