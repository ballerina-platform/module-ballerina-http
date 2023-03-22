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

int contentLengthListenerPort = common:getHttp2Port(http2ContentLengthHeaderTestPort);
http:Client contentLengthHttpClient = check new("http://localhost:" + contentLengthListenerPort.toString());

service /http2Headers on new http:Listener(contentLengthListenerPort) {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        string contLengthHeader = check req.getHeader(http:CONTENT_LENGTH);
        check caller->respond(contLengthHeader);
    }

    resource function post .(http:Caller caller, http:Request req) returns error? {
        string contLengthHeader = check req.getHeader(http:CONTENT_LENGTH);
        check caller->respond(contLengthHeader);
    }

    resource function delete .(http:Caller caller, http:Request req) returns error? {
        string contLengthHeader = check req.getHeader(http:CONTENT_LENGTH);
        check caller->respond(contLengthHeader);
    }
}

@test:Config {}
public function testContentLengthForGet() returns error? {
    http:Response response = check contentLengthHttpClient->get("/http2Headers");
    test:assertEquals(response.getTextPayload(), "0");
    test:assertEquals(response.getHeader(http:CONTENT_LENGTH), "1");
}

@test:Config {}
public function testContentLengthForPost() returns error? {
    json payload = {"details": {"class": "12","where": {"address": "221B"},"age": 54}};
    http:Response response = check contentLengthHttpClient->post("/http2Headers", payload, {"Content-Type": "application/json"});
    test:assertEquals(response.getTextPayload(), "64");
    test:assertEquals(response.getHeader(http:CONTENT_LENGTH), "2");
}

@test:Config {}
public function testContentLengthForDelete() returns error? {
    json payload = {"details": {"class": "12","where": {"address": "221B"},"age": 54}};
    http:Response response = check contentLengthHttpClient->delete("/http2Headers", payload, {"Content-Type": "application/json"});
    test:assertEquals(response.getTextPayload(), "64");
    test:assertEquals(response.getHeader(http:CONTENT_LENGTH), "2");
}
