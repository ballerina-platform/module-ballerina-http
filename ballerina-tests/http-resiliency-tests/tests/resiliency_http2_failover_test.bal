// Copyright (c) 2018 WSO2 Inc. (//www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import ballerina/lang.runtime as runtime;
import ballerina/log;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener failoverEP06 = new (9314);

listener http:Listener backendEP06 = new (8094);

final http:FailoverClient foBackendEP06 = check new ({
    timeout: 5,
    failoverCodes: [500, 501, 502, 503],
    interval: 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        {url: "http://localhost:8094/delay"},
        {url: "http://localhost:8094/error"},
        {url: "http://localhost:8094/mock"}
    ]
});

service /failoverDemoService06 on failoverEP06 {

    resource function post index(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP06.getSucceededEndpointIndex().toString();
        var backendRes = foBackendEP06->submit("GET", "/", request);
        if backendRes is http:HttpFuture {
            var response = foBackendEP06->getResponse(backendRes);
            if response is http:Response {
                string responseMessage = "Failover start index is : " + startIndex;
                error? responseToCaller = caller->respond(responseMessage);
                handleResponseToCaller(responseToCaller);
            } else {
                sendErrorResponse(caller, <error>response);
            }
        } else {
            sendErrorResponse(caller, <error>backendRes);
        }
    }
}

// Delayed service to mimic failing service due to network delay.
service /delay on backendEP06 {

    resource function get .(http:Caller caller, http:Request req) {
        // Delay the response for 5000 milliseconds to mimic network level delays.
        runtime:sleep(10);
        error? responseToCaller = caller->respond("Delayed resource is invoked");
        if responseToCaller is error {
            // log:printError("Error sending response from delay service", 'error = responseToCaller);
        }
    }
}

// Error service to mimic internal server error.
service /'error on backendEP06 {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 500;
        response.setPayload("Response from error Service with error status code.");
        error? responseToCaller = caller->respond(response);
        if responseToCaller is error {
            // log:printError("Error sending response from error service", 'error = responseToCaller);
        }
    }
}

// Mock service to mimic healthy service.
service /mock on backendEP06 {

    resource function get .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock Resource is Invoked.");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

function handleResponseToCaller(error? responseToCaller) {
    if responseToCaller is error {
        // log:printError("Error sending response from failover service.", 'error = responseToCaller);
    }
}

function sendErrorResponse(http:Caller caller, error e) {
    http:Response response = new;
    response.statusCode = 500;
    response.setPayload(e.message());
    var respondToCaller = caller->respond(response);
    handleResponseToCaller(respondToCaller);
}

//Test basic failover scenario for HTTP2 clients. //////TODO: #24260
@test:Config {}
function testBasicHttp2Failover() returns error? {
log:printInfo("*********0**********");
    http:Client testClient = check new ("http://localhost:9314");
    log:printInfo("*********011**********");
    http:Response|error response = testClient->post("/failoverDemoService06/index", requestPayload);
    log:printInfo("**********1*********");
    if response is http:Response {
        log:printInfo("*******************");
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        log:printInfo("********6***********");
        common:assertTrueTextPayload(response.getTextPayload(), "Failover start index is : 0");
        log:printInfo("********7***********");
    } else {
        log:printInfo("********2***********");
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
log:printInfo("********5***********");
    response = testClient->post("/failoverDemoService06/index", requestPayload);
    log:printInfo("************3*******");
    if response is http:Response {
        log:printInfo("**********4*********");
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTrueTextPayload(response.getTextPayload(), "Failover start index is : 2");
    } else {
        log:printInfo("********5***********");
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
