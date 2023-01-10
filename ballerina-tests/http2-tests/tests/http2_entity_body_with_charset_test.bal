// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

service /entityService on generalHTTP2Listener {

    resource function post jsonTest(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var payload = request.getJsonPayload();
        if (payload is json) {
            response.setPayload(payload);
        } else {
            response.setPayload(payload.message());
        }
        check caller->respond(response);
    }
}

final http:Client http2EntityClient = check new ("http://localhost:" + http2GeneralPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

// Test addHeader function within a service
@test:Config {
    groups: ["disabledOnWindows"]
}
function http2JsonTest() returns error? {
    string path = "/entityService/jsonTest";
    http:Request request = new;
    request.setHeader("content-type", "application/json");
    request.setPayload({test: "菜鸟驿站"});
    http:Response response = check http2EntityClient->post(path, request);
    common:assertJsonPayload(response.getJsonPayload(), {test: "菜鸟驿站"});
}
