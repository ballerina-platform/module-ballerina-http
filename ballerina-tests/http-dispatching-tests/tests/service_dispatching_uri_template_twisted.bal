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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener pathParamCheckListener = new (pathParamCheckTestPort, httpVersion = http:HTTP_1_1);
final http:Client pathParamTestClient = check new ("http://localhost:" + pathParamCheckTestPort.toString(), httpVersion = http:HTTP_1_1);

service / on pathParamCheckListener {

    // Case 1: `id` is present in both resource and positioned in a simpleString expression
    resource function get path/[string id]() returns string {
        return "a-" + id;
    }

    resource function get path/[string note]/aa/[string id]() returns string {
        return "b-" + note + " " + id;
    }

    // Case 2: `aaa` and `bbb` are present in both resource and in twisted positions
    resource function get [string aaa]/go/[string bbb]() returns string {
        return "c-" + aaa + " " + bbb;
    }

    resource function get [string bbb]/go/[string aaa]/[string ccc]() returns string {
        return "d-" + aaa + " " + bbb + " " + ccc;
    }

    // Case 3: rest param present along with path param
    resource function get bar/[string bbb]/go/[string... a]() returns string {
        return "e-" + a[0] + " " + bbb;
    }

    // Case 4: rest param has same var as 2nd resource
    resource function get path/[string id]/aa/[string... note]() returns string {
        return "f-" + note[1] + " " + id;
    }
}

@test:Config {}
function testSamePositionNodeWithSamePathTemplates() {
    http:Response|error response = pathParamTestClient->get("/path/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "a-hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSamePositionNodeWithSamePathTemplatesError() {
    http:Response|error response = pathParamTestClient->get("/path/hello/aa/gone");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "b-hello gone");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSameTwistedPathTemplate() {
    http:Response|error response = pathParamTestClient->get("/aa/go/bb");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "c-aa bb");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSameTwistedPathTemplateError() {
    http:Response|error response = pathParamTestClient->get("/foo/go/bar/cc");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "d-bar foo cc");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRestPathParamMatch() {
    http:Response|error response = pathParamTestClient->get("/bar/bb/go/baz");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "e-baz bb");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRestPathParamTwistedMatch() {
    http:Response|error response = pathParamTestClient->get("/path/bb/aa/baz/foo");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "f-foo bb");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
