// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

final http:Client clientTest1 = check new ("http://localhost:" + clientForwardTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client clientTest2 = check new ("http://localhost:" + clientForwardTestPort2.toString(), httpVersion = http:HTTP_1_1);

service / on new http:Listener(clientForwardTestPort2, httpVersion = http:HTTP_1_1) {

    resource function get test() returns string {
        return "HelloWorld";
    }
}

service / on new http:Listener(clientForwardTestPort1, httpVersion = http:HTTP_1_1) {

    resource function get test(http:Request req) returns http:Response|error {
        http:Request req_new = new;
        http:Response|error response = clientTest2->forward("/test", req_new);
        return response;
    }
}

@test:Config {}
function testClientForwardRuntimeError() returns error? {
    http:Response|error response = clientTest1->get("/test");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "client method invocation failed: invalid inbound request parameter",
                    "Internal Server Error", 500, "/test", "GET");
    } else {
        test:assertFail("Unexpected output");
    }
}
