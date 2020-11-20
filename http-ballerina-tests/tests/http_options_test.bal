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

listener http:Listener httpOptionsListenerEP = new(httpOptionsTestPort);
http:Client httpOptionsClient = new("http://localhost:" + httpOptionsTestPort.toString());

@http:ServiceConfig {
    basePath:"/echoDummy"
}
service httpOptionsEchoDummy on httpOptionsListenerEP {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource function echoDummy (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["OPTIONS"],
        path:"/getOptions"
    }
    resource function echoOptions (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello Options");
        checkpanic caller->respond(res);
    }
}

//Test OPTIONS content length header sample test case
@test:Config {}
function testOptionsContentLengthHeader() {
    http:Request req = new;
    req.setHeader(CONTENT_TYPE, APPLICATION_JSON);
    var response = httpOptionsClient->options("/echoDummy", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "0");
        assertHeaderValue(response.getHeader(ALLOW), "POST, OPTIONS");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test OPTIONS content length header sample test case
@test:Config {}
function testOptionsResourceWithPayload() {
    http:Request req = new;
    req.setHeader(CONTENT_TYPE, APPLICATION_JSON);
    var response = httpOptionsClient->options("/echoDummy/getOptions", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "13");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello Options");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
