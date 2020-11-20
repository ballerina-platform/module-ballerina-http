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

listener http:Listener priorEp1 = new(9111, { httpVersion: "2.0" });
listener http:Listener priorEp2 = new(9112, { httpVersion: "2.0" });

http:Client h2WithPriorKnowledge = new("http://localhost:9112", { httpVersion: "2.0", http2Settings: {
                http2PriorKnowledge: true }, poolConfig: {} });

http:Client h2WithoutPriorKnowledge = new("http://localhost:9112", { httpVersion: "2.0", http2Settings: {
                http2PriorKnowledge: false }, poolConfig: {} });

@http:ServiceConfig {
    basePath: "/priorKnowledge"
}
service priorKnowledgeTest on priorEp1 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/on"
    }
    resource function priorOn(http:Caller caller, http:Request req) {
        var response = h2WithPriorKnowledge->post("/backend", "Prior knowledge is enabled");
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            checkpanic caller->respond("Error in client post with prior knowledge on");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/off"
    }
    resource function priorOff(http:Caller caller, http:Request req) {
        var response = h2WithoutPriorKnowledge->post("/backend", "Prior knowledge is disabled");
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            checkpanic caller->respond("Error in client post with prior knowledge off");
        }
    }
}

@http:ServiceConfig {
    basePath: "/backend"
}
service priorKnowledgeTestBackEnd on priorEp2 {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function test(http:Caller caller, http:Request req) {
        string outboundResponse = "";
        if (req.hasHeader(http:CONNECTION) && req.hasHeader(http:UPGRADE)) {
            string[] connHeaders = req.getHeaders(http:CONNECTION);
            outboundResponse = connHeaders[1];
            outboundResponse = outboundResponse + "--" + req.getHeader(http:UPGRADE);
        } else {
            outboundResponse = "Connection and upgrade headers are not present";
        }

        outboundResponse = outboundResponse + "--" + checkpanic req.getTextPayload();
        checkpanic caller->respond(<@untainted> outboundResponse);
    }
}

@test:Config {}
public function testPriorKnowledgeOn() {
    http:Client clientEP = new("http://localhost:9111");
    http:Request req = new;
    var resp = clientEP->get("/priorKnowledge/on");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Connection and upgrade headers are not present--Prior knowledge is enabled");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPriorKnowledgeOff() {
    http:Client clientEP = new("http://localhost:9111");
    var resp = clientEP->get("/priorKnowledge/off");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "HTTP2-Settings,upgrade--h2c--Prior knowledge is disabled");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
