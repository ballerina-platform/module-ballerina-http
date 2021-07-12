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

listener http:Listener multipleClientListener1 = new(multipleClientTestPort1, { httpVersion: "2.0" });
listener http:Listener multipleClientListener2 = new(multipleClientTestPort2, { httpVersion: "2.0" });

http:Client multipleClientTestClient = check new("http://localhost:" + multipleClientTestPort1.toString());

http:Client h2WithPriorKnowledgeClient = check new("http://localhost:" + multipleClientTestPort2.toString(), { httpVersion: "2.0", http2Settings: {
        http2PriorKnowledge: true }, poolConfig: {} });

http:Client h1Client = check new("http://localhost:" + multipleClientTestPort2.toString(), { httpVersion: "1.1", poolConfig: {}});

service /globalClientTest on multipleClientListener1 {

    resource function get h1(http:Caller caller, http:Request req) {
        http:Response|error response = h1Client->post("/backend", "HTTP/1.1 request");
        if (response is http:Response) {
            checkpanic caller->respond(response);
        } else {
            checkpanic caller->respond("Error in client post - HTTP/1.1");
        }
    }

    resource function get h2(http:Caller caller, http:Request req) {
        http:Response|error response = h2WithPriorKnowledgeClient->post("/backend", "HTTP/2 with prior knowledge");
        if (response is http:Response) {
            checkpanic caller->respond(response);
        } else {
            checkpanic caller->respond("Error in client post - HTTP/2");
        }
    }
}

service /backend on multipleClientListener2 {

    resource function post .(http:Caller caller, http:Request req) {
        string outboundResponse = "";
        if (req.hasHeader("connection") && req.hasHeader("upgrade")) {
            string[] connHeaders = checkpanic req.getHeaders("connection");
            outboundResponse = connHeaders[1];
            outboundResponse = outboundResponse + "--" + checkpanic req.getHeader("upgrade");
        } else {
            outboundResponse = "Connection and upgrade headers are not present";
        }
        outboundResponse = outboundResponse + "--" + checkpanic req.getTextPayload() + "--" + req.httpVersion;
        checkpanic caller->respond(outboundResponse);
    }
}

//Test multiple clients with different configurations that are defined in global scope.
@test:Config {}
function testH1Client() {
    http:Response|error response = multipleClientTestClient->get("/globalClientTest/h1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Connection and upgrade headers are not present--HTTP/1.1 request--1.1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testH2Client() {
    http:Response|error response = multipleClientTestClient->get("/globalClientTest/h2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Connection and upgrade headers are not present--HTTP/2 with prior knowledge--2.0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
