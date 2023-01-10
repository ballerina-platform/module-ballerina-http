// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;
import ballerina/http_test_common as common;

//Backend pointed by these clients should be down.
final http:Client priorOn = check new ("http://localhost:14555",
    http2Settings = {http2PriorKnowledge: true}, poolConfig = {});

final http:Client priorOff = check new ("http://localhost:14555",
    http2Settings = {http2PriorKnowledge: false}, poolConfig = {});

service /general on generalHTTP2Listener {

    resource function get serverDown(http:Caller caller, http:Request req) returns error? {
        http:Response|error result1 = priorOn->get("/bogusResource");
        http:Response|error result2 = priorOff->get("/bogusResource");
        string response = handleResponse(result1) + "--" + handleResponse(result2);
        check caller->respond(response);
    }
}

isolated function handleResponse(http:Response|error result) returns string {
    if result is http:Response {
        return "Call succeeded";
    } else {
        return "Call to backend failed due to:" + result.message();
    }
}

@test:Config {}
public function testServerDown() returns error? {
    http:Client clientEP = check new ("http://localhost:9100");
    http:Response|error resp = clientEP->get("/general/serverDown");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Call to backend failed due to:Something wrong with the connection--Call to backend " +
                                    "failed due to:Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
