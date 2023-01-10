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
import ballerina/http_test_common as common;

listener http:Listener httpOptionsListenerEP = new (httpOptionsTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpOptionsClient = check new ("http://localhost:" + httpOptionsTestPort.toString(), httpVersion = http:HTTP_1_1);

service /echoDummy on httpOptionsListenerEP {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello world");
        check caller->respond(res);
    }

    resource function options getOptions(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello Options");
        check caller->respond(res);
    }
}

//Test OPTIONS content length header sample test case
@test:Config {}
function testOptionsContentLengthHeader() returns error? {
    http:Response|error response = httpOptionsClient->options("/echoDummy", {[common:CONTENT_TYPE] : [common:APPLICATION_JSON]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:ALLOW), "POST, OPTIONS");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test OPTIONS content length header sample test case
@test:Config {}
function testOptionsResourceWithPayload() returns error? {
    http:Response|error response = httpOptionsClient->options("/echoDummy/getOptions", {[common:CONTENT_TYPE] : [common:APPLICATION_JSON]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_LENGTH), "13");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello Options");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
