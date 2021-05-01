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

import ballerina/lang.runtime as runtime;
import ballerina/log;
import ballerina/mime;
import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener http2RetryTestserviceEndpoint1 = new(http2RetryFunctionTestPort1, { httpVersion: "2.0" });
listener http:Listener http2RetryTestserviceEndpoint2 = new(http2RetryFunctionTestPort2, { httpVersion: "2.0" });

http:Client http2RetryFunctionTestClient = check new("http://localhost:" + http2RetryFunctionTestPort1.toString(), { httpVersion: "2.0" });

// Define the end point to the call the `mockHelloService`.
http:Client http2RetryBackendClientEP = check new("http://localhost:" + http2RetryFunctionTestPort1.toString(), {
    // Retry configuration options.
    retryConfig: {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    },
    timeout: 2,
    httpVersion: "2.0"
});

http:Client http2InternalErrorEP = check new("http://localhost:" + http2RetryFunctionTestPort2.toString(), {
    retryConfig: {
        interval: 3,
        count: 3,
        backOffFactor: 2.0,
        maxWaitInterval: 20,
        statusCodes: [501, 502, 503]
    },
    timeout: 2,
    httpVersion: "2.0"
});

service /retryDemoService on http2RetryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function 'default .(http:Caller caller, http:Request request) {
        var backendResponse = http2RetryBackendClientEP->forward("/mockHelloService", request);
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
        var backendResponse = http2RetryBackendClientEP->head("/mockHelloService");
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
        var backendResponse = http2RetryBackendClientEP->put("/mockHelloService", request);
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
        var backendResponse = http2RetryBackendClientEP->patch("/mockHelloService", request);
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
        var backendResponse = http2RetryBackendClientEP->options("/mockHelloService");
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
        var backendResponse = http2RetryBackendClientEP->delete("/mockHelloService", request);
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
        var backendResponse = http2RetryBackendClientEP->execute("GET", "/mockHelloService", request);
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

int http2RetryCount = 0;
int http2GetRetryCount = 0;
int http2HeadRetryCount = 0;
int http2PutRetryCount = 0;
int http2PatchRetryCount = 0;
int http2DeleteRetryCount = 0;
int http2OptionsRetryCount = 0;

// This sample service is used to mock connection timeouts and service outages.
// The service outage is mocked by stopping/starting this service.
// This should run separately from the `retryDemoService` service.
service /mockHelloService on http2RetryTestserviceEndpoint1 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http2RetryCount = http2RetryCount + 1;
        if (http2RetryCount % 4 != 0) {
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
        http2GetRetryCount = http2GetRetryCount + 1;
        waitForRetry(http2GetRetryCount);
        http:Response res = new;
        error? responseToCaller = caller->respond("HTTP GET method invocation is successful");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function head .(http:Caller caller, http:Request request) {
        http2HeadRetryCount = http2HeadRetryCount + 1;
        waitForRetry(http2HeadRetryCount);
        http:Response res = new;
        res.setHeader("X-Head-Retry-Count", http2HeadRetryCount.toString());
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function put .(http:Caller caller, http:Request request) {
        http2PutRetryCount = http2PutRetryCount + 1;
        waitForRetry(http2PutRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP PUT method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function patch .(http:Caller caller, http:Request request) {
        http2PatchRetryCount = http2PatchRetryCount + 1;
        waitForRetry(http2PatchRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP PATCH method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function delete .(http:Caller caller, http:Request request) {
        http2DeleteRetryCount = http2DeleteRetryCount + 1;
        waitForRetry(http2DeleteRetryCount);
        http:Response res = new;
        res.setTextPayload("HTTP DELETE method invocation is successful");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function options .(http:Caller caller, http:Request request) {
        http2OptionsRetryCount = http2OptionsRetryCount + 1;
        waitForRetry(http2OptionsRetryCount);
        http:Response res = new;
        res.setHeader("Allow", "OPTIONS, GET, HEAD, POST");
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

service /retryStatusService on http2RetryTestserviceEndpoint1 {
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

int http2RetryCounter = 0;

service /mockStatusCodeService on http2RetryTestserviceEndpoint2 {
    resource function 'default recover(http:Caller caller, http:Request req) {
        http2RetryCounter = http2RetryCounter + 1;
        if (http2RetryCounter % 4 != 0) {
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

//Test basic retry functionality with HTTP2
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2SimpleRetry() {
    json payload = {Name:"Ballerina"};
    var response = http2RetryFunctionTestClient->post("/retryDemoService", payload);
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
    groups: ["http2RetryClientTest"]
}
function testHttp2HeadRequestWithRetries() {
    var response = http2RetryFunctionTestClient->head("/retryDemoService");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader("X-Head-Retry-Count"), http2HeadRetryCount.toString());
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PUT request
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2PutRequestWithRetries() {
    var response = http2RetryFunctionTestClient->put("/retryDemoService", "This is a simple HTTP PUT request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP PUT method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with PATCH request
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2PatchRequestWithRetries() {
    var response = http2RetryFunctionTestClient->patch("/retryDemoService", "This is a simple HTTP PATCH request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP PATCH method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with DELETE request
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2DeleteRequestWithRetries() {
    var response = http2RetryFunctionTestClient->delete("/retryDemoService", "This is a simple HTTP DELETE request");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "HTTP DELETE method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with OPTIONS request
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2OptionsRequestWithRetries() {
    var response = http2RetryFunctionTestClient->options("/retryDemoService");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader("Allow"), "OPTIONS, GET, HEAD, POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test basic retry functionality with Execute
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2ExecuteWithRetries() {
    var response = http2RetryFunctionTestClient->execute("GET", "/retryDemoService", new http:Request());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "HTTP GET method invocation is successful");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality based on HTTP status codes with HTTP2
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2RetryBasedOnHttpStatusCodes() {
    http:Request req = new;
    req.setHeader("x-retry", "recover");
    req.setJsonPayload({Name:"Ballerina"});
    var response = http2RetryFunctionTestClient->post("/retryStatusService", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test continuous 502 response code with HTTP2
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2RetryBasedOnHttpStatusCodesContinuousFailure() {
    http:Request req = new;
    req.setHeader("x-retry", "internalError");
    req.setJsonPayload({Name:"Ballerina"});
    var response = http2RetryFunctionTestClient->post("/retryStatusService", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 502, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Gateway Timed out.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
