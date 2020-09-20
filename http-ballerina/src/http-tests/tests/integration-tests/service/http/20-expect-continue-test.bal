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

import ballerina/log;
import ballerina/java;
import ballerina/mime;
import ballerina/test;
import http;


listener http:Listener expectContinueListenerEP1 = new(expectContinueTestPort1);
listener http:Listener expectContinueListenerEP2 = new(expectContinueTestPort2);

http:Client expectContinueClient = new("http://localhost:" + expectContinueTestPort2.toString());

@http:ServiceConfig {
    basePath: "/continue"
}
service helloContinue on expectContinueListenerEP1 {
    @http:ResourceConfig {
        path: "/"
    }
    resource function hello(http:Caller caller, http:Request request) {
        if (request.expects100Continue()) {
            if (request.hasHeader("X-Status")) {
                log:printInfo("Sending 100-Continue response");
                var responseError = caller->continue();
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
            } else {
                log:printInfo("Ignore payload by sending 417 response");
                http:Response res = new;
                res.statusCode = 417;
                res.setPayload("Do not send me any payload");
                var responseError = caller->respond(res);
                if (responseError is error) {
                    log:printError("Error sending response", responseError);
                }
                return;
            }
        }

        http:Response res = new;
        var result  = request.getTextPayload();

        if (result is string) {
            var responseError = caller->respond(<@untainted> result);
            if (responseError is error) {
                log:printError("Error sending response", responseError);
            }
        } else {
            res.statusCode = 500;
            res.setPayload(<@untainted> result.message());
            log:printError("Failed to retrieve payload from request: " + result.message());
            var responseError = caller->respond(res);
            if (responseError is error) {
                log:printError("Error sending response", responseError);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["POST"]
    }
    resource function getFormParam(http:Caller caller, http:Request req) {
        string replyMsg = "Result =";
        var bodyParts = req.getBodyParts();
        if (bodyParts is mime:Entity[]) {
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                mime:ContentDisposition contentDisposition = part.getContentDisposition();
                var result = part.getText();
                if (result is string) {
                    replyMsg += " Key:" + contentDisposition.name + " Value: " + result;
                } else {
                    replyMsg += <string> " Key:" + contentDisposition.name + " Value: " + result.message();
                }
                i += 1;
            }
            var responseError = caller->respond(<@untainted> replyMsg);
            if (responseError is error) {
                log:printError(responseError.message(), responseError);
            }
        } else {
            log:printError(bodyParts.message(), bodyParts);
        }
    }

    resource function testPassthrough(http:Caller caller, http:Request req) {
        if (req.expects100Continue()) {
            req.removeHeader("Expect");
            var responseError = caller->continue();
            if (responseError is error) {
                log:printError("Error sending response", responseError);
            }
        }
        var res = expectContinueClient->forward("/backend/hello", <@untainted> req);
        if (res is http:Response) {
            var responseError = caller->respond(res);
            if (responseError is error) {
                log:printError("Error sending response", responseError);
            }
        } else {
            log:printError(res.message(), res);
        }
    }
}

service backend on expectContinueListenerEP2 {
    resource function hello(http:Caller caller, http:Request request) {
        http:Response response = new;
        var payload = request.getTextPayload();
        if (payload is string) {
            response.setTextPayload(<@untainted> payload);
        } else {
            response.setTextPayload(<@untainted> payload.message());
        }
        var responseError = caller->respond(response);
        if (responseError is error) {
            log:printError("Error sending response", responseError);
        }
    }
}

//Test 100 continue response and for request with expect:100-continue header
@test:Config {}
function test100Continue() {
    test:assertTrue(externTest100Continue(expectContinueTestPort1));
}

//Test ignoring inbound payload with a 417 response for request with expect:100-continue header
@test:Config {}
function test100ContinueNegative() {
    test:assertTrue(externTest100ContinueNegative(expectContinueTestPort1));
}

//Test multipart form data request with expect:100-continue header
@test:Config {}
function testMultipartWith100ContinueHeader() {
    test:assertTrue(externTestMultipartWith100ContinueHeader(expectContinueTestPort1));
}

@test:Config {}
function test100ContinuePassthrough() {
    test:assertTrue(externTest100ContinuePassthrough(expectContinueTestPort1));
}

function externTest100Continue(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternExpectContinueTestUtil"
} external;

function externTest100ContinueNegative(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternExpectContinueTestUtil"
} external;

function externTestMultipartWith100ContinueHeader(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternExpectContinueTestUtil"
} external;

function externTest100ContinuePassthrough(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternExpectContinueTestUtil"
} external;
