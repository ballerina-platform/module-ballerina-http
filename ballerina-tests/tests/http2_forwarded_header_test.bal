// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

service /initiatingService on new http:Listener(9107) {
    resource function get initiatingResource(http:Caller caller, http:Request request) {
        http:Client forwadingClient = checkpanic new("http://localhost:9108",
                                       {forwarded: "enable", httpVersion: "2.0",
                                        http2Settings: { http2PriorKnowledge: true }});
        http:Response|error responseFromForwardBackend = forwadingClient->execute("GET", "/forwardedBackend/forwardedResource", request);
        if (responseFromForwardBackend is http:Response) {
            error? resultSentToClient = caller->respond(responseFromForwardBackend);
        }
    }
}

service /forwardedBackend on new http:Listener(9108, {httpVersion: "2.0"}) {
    resource function get forwardedResource(http:Caller caller, http:Request request) {
        string header = checkpanic request.getHeader("forwarded");
        http:Response response = new();
        response.setHeader("forwarded", header);
        response.setPayload("forward is working");
        error? resultSentToClient = caller->respond(response);
    }
}

@test:Config {}
public function testForwardHeader() {
    http:Client clientEP = checkpanic new("http://localhost:9107");
    http:Response|error resp = clientEP->get("/initiatingService/initiatingResource");
    if (resp is http:Response) {
        assertHeaderValue(checkpanic resp.getHeader("forwarded"), "for=127.0.0.1; by=127.0.0.1; proto=http");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
