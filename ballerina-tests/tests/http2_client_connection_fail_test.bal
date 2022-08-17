// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// under the License.package http2;

import ballerina/http;
import ballerina/test;

http:Client callNonExistingTestClient = check new("http://localhost:" + generalPort.toString());

service /callNonExistingEP on generalListener {
    resource function get .() returns string|error? {
        http:Client callNonExisting = check new("http://localhost:5983/nonExisting");
        string|error response = callNonExisting->get("/");
        if response is error {
            test:assertEquals(response.message(), "Something wrong with the connection");
        } else {
            test:assertFail(msg = "Found unexpected output type: " + response);
        }

        response = callNonExisting->get("/");
        if response is error {
            test:assertEquals(response.message(), "Something wrong with the connection");
        } else {
            test:assertFail(msg = "Found unexpected output type: " + response);
        }
        return "Success";
    }
}

@test:Config {}
public function testCallingNonExistingEPThroughService() returns error? {
    http:Client callNonExistingTestClient = check new("http://localhost:" + generalPort.toString());
    string payload = check callNonExistingTestClient->get("/callNonExistingEP");
    test:assertEquals(payload, "Success", msg = "Found unexpected output");
}

@test:Config {}
function testCallingNonExistingEP() returns error? {
    http:Client callNonExisting = check new("http://localhost:5983/nonExisting");
    string|error response = callNonExisting->get("/");
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response);
    }

    response = callNonExisting->get("/");
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response);
    }
}
