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
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client foClientEP = check new ("http://localhost:" + foClientWithoutStatusCodeTestPort1.toString(), httpVersion = http:HTTP_1_1);

final http:FailoverClient foBackendEP = check new (
    httpVersion = http:HTTP_1_1,
    timeout = 5,
    failoverCodes = [],
    interval = 5,
    targets = [
    {url: "http://nonexistentEP/mock1"},
    {url: "http://localhost:" + foClientWithoutStatusCodeTestPort2.toString() + "/echo"},
    {url: "http://localhost:" + foClientWithoutStatusCodeTestPort2.toString() + "/mock"}
]
);

service / on new http:Listener(foClientWithoutStatusCodeTestPort1) {
    resource function 'default fo() returns string|error {
        return foBackendEP->get("/");
    }
}

service / on new http:Listener(foClientWithoutStatusCodeTestPort2) {
    resource function 'default echo() returns string {
        runtime:sleep(30);
        return "echo Resource is invoked";
    }

    resource function 'default mock() returns string {
        return "Mock Resource is Invoked.";
    }
}

@test:Config {}
function testFailoverWithoutStatusCodes() returns error? {
    http:Response|error response = foClientEP->get("/fo");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Mock Resource is Invoked.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
