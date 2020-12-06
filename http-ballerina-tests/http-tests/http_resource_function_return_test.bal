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

listener http:Listener resourceFunctionListener = new(resourceFunctionTestPort);
http:Client resourceFunctionTestClient = new("http://localhost:" + resourceFunctionTestPort.toString());

@http:ServiceConfig {
    basePath:"/"
}
service resourceReturnService on resourceFunctionListener {

    resource function manualErrorReturn(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello Ballerina!");

        // Manually return error.
        if (1 == 1) {
            error e = error("Some random error");
            return e;
        }
        checkpanic caller->respond(response);
        return;
    }

    resource function checkErrorReturn(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        // Check expression returns error.
        int i = check getError();
        response.setTextPayload("i = " + i.toString());
        checkpanic caller->respond(response);
        return;
    }

}

function getError() returns error|int {
    if (1 == 1) {
        error e = error("Simulated error");
        return e;
    }
    return 1;
}

//Returning error from a resource function generate 500
@test:Config {}
function testErrorTypeReturnedFromAResourceFunction() {
    var response = resourceFunctionTestClient->get("/manualErrorReturn");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "some random error");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Returning error from a resource function due to 'check' generate 500
@test:Config {}
function testErrorReturnedFromACheckExprInResourceFunction() {
    var response = resourceFunctionTestClient->get("/checkErrorReturn");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "simulated error");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

