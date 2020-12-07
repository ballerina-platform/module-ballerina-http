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

import ballerina/java;
import ballerina/log;
import ballerina/mime;
import ballerina/runtime;
import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener retryTestserviceEndpoint1 = new(retryFunctionTestPort1);
listener http:Listener retryTestserviceEndpoint2 = new(retryFunctionTestPort2);
http:Client retryFunctionTestClient = new("http://localhost:" + retryFunctionTestPort1.toString());

// Define the end point to the call the `mockHelloService`.
http:Client retryBackendClientEP = new ("http://localhost:" + retryFunctionTestPort1.toString(), {
    // Retry configuration options.
    retryConfig: {
        intervalInMillis: 3000,
        count: 3,
        backOffFactor: 0.5
    },
    timeoutInMillis: 2000
});

http:Client internalErrorEP = new("http://localhost:" + retryFunctionTestPort2.toString(), {
    retryConfig: {
        intervalInMillis: 3000,
        count: 3,
        backOffFactor: 2.0,
        maxWaitIntervalInMillis: 20000,
        statusCodes: [501, 502, 503]
    },
    timeoutInMillis: 2000
});

@http:ServiceConfig {
    basePath: "/retry"
}
service retryDemoService on retryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/"
    }
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function invokeEndpoint(http:Caller caller, http:Request request) {
        var backendResponse = retryBackendClientEP->forward("/hello", request);
        if (backendResponse is http:Response) {
            var responseToCaller = caller->respond(<@untainted> backendResponse);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else if (backendResponse is error) {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendResponse.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }
}

int retryCount = 0;

// This sample service is used to mock connection timeouts and service outages.
// The service outage is mocked by stopping/starting this service.
// This should run separately from the `retryDemoService` service.
@http:ServiceConfig { basePath: "/hello" }
service mockHelloService on retryTestserviceEndpoint1 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/"
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        retryCount = retryCount + 1;
        if (counter % 4 != 0) {
            log:printInfo(
                "Request received from the client to delayed service.");
            // Delay the response by 5000 milliseconds to
            // mimic network level delays.
            runtime:sleep(5000);
            http:Response res = new;
            res.setPayload("Hello World!!!");
            var result = caller->respond(res);

            if (result is error) {
                log:printError("Error sending response from mock service", result);
            }
        } else {
            log:printInfo("Request received from the client to healthy service.");
            http:Response response = new;
            if (req.hasHeader(mime:CONTENT_TYPE)
                && req.getHeader(mime:CONTENT_TYPE).startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
                var bodyParts = req.getBodyParts();
                if (bodyParts is mime:Entity[]) {
                    foreach var bodyPart in bodyParts {
                        if (bodyPart.hasHeader(mime:CONTENT_TYPE)
                            && bodyPart.getHeader(mime:CONTENT_TYPE).startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
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
                                    var childBlobContent = childPart.getByteArray();
                                }
                                io:println(bodyPart.getContentType());
                                bodyPart.setBodyParts(<@untainted> childParts, <@untainted> bodyPart.getContentType());
                            }
                        } else {
                            var bodyPartBlobContent = bodyPart.getByteArray();
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
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response from mock service", responseToCaller);
            }
        }
    }
}

@http:ServiceConfig {
    basePath: "/retryStatus"
}
service retryStatusService on retryTestserviceEndpoint1 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/"
    }
    resource function invokeEndpoint(http:Caller caller, http:Request request) {
        if (request.getHeader("x-retry") == "recover") {
            var backendResponse = internalErrorEP->get("/status/recover", <@untainted> request);
            if (backendResponse is http:Response) {
                var responseError = caller->respond(<@untainted> backendResponse);
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
            } else if (backendResponse is error) {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(<@untainted> backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
            }
        } else if (request.getHeader("x-retry") == "internalError") {
            var backendResponse = internalErrorEP->get("/status/internalError", <@untainted> request);
            if (backendResponse is http:Response) {
                var responseError = caller->respond(<@untainted> backendResponse);
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
            } else if (backendResponse is error) {
                http:Response errorResponse = new;
                errorResponse.statusCode = 500;
                errorResponse.setPayload(<@untainted> backendResponse.message());
                var responseError = caller->respond(errorResponse);
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
            }
        }
    }
}

int retryCounter = 0;

@http:ServiceConfig { basePath: "/status" }
service mockStatusCodeService on retryTestserviceEndpoint2 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/recover"
    }
    resource function recoverableResource(http:Caller caller, http:Request req) {
        retryCounter = retryCounter + 1;
        if (retryCounter % 4 != 0) {
            http:Response res = new;
            res.statusCode = 502;
            res.setPayload("Gateway Timed out.");
            var responseError = caller->respond(res);
            if (responseError is error) {
                log:printError("Error sending response from the service", responseError);
            }
        } else {
            var responseError = caller->respond("Hello World!!!");
            if (responseError is error) {
                log:printError("Error sending response from the service", responseError);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/internalError"
    }
    resource function unRecoverableResource(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = 502;
        res.setPayload("Gateway Timed out.");
        var responseError = caller->respond(res);
        if (responseError is error) {
            log:printError("Error sending response from the service", responseError);
        }
    }
}


//Test basic retry functionality
@test:Config {}
function testSimpleRetry() {
    json payload = {Name:"Ballerina"};
    var response = retryFunctionTestClient->post("/retry", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test retry functionality with multipart requests
@test:Config {}
function testRetryWithMultiPart() {
    test:assertTrue(externTestMultiPart(retryFunctionTestPort1, "retry"));
}

//Test retry functionality when request has nested body parts
@test:Config {}
function testRetryWithNestedMultiPart() {
    test:assertTrue(externTestNestedMultiPart(retryFunctionTestPort1, "retry"));
}

//Test retry functionality based on HTTP status codes
@test:Config {}
function testRetryBasedOnHttpStatusCodes() {
    http:Request req = new;
    req.setHeader("x-retry", "recover");
    req.setJsonPayload({Name:"Ballerina"});
    var response = retryFunctionTestClient->post("/retryStatus", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test continuous 502 response code
@test:Config {}
function testRetryBasedOnHttpStatusCodesContinuousFailure() {
    http:Request req = new;
    req.setHeader("x-retry", "internalError");
    req.setJsonPayload({Name:"Ballerina"});
    var response = retryFunctionTestClient->post("/retryStatus", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 502, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Gateway Timed out.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function externTestMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternRetryMultipartTestutil"
} external;

function externTestNestedMultiPart(int servicePort, string path) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternRetryMultipartTestutil"
} external;

