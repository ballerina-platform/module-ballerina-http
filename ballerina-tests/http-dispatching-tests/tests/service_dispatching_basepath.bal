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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener basePathTestEP = new (basePathTestPort, httpVersion = http:HTTP_1_1);
final http:Client basePathTestClient = check new ("http://localhost:" + basePathTestPort.toString(), httpVersion = http:HTTP_1_1);

service http:Service /my/Tes\@tHello/go on basePathTestEP {
    resource function get foo(http:Caller caller) returns error? {
        return caller->respond("special dispatched");
    }
}

service http:Service "/Tes@tHello/go" on basePathTestEP {
    resource function get foo(http:Caller caller) returns error? {
        return caller->respond("string dispatched");
    }
}

service http:Service /myservice/'andversion/a\/b/id on basePathTestEP {
    resource function get .(http:Caller caller) returns error? {
        return caller->respond("service/version/1/1/id");
    }
}

@test:Config {}
public function testBasePathSpecialChars() {
    http:Response|error resp = basePathTestClient->get("/my/Tes%40tHello/go/foo");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "special dispatched");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testBasePathAsString() {
    http:Response|error resp = basePathTestClient->get("/Tes%40tHello/go/foo");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "string dispatched");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testMGWVersionBasePath() {
    http:Response|error resp = basePathTestClient->get("/myservice/andversion/a%2Fb/id");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "service/version/1/1/id");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
