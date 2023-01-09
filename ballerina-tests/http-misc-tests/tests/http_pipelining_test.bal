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
import ballerina/test;
import ballerina/http;

listener http:Listener pipeliningListenerEP1 = new(pipeliningTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener pipeliningListenerEP2 = new(pipeliningTestPort2, httpVersion = http:HTTP_1_1, timeout = 1);
listener http:Listener pipeliningListenerEP3 = new(pipeliningTestPort3, httpVersion = http:HTTP_1_1, http1Settings = { maxPipelinedRequests: 2 });

service /pipeliningTest on pipeliningListenerEP1 {

    resource function 'default responseOrder(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;

        if req.hasHeader("message-id") {
            //Request one roughly takes 4 seconds to prepare its response
            if check req.getHeader("message-id") == "request-one" {
                runtime:sleep(4);
                response.setHeader("message-id", "response-one");
                response.setPayload("Hello1");
            }
            //Request two's response will get ready immediately without any sleep time
            if check req.getHeader("message-id") == "request-two" {
                response.setHeader("message-id", "response-two");
                response.setPayload("Hello2");
            }
            //Request three roughly takes 2 seconds to prepare its response
            if check req.getHeader("message-id") == "request-three" {
                runtime:sleep(2);
                response.setHeader("message-id", "response-three");
                response.setPayload("Hello3");
            }
        }

        return caller->respond(response);
        // if result is error {
        //     error err = result;
        //     log:printError(err.message(), 'error = result);
        // }
    }
}

service /pipelining on pipeliningListenerEP2 {

    resource function 'default testTimeout(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;

        if req.hasHeader("message-id") {
            //Request one roughly takes 8 seconds to prepare its response
            if check req.getHeader("message-id") == "request-one" {
                runtime:sleep(8);
                response.setHeader("message-id", "response-one");
                response.setPayload("Hello1");
            }
            //Request two and three will be ready immediately, but they should't have sent out to the client
            if check req.getHeader("message-id") == "request-two" {
                response.setHeader("message-id", "response-two");
                response.setPayload("Hello2");
            }

            if check req.getHeader("message-id") == "request-three" {
                response.setHeader("message-id", "response-three");
                response.setPayload("Hello3");
            }
        }

        var responseError = caller->respond(response);
        if responseError is error {
            // log:printError("Pipeline timeout:" + responseError.message(), 'error = responseError);
        }
    }
}

service /pipeliningLimit on pipeliningListenerEP3 {
    
    resource function 'default testMaxRequestLimit(http:Caller caller, http:Request req) {
        http:Response response = new;
        //Let the thread sleep for sometime so the requests have enough time to queue up
        runtime:sleep(8);
        response.setPayload("Pipelined Response");

        var responseError = caller->respond(response);
        if responseError is error {
            // log:printError("Pipeline limit exceeded:" + responseError.message(), 'error = responseError);
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
    'class: "io.ballerina.stdlib.http.testutils.ExternPipeliningTestUtil"
} external;

function externTestPipeliningWithTimeout(int servicePort) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternPipeliningTestUtil"
} external;

function externTestPipeliningLimit(int servicePort) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternPipeliningTestUtil"
} external;
