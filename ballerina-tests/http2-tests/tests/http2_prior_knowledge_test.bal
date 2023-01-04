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

import ballerina/http;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client h2WithPriorKnowledge = check new ("http://localhost:9101",
    http2Settings = {http2PriorKnowledge: true}, poolConfig = {});

final http:Client h2WithoutPriorKnowledge = check new ("http://localhost:9101",
    http2Settings = {http2PriorKnowledge: false}, poolConfig = {});

service /priorKnowledge on generalHTTP2Listener {

    resource function get 'on(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = h2WithPriorKnowledge->post("/priorKnowledgeTestBackEnd", "Prior knowledge is enabled");
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error in client post with prior knowledge on");
        }
    }

    resource function get off(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = h2WithoutPriorKnowledge->post("/priorKnowledgeTestBackEnd", "Prior knowledge is disabled");
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error in client post with prior knowledge off");
        }
    }
}

service /priorKnowledgeTestBackEnd on HTTP2BackendListener {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        string outboundResponse = "";
        if req.hasHeader(http:CONNECTION) && req.hasHeader(http:UPGRADE) {
            string[] connHeaders = check req.getHeaders(http:CONNECTION);
            outboundResponse = connHeaders[1];
            outboundResponse = outboundResponse + "--" + check req.getHeader(http:UPGRADE);
        } else {
            outboundResponse = "Connection and upgrade headers are not present";
        }

        outboundResponse = outboundResponse + "--" + check req.getTextPayload();
        check caller->respond(outboundResponse);
    }
}

@test:Config {}
public function testPriorKnowledgeOn() returns error? {
    final http:Client clientEP = check new ("http://localhost:9100");
    http:Response|error resp = clientEP->get("/priorKnowledge/on");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Connection and upgrade headers are not present--Prior knowledge is enabled");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testPriorKnowledgeOff() returns error? {
    final http:Client clientEP = check new ("http://localhost:9100");
    http:Response|error resp = clientEP->get("/priorKnowledge/off");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "HTTP2-Settings,upgrade--h2c--Prior knowledge is disabled");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
