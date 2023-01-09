// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener connectionNativeTestPortEP = new (connectionNativeTestPort, httpVersion = http:HTTP_1_1);
final http:Client connectionNativeClient = check new ("http://localhost:" + connectionNativeTestPort.toString(), httpVersion = http:HTTP_1_1);

service /connectionNativeHello on connectionNativeTestPortEP {

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_MOVED_PERMANENTLY_301, ["location1"]);
    }
}

//Test whether the headers and status codes are set correctly
@test:Config {}
function testRedirect() returns error? {
    http:Response|error response = connectionNativeClient->get("/connectionNativeHello/redirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 301, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader("Location"), "location1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
