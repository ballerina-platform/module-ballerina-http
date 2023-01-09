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

int http2ConnectionNativeTest = common:getHttp2Port(connectionNativeTestPort);

listener http:Listener http2ConnectionNativeTestEP = new (http2ConnectionNativeTest);
final http:Client http2ConnectionNativeClient = check new ("http://localhost:" + http2ConnectionNativeTest.toString(),
    http2Settings = {http2PriorKnowledge: true});

service /connectionNativeHello on http2ConnectionNativeTestEP {

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_MOVED_PERMANENTLY_301, ["location1"]);
    }
}

//Test whether the headers and status codes are set correctly
@test:Config {}
function testHttp2Redirect() returns error? {
    http:Response|error response = http2ConnectionNativeClient->get("/connectionNativeHello/redirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 301, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader("Location"), "location1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
