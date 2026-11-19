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

    resource function post body(http:Request req) returns string|error {
        return string `body=${check req.getTextPayload()}`;
    }

    resource function post headersAndBody(http:Request req) returns string|error {
        string trace = check req.getHeader("x-trace");
        return string `${trace}:${check req.getTextPayload()}:${req.getContentType()}`;
    }

    resource function post nested(http:Request req) returns string|error {
        return check flattenParts(check req.getBodyParts());
    }

}

isolated int generatorCloseCount = 0;

function flattenParts(mime:Entity[] parts) returns string|error {
    string result = "";
    foreach mime:Entity part in parts {
        if part.getContentType().startsWith("multipart/") {
            result += "[" + check flattenParts(check part.getBodyParts()) + "]";
        } else {
            result += check part.getText() + "|";
        }
    }
    return result;
}

class ClosableByteGenerator {
    private int count = 0;
    private final boolean failing;
    isolated function init(boolean failing) {
        self.failing = failing;
    }
    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        self.count += 1;
        if self.count == 1 {
            return {value: "abc".toBytes()};
        }
        if self.failing {
            return error io:GenericError("stream source failed");
        }
        return ();
    }
    public isolated function close() returns io:Error? {
        lock {
            generatorCloseCount += 1;
        }
    }
}

isolated map<int> flakyHits = {};

// Fails the first call of every id with 503 and echoes the text of the body parts (or the body) afterwards.
service /flaky on new http:Listener(flakyBackendTestPort, httpVersion = http:HTTP_1_1) {
    resource function post [string id]/echo(http:Request req) returns http:Response|error {
        int hits;
        lock {
            hits = (flakyHits[id] ?: 0) + 1;
            flakyHits[id] = hits;
        }
        http:Response res = new;
        if hits == 1 {
            res.statusCode = 503;
            return res;
        }
        if req.getContentType().startsWith("multipart/") {
            string result = "";
            foreach mime:Entity part in check req.getBodyParts() {
                result += check part.getText();
                result += "|";
            }
            res.setTextPayload(result);
        } else {
            res.setTextPayload(string `body=${check req.getTextPayload()}`);
        }
        return res;
    }

    resource function post redirect(http:Request req) returns http:Response {
        http:Response res = new;
        res.statusCode = 307;
        res.setHeader("Location", "http://localhost:" + flakyBackendTestPort.toString() + "/flaky/redirected/echo");
        return res;
    }
}

isolated string[] proxiedRequestTargets = [];

// Minimal forward proxy: it only records the target of the request it receives.
service / on new http:Listener(fakeProxyTestPort, httpVersion = http:HTTP_1_1) {
    resource function 'default [string... path](http:Request req) returns string {
        lock {
            proxiedRequestTargets.push(req.rawPath);
        }
        return "via proxy";
    }
}

function multipartWithStreamPart() returns http:Request {
    mime:Entity part1 = new;
    part1.setText("part-one");
    mime:Entity part2 = new;
    part2.setByteStream(new stream<byte[], io:Error?>(new SingleChunkByteGenerator()));
    http:Request req = new;
    req.setBodyParts([part1, part2]);
    return req;
}

function streamBodyRequest() returns http:Request {
    http:Request req = new;
    req.setByteStream(new stream<byte[], io:Error?>(new SingleChunkByteGenerator()));
    return req;
}

