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

// import ballerina/log;
import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

listener http:Listener expectContinueListenerEP1 = new(expectContinueTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener expectContinueListenerEP2 = new(expectContinueTestPort2, httpVersion = http:HTTP_1_1);

final http:Client expectContinueClient = check new("http://localhost:" + expectContinueTestPort2.toString(), httpVersion = http:HTTP_1_1);

service /'continue on expectContinueListenerEP1 {

    resource function 'default .(http:Caller caller, http:Request request) {
        if request.expects100Continue() {
            if request.hasHeader("X-Status") {
                // log:printInfo("Sending 100-Continue response");
                var responseError = caller->continue();
                if responseError is error {
                    // log:printError("Error sending response", 'error = responseError);
                }
            } else {
                // log:printInfo("Ignore payload by sending 417 response");
                http:Response res = new;
                res.statusCode = 417;
                res.setPayload("Do not send me any payload");
                var responseError = caller->respond(res);
                if responseError is error {
                    // log:printError("Error sending response", 'error = responseError);
                }
                return;
            }
        }

        http:Response res = new;
        var result  = request.getTextPayload();

        if result is string {
            var responseError = caller->respond(result);
            if responseError is error {
                // log:printError("Error sending response", 'error = responseError);
            }
        } else {
            res.statusCode = 500;
            res.setPayload(result.message());
            // log:printError("Failed to retrieve payload from request: " + result.message());
            var responseError = caller->respond(res);
            if responseError is error {
                // log:printError("Error sending response", 'error = responseError);
            }
        }
    }

    resource function post getFormParam(http:Caller caller, http:Request req) {
        string replyMsg = "Result =";
        var bodyParts = req.getBodyParts();
        if bodyParts is mime:Entity[] {
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                mime:ContentDisposition contentDisposition = part.getContentDisposition();
                var result = part.getText();
                if result is string {
                    replyMsg += " Key:" + contentDisposition.name + " Value: " + result;
                } else {
                    replyMsg += <string> " Key:" + contentDisposition.name + " Value: " + result.message();
                }
                i += 1;
            }
            var responseError = caller->respond(replyMsg);
            if responseError is error {
                // log:printError(responseError.message(), 'error = responseError);
            }
        } else {
            // log:printError(bodyParts.message(), 'error = bodyParts);
        }
    }

    resource function 'default testPassthrough(http:Caller caller, http:Request req) {
        if req.expects100Continue() {
            req.removeHeader("Expect");
            var responseError = caller->continue();
            if responseError is error {
                // log:printError("Error sending response", 'error = responseError);
            }
        }
        http:Response|error res = expectContinueClient->forward("/backend/hello", req);
        if res is http:Response {
            var responseError = caller->respond(res);
            if responseError is error {
                // log:printError("Error sending response", 'error = responseError);
            }
        } else {
            // log:printError(res.message(), 'error = res);
        }
    }
}

service /backend on expectContinueListenerEP2 {
    resource function 'default hello(http:Caller caller, http:Request request) {
        http:Response response = new;
        var payload = request.getTextPayload();
        if payload is string {
            response.setTextPayload(payload);
        } else {
            response.setTextPayload(payload.message());
        }
        var responseError = caller->respond(response);
        if responseError is error {
            // log:printError("Error sending response", 'error = responseError);
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
    'class: "io.ballerina.stdlib.http.testutils.ExternExpectContinueTestUtil"
} external;

function externTest100ContinueNegative(int servicePort) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternExpectContinueTestUtil"
} external;

function externTestMultipartWith100ContinueHeader(int servicePort) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternExpectContinueTestUtil"
} external;

function externTest100ContinuePassthrough(int servicePort) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternExpectContinueTestUtil"
} external;
