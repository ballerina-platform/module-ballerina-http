// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener multipleClientListener1 = new (multipleClientTestPort1);
listener http:Listener multipleClientListener2 = new (multipleClientTestPort2);

final http:Client multipleClientTestClient = check new ("http://localhost:" + multipleClientTestPort1.toString(), httpVersion = http:HTTP_1_1);

final http:Client h2WithPriorKnowledgeClient = check new ("http://localhost:" + multipleClientTestPort2.toString(),
    http2Settings = {http2PriorKnowledge: true}, poolConfig = {});

final http:Client h1Client = check new ("http://localhost:" + multipleClientTestPort2.toString(),
    httpVersion = http:HTTP_1_1, poolConfig = {});

service /globalClientTest on multipleClientListener1 {

    resource function get h1(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = h1Client->post("/backend", "HTTP/1.1 request");
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error in client post - HTTP/1.1");
        }
    }

    resource function get h2(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = h2WithPriorKnowledgeClient->post("/backend", "HTTP/2 with prior knowledge");
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error in client post - HTTP/2");
        }
    }
}

service /backend on multipleClientListener2 {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        string outboundResponse = "";
        if (req.hasHeader("connection") && req.hasHeader("upgrade")) {
            string[] connHeaders = check req.getHeaders("connection");
            outboundResponse = connHeaders[1];
            outboundResponse = outboundResponse + "--" + check req.getHeader("upgrade");
        } else {
            outboundResponse = "Connection and upgrade headers are not present";
        }
        outboundResponse = outboundResponse + "--" + check req.getTextPayload() + "--" + req.httpVersion;
        check caller->respond(outboundResponse);
    }
}

//Test multiple clients with different configurations that are defined in global scope.
@test:Config {}
function testH1Client() returns error? {
    http:Response|error response = multipleClientTestClient->get("/globalClientTest/h1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Connection and upgrade headers are not present--HTTP/1.1 request--1.1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testH2Client() returns error? {
    http:Response|error response = multipleClientTestClient->get("/globalClientTest/h2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Connection and upgrade headers are not present--HTTP/2 with prior knowledge--2.0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