final string lbMultipartEchoUrl = "http://localhost:" + lbMultipartStreamPartTestPort.toString();
final string flakyUrl = "http://localhost:" + flakyBackendTestPort.toString();
final string deadUrl = "http://localhost:" + unreachableBackendPort.toString();

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceAndFailoverClientUseProxy() returns error? {
    http:ProxyConfig proxy = {host: "localhost", port: fakeProxyTestPort};
    http:LoadBalanceClient lb = check new ({targets: [{url: deadUrl}], proxy, httpVersion: http:HTTP_1_1});
    http:FailoverClient fo = check new ({targets: [{url: deadUrl}], proxy, httpVersion: http:HTTP_1_1});
    http:Response _ = check lb->get("/proxied/lb");
    http:Response _ = check fo->get("/proxied/fo");
    string[] targets;
    lock {
        targets = proxiedRequestTargets.clone();
    }
    test:assertTrue(targets.some(t => t.endsWith("/proxied/lb")), "The load balance request did not reach the proxy");
    test:assertTrue(targets.some(t => t.endsWith("/proxied/fo")), "The failover request did not reach the proxy");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientMultipartStreamPartAfterFailedTarget() returns error? {
    http:FailoverClient fo = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    string res = check fo->post("/lbMultipart/echo", multipartWithStreamPart());
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientMultipartStreamPartAfterFailedTarget() returns error? {
    http:LoadBalanceClient lb = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    string res = check lb->post("/lbMultipart/echo", multipartWithStreamPart());
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientMultipartStreamPartOnSecondAttempt() returns error? {
    http:Client c = check new (flakyUrl, httpVersion = http:HTTP_1_1,
        retryConfig = {count: 2, interval: 0.1, statusCodes: [503]});
    string res = check c->post("/flaky/retry-multipart/echo", multipartWithStreamPart());
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientStreamBodyOnSecondAttempt() returns error? {
    http:Client c = check new (flakyUrl, httpVersion = http:HTTP_1_1,
        retryConfig = {count: 2, interval: 0.1, statusCodes: [503]});
    string res = check c->post("/flaky/retry-body/echo", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientWithRetryMultipartStreamPart() returns error? {
    http:LoadBalanceClient lb = check new ({
        httpVersion: http:HTTP_1_1,
        retryConfig: {count: 1, interval: 0.1},
        targets: [{url: lbMultipartEchoUrl}]
    });
    string res = check lb->post("/lbMultipart/echo", multipartWithStreamPart());
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientWithRetryMultipartStreamPart() returns error? {
    http:FailoverClient fo = check new ({
        httpVersion: http:HTTP_1_1,
        retryConfig: {count: 1, interval: 0.1},
        targets: [{url: lbMultipartEchoUrl}]
    });
    string res = check fo->post("/lbMultipart/echo", multipartWithStreamPart());
    test:assertEquals(res, "part-one|part-two|");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientStreamBody() returns error? {
    http:LoadBalanceClient lb = check new ({httpVersion: http:HTTP_1_1, targets: [{url: lbMultipartEchoUrl}]});
    string res = check lb->post("/lbMultipart/body", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
    http:LoadBalanceClient lbRetry = check new ({
        httpVersion: http:HTTP_1_1,
        retryConfig: {count: 1, interval: 0.1},
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    res = check lbRetry->post("/lbMultipart/body", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientStreamBody() returns error? {
    http:FailoverClient fo = check new ({httpVersion: http:HTTP_1_1, targets: [{url: lbMultipartEchoUrl}]});
    string res = check fo->post("/lbMultipart/body", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
    http:FailoverClient foAfterFailure = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    res = check foAfterFailure->post("/lbMultipart/body", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceAndFailoverClientFailingStreamBody() returns error? {
    http:Request req = new;
    req.setByteStream(new stream<byte[], io:Error?>(new FailingByteGenerator()));
    http:LoadBalanceClient lb = check new ({httpVersion: http:HTTP_1_1, targets: [{url: lbMultipartEchoUrl}]});
    http:Response|http:ClientError lbRes = lb->post("/lbMultipart/body", req);
    test:assertTrue(lbRes is http:ClientError, "A failing stream must fail the load balance call");
    http:Request req2 = new;
    req2.setByteStream(new stream<byte[], io:Error?>(new FailingByteGenerator()));
    http:FailoverClient fo = check new ({httpVersion: http:HTTP_1_1, targets: [{url: lbMultipartEchoUrl}]});
    http:Response|http:ClientError foRes = fo->post("/lbMultipart/body", req2);
    test:assertTrue(foRes is http:ClientError, "A failing stream must fail the failover call");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRedirectWithRetryStreamBody() returns error? {
    http:Client c = check new (flakyUrl, httpVersion = http:HTTP_1_1,
        followRedirects = {enabled: true, allowAuthHeaders: false},
        retryConfig = {count: 2, interval: 0.1, statusCodes: [503]});
    // The call fails once with 503 after the redirect and is retried.
    string res = check c->post("/flaky/redirect", streamBodyRequest());
    test:assertEquals(res, "body=part-two");
}

const string STREAM_READ_ERROR = "Error reading the byte stream of the payload";

function failingStreamRequest() returns http:Request {
    http:Request req = new;
    req.setByteStream(new stream<byte[], io:Error?>(new FailingByteGenerator()));
    return req;
}

// A stream that can be resent is read before the request is sent, so its failure is reported by the client. Without
// a possible resend the stream is not read in advance, so the failure surfaces while the request is being sent.
@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientBuffersOnlyWhenRetriesAreConfigured() {
    http:Client withRetry = checkpanic new (lbMultipartEchoUrl, httpVersion = http:HTTP_1_1, retryConfig = {count: 1});
    http:Response|http:ClientError buffered = withRetry->post("/lbMultipart/body", failingStreamRequest());
    test:assertTrue(buffered is http:ClientError && buffered.message().includes(STREAM_READ_ERROR),
            "The stream should be read before sending when retries are configured");
    http:Client noRetry = checkpanic new (lbMultipartEchoUrl, httpVersion = http:HTTP_1_1, retryConfig = {count: 0});
    http:Response|http:ClientError streamed = noRetry->post("/lbMultipart/body", failingStreamRequest());
    test:assertFalse(streamed is http:ClientError && streamed.message().includes(STREAM_READ_ERROR),
            "The stream should not be read in advance when no retry can happen");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientBuffersOnlyWithMultipleTargets() {
    http:FailoverClient single = checkpanic new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: lbMultipartEchoUrl}]
    });
    http:Response|http:ClientError streamed = single->post("/lbMultipart/body", failingStreamRequest());
    test:assertFalse(streamed is http:ClientError && streamed.message().includes(STREAM_READ_ERROR),
            "A single target request should not be read in advance");
    http:FailoverClient multiple = checkpanic new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: lbMultipartEchoUrl}, {url: deadUrl}]
    });
    http:Response|http:ClientError buffered = multiple->post("/lbMultipart/body", failingStreamRequest());
    test:assertTrue(buffered is http:ClientError && buffered.message().includes(STREAM_READ_ERROR),
            "A request that can fail over should be read in advance");
}

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientBuffersOnlyWithFailoverAndMultipleTargets() {
    http:LoadBalanceClient single = checkpanic new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: lbMultipartEchoUrl}]
    });
    http:Response|http:ClientError streamed = single->post("/lbMultipart/body", failingStreamRequest());
    test:assertFalse(streamed is http:ClientError && streamed.message().includes(STREAM_READ_ERROR),
            "A single target request should not be read in advance");
    http:LoadBalanceClient multiple = checkpanic new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: lbMultipartEchoUrl}, {url: deadUrl}]
    });
    http:Response|http:ClientError buffered = multiple->post("/lbMultipart/body", failingStreamRequest());
    test:assertTrue(buffered is http:ClientError && buffered.message().includes(STREAM_READ_ERROR),
            "A request that can fail over should be read in advance");
}

@test:Config {groups: ["resiliencyGaps"]}
function testBufferedByteStreamIsClosed() returns error? {
    http:Client c = check new (lbMultipartEchoUrl, httpVersion = http:HTTP_1_1, retryConfig = {count: 1});
    int before;
    lock {
        before = generatorCloseCount;
    }
    http:Request req = new;
    req.setByteStream(new stream<byte[], io:Error?>(new ClosableByteGenerator(false)));
    string res = check c->post("/lbMultipart/body", req);
    test:assertEquals(res, "body=abc");
    http:Request failing = new;
    failing.setByteStream(new stream<byte[], io:Error?>(new ClosableByteGenerator(true)));
    http:Response|http:ClientError failed = c->post("/lbMultipart/body", failing);
    test:assertTrue(failed is http:ClientError);
    int after;
    lock {
        after = generatorCloseCount;
    }
    test:assertEquals(after - before, 2, "The streams should be closed after they are read, also on failure");
}

@test:Config {groups: ["resiliencyGaps"]}
function testFailoverClientDeeplyNestedMultipartStreamPart() returns error? {
    mime:Entity inner = new;
    mime:Entity streamPart = new;
    streamPart.setByteStream(new stream<byte[], io:Error?>(new SingleChunkByteGenerator()));
    mime:Entity textPart = new;
    textPart.setText("inner-text");
    inner.setBodyParts([textPart, streamPart]);
    mime:Entity middle = new;
    middle.setBodyParts([inner]);
    mime:Entity top = new;
    top.setText("top-text");
    http:Request req = new;
    req.setBodyParts([top, middle]);
    http:FailoverClient fo = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    string res = check fo->post("/lbMultipart/nested", req);
    test:assertEquals(res, "top-text|[[inner-text|part-two|]]");
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
    string url = "http://localhost:" + unreachableBackendPort.toString();
    // The time a refused connection takes differs between platforms, so measure it instead of assuming it.
    http:Client plainClient = check new (url, httpVersion = http:HTTP_1_1);
    decimal attempt = 0d;
    foreach int i in 0 ..< 2 {
        decimal begin = <decimal>time:monotonicNow();
        http:Response|http:ClientError probe = plainClient->get("/u");
        decimal took = <decimal>time:monotonicNow() - begin;
        test:assertTrue(probe is http:ClientError);
        if took > attempt {
            attempt = took;
        }
    }
    http:Client retryClient = check new (url,
        httpVersion = http:HTTP_1_1, retryConfig = {count: 1, interval: 4, backOffFactor: 1.0});
    decimal startTime = <decimal>time:monotonicNow();
    http:Response|http:ClientError res = retryClient->get("/u");
    decimal elapsed = <decimal>time:monotonicNow() - startTime;
    test:assertTrue(res is http:ClientError);
    // Two attempts and one wait of four seconds. A wait after the last attempt would add four more seconds.
    test:assertTrue(elapsed < 2 * attempt + 6.5d,
            "Unexpected retry duration: " + elapsed.toString() + ", attempt: " + attempt.toString());
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

@test:Config {groups: ["resiliencyGaps"]}
function testLoadBalanceClientSendsPreparedRequestAfterFailedTarget() returns error? {
    http:LoadBalanceClient lb = check new ({
        httpVersion: http:HTTP_1_1,
        targets: [{url: deadUrl}, {url: lbMultipartEchoUrl}]
    });
    http:Request req = streamBodyRequest();
    req.setHeader("x-trace", "t1");
    string res = check lb->post("/lbMultipart/headersAndBody", req);
    test:assertEquals(res, "t1:part-two:application/octet-stream");
}

@test:Config {groups: ["resiliencyGaps"]}
function testRetryClientDoesNotBufferMultipartStreamPartsWithoutRetries() {
    http:Client noRetry = checkpanic new (lbMultipartEchoUrl, httpVersion = http:HTTP_1_1, retryConfig = {count: 0});
    http:Response|http:ClientError streamed = noRetry->post("/lbMultipart/echo", multipartWithFailingStreamPart());
    test:assertFalse(streamed is http:ClientError && streamed.message().includes(STREAM_READ_ERROR),
            "A multipart stream part should not be read in advance when no retry can happen");
    http:Client withRetry = checkpanic new (lbMultipartEchoUrl, httpVersion = http:HTTP_1_1, retryConfig = {count: 1});
    http:Response|http:ClientError buffered = withRetry->post("/lbMultipart/echo", multipartWithFailingStreamPart());
    test:assertTrue(buffered is http:ClientError && buffered.message().includes(STREAM_READ_ERROR),
            "A multipart stream part should be read in advance when a retry can happen");
}

function multipartWithFailingStreamPart() returns http:Request {
    mime:Entity part1 = new;
    part1.setText("part-one");
    mime:Entity part2 = new;
    part2.setByteStream(new stream<byte[], io:Error?>(new FailingByteGenerator()));
    http:Request req = new;
    req.setBodyParts([part1, part2]);
    return req;
}
