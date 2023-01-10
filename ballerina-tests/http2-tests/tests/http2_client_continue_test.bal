// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener http2ClientContinueListenerEP = check new(http2ClientContinueTestPort);

final http:Client http2ContinueClientWithPriorKnowledge = check new ("http://localhost:" + http2ClientContinueTestPort.toString(), {
    http2Settings: {
        http2PriorKnowledge: true
    }
});

final http:Client http2ContinueClientWithoutPriorKnowledge = check new ("http://localhost:" + http2ClientContinueTestPort.toString());


service /'continue on http2ClientContinueListenerEP {

    resource function 'default .(http:Caller caller, http:Request request) returns error? {
        if request.expects100Continue() {
            check caller->continue();
        }
        string|error payload = request.getTextPayload();
        if payload is string {
            check caller->respond("Hello World!");
        } else {
            check caller->respond(payload);
        }
    }
}

@test:Config {}
function testContinueWithHttp2PriorKnowledge() returns error? {
    http:Request req = new;
    req.addHeader("Expect", "100-continue");
    req.setPayload("Hello World!");
    string responsePayload = check http2ContinueClientWithPriorKnowledge->post("/continue", req);
    test:assertEquals("Hello World!", responsePayload);
}

@test:Config {}
function testContinueForLargePayloadWithHttp2PriorKnowledge() returns error? {
    http:Request req = new;
    req.addHeader("Expect", "100-continue");
    string payload = "";
    int i = 0;
    while (i < 10) {
        payload += largePayload;
        i += 1;
    }
    req.setPayload(payload);
    string responsePayload = check http2ContinueClientWithPriorKnowledge->post("/continue", req);
    test:assertEquals("Hello World!", responsePayload);
}

@test:Config {}
function testContinueWithOutHttp2PriorKnowledge() returns error? {
    http:Request req = new;
    req.addHeader("Expect", "100-continue");
    req.setPayload("Hello World!");
    string responsePayload = check http2ContinueClientWithoutPriorKnowledge->post("/continue", req);
    test:assertEquals("Hello World!", responsePayload);
}

@test:Config {}
function testContinueForLargePayloadWithOutHttp2PriorKnowledge() returns error? {
    http:Request req = new;
    req.addHeader("Expect", "100-continue");
    string payload = "";
    int i = 0;
    while (i < 10) {
        payload += largePayload;
        i += 1;
    }
    req.setPayload(payload);
    string responsePayload = check http2ContinueClientWithoutPriorKnowledge->post("/continue", req);
    test:assertEquals("Hello World!", responsePayload);
}
