// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/io;
import ballerina/mime;
import ballerina/test;
import ballerina/time;

isolated int retryStreamFailureBackendHits = 0;

service /retryStreamFailure on new http:Listener(retryStreamFailureTestPort, httpVersion = http:HTTP_1_1) {
    resource function post upload(http:Request req) returns string {
        lock {
            retryStreamFailureBackendHits += 1;
        }
        byte[]|error payload = req.getBinaryPayload();
        return payload is error ? "read error" : string `backend got ${payload.length()} bytes`;
    }
}

class FailingByteGenerator {
    private int count = 0;
    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        self.count += 1;
        if self.count == 1 {
            return {value: "abc".toBytes()};
        }
        return error io:GenericError("stream source failed");
    }
}

class SingleChunkByteGenerator {
    private boolean done = false;
    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        if self.done {
            return ();
        }
        self.done = true;
        return {value: "part-two".toBytes()};
    }
}

service /lbMultipart on new http:Listener(lbMultipartStreamPartTestPort, httpVersion = http:HTTP_1_1) {
    resource function post echo(http:Request req) returns string|error {
        mime:Entity[] parts = check req.getBodyParts();
        string result = "";
        foreach mime:Entity part in parts {
            result += check part.getText();
            result += "|";
        }
        return result;
    }
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientEmptyTargets() {
    http:LoadBalanceClient|http:ClientError lb = new ({targets: []});
    test:assertTrue(lb is http:ClientError, "LoadBalanceClient init with empty targets should fail");
    http:LoadBalanceClient|http:ClientError lbDefault = new ();
    test:assertTrue(lbDefault is http:ClientError, "LoadBalanceClient init with default targets should fail");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientEmptyTargets() {
    http:FailoverClient|http:ClientError fo = new ({targets: []});
    test:assertTrue(fo is http:ClientError, "FailoverClient init with empty targets should fail");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceAndFailoverClientUseProxy() {
    http:ProxyConfig proxy = {host: "no-such-proxy.invalid", port: 3128};
    http:Client|http:ClientError plain = new ("http://localhost:9", proxy = proxy);
    test:assertTrue(plain is http:ClientError, "Client with an unresolvable proxy should fail");
    http:LoadBalanceClient|http:ClientError lb = new ({targets: [{url: "http://localhost:9"}], proxy});
    test:assertTrue(lb is http:ClientError, "LoadBalanceClient should apply the proxy to its targets");
    http:FailoverClient|http:ClientError fo = new ({targets: [{url: "http://localhost:9"}], proxy});
    test:assertTrue(fo is http:ClientError, "FailoverClient should apply the proxy to its targets");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientFailingRequestStream() returns error? {
    http:Client retryClient = check new ("http://localhost:" + retryStreamFailureTestPort.toString(),
        httpVersion = http:HTTP_1_1, retryConfig = {count: 2, interval: 0.2});
    http:Request req = new;
    req.setByteStream(new stream<byte[], io:Error?>(new FailingByteGenerator()));
    http:Response|http:ClientError res = retryClient->post("/retryStreamFailure/upload", req);
    test:assertTrue(res is http:ClientError, "A failing request stream must fail the call, got: " +
        (res is http:Response ? res.statusCode.toString() + " " + check res.getTextPayload() : ""));
    int hits;
    lock {
        hits = retryStreamFailureBackendHits;
    }
    test:assertEquals(hits, 0, "The backend must not receive a request whose stream failed");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientNoWaitAfterLastAttempt() returns error? {
    http:Client retryClient = check new ("http://localhost:" + unreachableBackendPort.toString(),
        httpVersion = http:HTTP_1_1, retryConfig = {count: 2, interval: 1, backOffFactor: 1.0});
    decimal startTime = <decimal>time:monotonicNow();
    http:Response|http:ClientError res = retryClient->get("/u");
    decimal elapsed = <decimal>time:monotonicNow() - startTime;
    test:assertTrue(res is http:ClientError);
    // Two waits of one second are expected; a third wait after the last attempt would take it past three seconds.
    test:assertTrue(elapsed >= 1.9d && elapsed < 2.7d, "Unexpected retry duration: " + elapsed.toString());
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientMultipartStreamPart() returns error? {
    http:LoadBalanceClient lb = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: "http://localhost:" + lbMultipartStreamPartTestPort.toString()}]
    });
    mime:Entity part1 = new;
    part1.setText("part-one");
    mime:Entity part2 = new;
    part2.setByteStream(new stream<byte[], io:Error?>(new SingleChunkByteGenerator()));
    http:Request req = new;
    req.setBodyParts([part1, part2]);
    string res = check lb->post("/lbMultipart/echo", req);
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testCircuitBreakerInvalidBucketSize() {
    foreach decimal bucketSize in [0d, -1d] {
        http:Client|http:ClientError cb = new ("http://localhost:" + unreachableBackendPort.toString(),
            circuitBreaker = {
                rollingWindow: {timeWindow: 10, bucketSize},
                failureThreshold: 0.5,
                resetTime: 10
            });
        test:assertTrue(cb is http:ClientError, "bucketSize " + bucketSize.toString() + " should be rejected");
    }
}
