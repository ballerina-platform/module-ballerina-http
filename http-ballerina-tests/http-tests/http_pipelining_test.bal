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
import ballerina/runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener pipeliningListenerEP1 = new(pipeliningTestPort1);
listener http:Listener pipeliningListenerEP2 = new(pipeliningTestPort2, { timeoutInMillis: 1000 });
listener http:Listener pipeliningListenerEP3 = new(pipeliningTestPort3, { http1Settings: { maxPipelinedRequests: 2 } });

service pipeliningTest on pipeliningListenerEP1 {

    resource function responseOrder(http:Caller caller, http:Request req) {
        http:Response response = new;

        if (req.hasHeader("message-id")) {
            //Request one roughly takes 4 seconds to prepare its response
            if (req.getHeader("message-id") == "request-one") {
                runtime:sleep(4000);
                response.setHeader("message-id", "response-one");
                response.setPayload("Hello1");
            }
            //Request two's response will get ready immediately without any sleep time
            if (req.getHeader("message-id") == "request-two") {
                response.setHeader("message-id", "response-two");
                response.setPayload("Hello2");
            }
            //Request three roughly takes 2 seconds to prepare its response
            if (req.getHeader("message-id") == "request-three") {
                runtime:sleep(2000);
                response.setHeader("message-id", "response-three");
                response.setPayload("Hello3");
            }
        }

        var result = caller->respond(<@untainted> response);
        if (result is error) {
            error err = result;
            log:printError(<string> err.detail()["message"], result);
        }
    }
}

service pipelining on pipeliningListenerEP2 {

    resource function testTimeout(http:Caller caller, http:Request req) {
        http:Response response = new;

        if (req.hasHeader("message-id")) {
            //Request one roughly takes 8 seconds to prepare its response
            if (req.getHeader("message-id") == "request-one") {
                runtime:sleep(8000);
                response.setHeader("message-id", "response-one");
                response.setPayload("Hello1");
            }
            //Request two and three will be ready immediately, but they should't have sent out to the client
            if (req.getHeader("message-id") == "request-two") {
                response.setHeader("message-id", "response-two");
                response.setPayload("Hello2");
            }

            if (req.getHeader("message-id") == "request-three") {
                response.setHeader("message-id", "response-three");
                response.setPayload("Hello3");
            }
        }

        var responseError = caller->respond(response);
        if (responseError is error) {
            log:printError("Pipeline timeout:" + responseError.message(), responseError);
        }
    }
}

service pipeliningLimit on pipeliningListenerEP3 {
    resource function testMaxRequestLimit(http:Caller caller, http:Request req) {
        http:Response response = new;
        //Let the thread sleep for sometime so the requests have enough time to queue up
        runtime:sleep(8000);
        response.setPayload("Pipelined Response");

        var responseError = caller->respond(response);
        if (responseError is error) {
            log:printError("Pipeline limit exceeded:" + responseError.message(), responseError);
        }
    }
}

//Test whether the response order matches the request order when HTTP pipelining is used
@test:Config {}
function testPipelinedResponseOrder() {
    test:assertTrue(externTestPipelinedResponseOrder(pipeliningTestPort1));
}

//Test pipelining with timeout. If the first request's response didn't arrive before the server timeout, client
//shouldn't receive the responses for the subsequent requests
@test:Config {}
function testPipeliningWithTimeout() {
    test:assertTrue(externTestPipeliningWithTimeout(pipeliningTestPort2));
}

//Once the pipelining limit is reached, connection should be closed from the server side
@test:Config {}
function testPipeliningLimit() {
    test:assertTrue(externTestPipeliningLimit(pipeliningTestPort3));
}

function externTestPipelinedResponseOrder(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternPipeliningTestUtil"
} external;

function externTestPipeliningWithTimeout(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternPipeliningTestUtil"
} external;

function externTestPipeliningLimit(int servicePort) returns boolean = @java:Method {
    'class: "org.ballerinalang.net.testutils.ExternPipeliningTestUtil"
} external;
