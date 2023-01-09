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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener resourceFunctionListener = new (resourceFunctionTestPort, httpVersion = http:HTTP_1_1);
final http:Client resourceFunctionTestClient = check new ("http://localhost:" + resourceFunctionTestPort.toString(), httpVersion = http:HTTP_1_1);

service on resourceFunctionListener {

    resource function 'default manualErrorReturn(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello Ballerina!");

        // Manually return error.
        return error("Some random error");
    }

    resource function 'default checkErrorReturn(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        // Check expression returns error.
        int i = check getError();
        response.setTextPayload("i = " + i.toString());
        check caller->respond(response);
        return;
    }

    resource function 'default callerRespondError(http:Caller caller) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello Ballerina!");
        // Responding an error using the caller.
        check caller->respond(getError());
    }

}

isolated function getError() returns error|int {
    return error("Simulated error");
}

//Returning error from a resource function generate 500
@test:Config {}
function testErrorTypeReturnedFromAResourceFunction() returns error? {
    http:Response|error response = resourceFunctionTestClient->get("/manualErrorReturn");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Some random error");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Returning error from a resource function due to 'check' generate 500
@test:Config {}
function testErrorReturnedFromACheckExprInResourceFunction() returns error? {
    http:Response|error response = resourceFunctionTestClient->get("/checkErrorReturn");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Simulated error");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Responding error from caller
@test:Config {}
function testErrorTypeRespondedFromCaller() returns error? {
    http:Response|error response = resourceFunctionTestClient->get("/callerRespondError");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Simulated error");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

