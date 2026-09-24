// Copyright (c) 2026 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/jballerina.java;
import ballerina/test;

const CHUNKED_RESPONSE_GROUP = "chunkedResponseLimit";

final http:Client entityBodyLimitChunkedClient = check new ("http://localhost:" + responseLimitsTestPort3.toString(),
    httpVersion = http:HTTP_1_1, responseLimits = {maxEntityBodySize: 1024});

final http:Client entityBodyLimitKeepAliveClient = check new ("http://localhost:" + responseLimitsTestPort4.toString(),
    httpVersion = http:HTTP_1_1, responseLimits = {maxEntityBodySize: 1024});

final http:Client entityBodyLimitRequestClient = check new ("http://localhost:" + requestLimitsTestPort7.toString(),
    httpVersion = http:HTTP_1_1);

listener http:Listener entityBodyLimitBackendEP = new (responseLimitsTestPort4, httpVersion = http:HTTP_1_1);

listener http:Listener entityBodyLimitListenerEP = new (requestLimitsTestPort7, httpVersion = http:HTTP_1_1,
    requestLimits = {maxEntityBodySize: 1000});

service /entityBodyLimit on entityBodyLimitBackendEP {
    resource function get [int size]() returns string => getStringLengthOf(size);
}

service /entityBodyLimit on entityBodyLimitListenerEP {
    resource function post .(@http:Payload string payload) returns int => payload.length();
}

@test:BeforeGroups {value: [CHUNKED_RESPONSE_GROUP]}
function startChunkedServer() returns error? {
    check startChunkedResponseServer(responseLimitsTestPort3);
}

@test:AfterGroups {value: [CHUNKED_RESPONSE_GROUP], alwaysRun: true}
function stopChunkedServer() returns error? {
    check stopChunkedResponseServer(responseLimitsTestPort3);
}

@test:Config {groups: [CHUNKED_RESPONSE_GROUP]}
function testEntityBodyLimitExceededWithManyBufferedChunks() {
    http:Response|error response = entityBodyLimitChunkedClient->get("/chunks/400,400,400");
    if response is http:ClientError {
        test:assertEquals(response.message(),
                "Response max entity body size exceeds: Entity body is larger than 1024 bytes. ");
    } else {
        test:assertFail("Expected the response to be rejected for exceeding the entity body limit");
    }
}

@test:Config {groups: [CHUNKED_RESPONSE_GROUP]}
function testEntityBodyLimitDoesNotStopIdleTimeoutSeeingProgress() returns error? {
    http:Client clientEP = check new ("http://localhost:" + responseLimitsTestPort3.toString(),
        httpVersion = http:HTTP_1_1, timeout = 1, responseLimits = {maxEntityBodySize: 1048576});
    // Six chunks 300 ms apart take longer than the timeout in total, but the connection is never idle for 1 s.
    string payload = check clientEP->get("/chunks/300,300,300,300,300,300?delay=300");
    test:assertEquals(payload.length(), 1800);
}

@test:Config {groups: [CHUNKED_RESPONSE_GROUP]}
function testMalformedResponseFailsTheSameWithEntityBodyLimit() returns error? {
    http:Client cappedClient = check new ("http://localhost:" + responseLimitsTestPort3.toString(),
        httpVersion = http:HTTP_1_1, timeout = 1, responseLimits = {maxEntityBodySize: 1024});
    http:Client uncappedClient = check new ("http://localhost:" + responseLimitsTestPort3.toString(),
        httpVersion = http:HTTP_1_1, timeout = 1);
    test:assertEquals(check getOutcome(cappedClient, "/malformed"), check getOutcome(uncappedClient, "/malformed"));
}

@test:Config {}
function testEntityBodyLimitAppliesToEachResponseOnReusedConnection() returns error? {
    string first = check entityBodyLimitKeepAliveClient->get("/entityBodyLimit/900");
    test:assertEquals(first.length(), 900);
    string second = check entityBodyLimitKeepAliveClient->get("/entityBodyLimit/200");
    test:assertEquals(second.length(), 200);
}

@test:Config {}
function testEntityBodyLimitAppliesToEachRequestOnKeepAliveConnection() returns error? {
    foreach int i in 0 ..< 2 {
        http:Response response = check entityBodyLimitRequestClient->post("/entityBodyLimit", getStringLengthOf(600));
        test:assertEquals(response.statusCode, 201);
        test:assertEquals(check response.getTextPayload(), "600");
    }
}

function getOutcome(http:Client clientEP, string path) returns string|error {
    http:Response|error response = clientEP->get(path);
    if response is error {
        return response.message();
    }
    string|error payload = response.getTextPayload();
    return response.statusCode.toString() + " " + (payload is error ? payload.message() : payload);
}

function startChunkedResponseServer(int port) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternChunkedResponseTestUtil"
} external;

function stopChunkedResponseServer(int port) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternChunkedResponseTestUtil"
} external;
