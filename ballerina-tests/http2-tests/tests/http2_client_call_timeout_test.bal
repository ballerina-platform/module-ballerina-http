// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/time;

const int http2CallTimeoutTestPort = 9771;
final string http2CallTimeoutUrl = "http://localhost:" + http2CallTimeoutTestPort.toString();

listener http:Listener http2CallTimeoutListener = new (http2CallTimeoutTestPort);

isolated int http2CallTimeoutFlakyHits = 0;
isolated int http2CallTimeoutRedirectHops = 0;

class Http2CallTimeoutStalledStream {
    private boolean sent = false;

    public isolated function next() returns record {|byte[] value;|}|io:Error? {
        lock {
            if !self.sent {
                self.sent = true;
                byte[] chunk = from int _ in 0 ..< 16384 select <byte>97;
                return {value: chunk};
            }
        }
        // The rest of the body never comes within the test
        runtime:sleep(6);
        return;
    }
}

service /http2CallTimeoutBackend on http2CallTimeoutListener {

    resource function get fast() returns string {
        return "fast";
    }

    resource function get delayed() returns string {
        runtime:sleep(1.5);
        return "delayed";
    }

    resource function get slow() returns string {
        runtime:sleep(4);
        return "slow";
    }

    resource function get flaky() returns http:ServiceUnavailable {
        lock {
            http2CallTimeoutFlakyHits += 1;
        }
        runtime:sleep(0.3);
        return {body: "unavailable"};
    }

    resource function get hop/[int count]() returns http:Response {
        lock {
            http2CallTimeoutRedirectHops += 1;
        }
        runtime:sleep(0.7);
        http:Response res = new;
        res.statusCode = 302;
        res.setHeader("Location", "/http2CallTimeoutBackend/hop/" + (count + 1).toString());
        return res;
    }

    resource function get stalledBody() returns http:Response {
        http:Response res = new;
        res.setByteStream(new stream<byte[], io:Error?>(new Http2CallTimeoutStalledStream()), "text/plain");
        return res;
    }
}

// The timeout differs per use, so no two clients share a connection pool
function http2CallTimeoutConfig(int id, *http:ClientConfiguration overrides) returns http:ClientConfiguration {
    return {
        http2Settings: {http2PriorKnowledge: true},
        timeout: 30d + <decimal>id,
        callTimeout: overrides.callTimeout,
        retryConfig: overrides.retryConfig,
        followRedirects: overrides.followRedirects,
        circuitBreaker: overrides.circuitBreaker
    };
}

function http2CallTimeoutSeconds(time:Utc since) returns decimal {
    return time:utcDiffSeconds(time:utcNow(), since);
}

function http2CallTimeoutDescribe(any|error value) returns string {
    return value is error ? value.message() : value.toString();
}

function http2CallTimeoutReset() {
    lock {
        http2CallTimeoutFlakyHits = 0;
    }
    lock {
        http2CallTimeoutRedirectHops = 0;
    }
}

// The client's callTimeout ends a call whose response never comes in time, with an error that is not the idle timeout
// error, and the connection is released: the pool allows one connection, so the next call would otherwise wait for it.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutCallTimeoutOfTheClientBoundsTheCall() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(5, callTimeout = 1));
    time:Utc startedAt = time:utcNow();
    string|error result = cl->get("/http2CallTimeoutBackend/slow");
    decimal elapsed = http2CallTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(result));
    test:assertFalse(result is http:IdleTimeoutError);
    test:assertTrue(elapsed >= 0.9d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");

    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/http2CallTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(http2CallTimeoutSeconds(startedAt) < 3d, "The connection of the timed out call was not released");
}

@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutWithDeadlineOverridesTheClientDefault() returns error? {
    http:Client unlimited = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(1));
    // The remote method and the resource method of a view with a shorter time both time out
    http:Client shortView = unlimited.withDeadline(1);
    string|error viaRemote = shortView->get("/http2CallTimeoutBackend/delayed");
    test:assertTrue(viaRemote is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(viaRemote));
    string|error viaResource = shortView->/http2CallTimeoutBackend/delayed;
    test:assertTrue(viaResource is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(viaResource));

    runtime:sleep(0.5);
    // The client itself keeps having no limit, and the view does not leak its time into it
    string plain = check unlimited->get("/http2CallTimeoutBackend/delayed");
    test:assertEquals(plain, "delayed");

    // A view with a longer time than the default of the client lets a call through
    http:Client limited = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(6, callTimeout = 1));
    string|error limitedResult = limited->get("/http2CallTimeoutBackend/delayed");
    test:assertTrue(limitedResult is http:CallTimeoutError);
    runtime:sleep(0.5);
    http:Client longerView = limited.withDeadline(10);
    string longer = check longerView->get("/http2CallTimeoutBackend/delayed");
    test:assertEquals(longer, "delayed");
    // And one with 0 removes the limit
    http:Client noneView = limited.withDeadline(0);
    string none = check noneView->get("/http2CallTimeoutBackend/delayed");
    test:assertEquals(none, "delayed");
}

@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutNegativeDeadlineIsRejected() returns error? {
    http:Client|error negative = new (http2CallTimeoutUrl, callTimeout = -1);
    test:assertTrue(negative is error, "A negative callTimeout was accepted");
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(2));
    http:Client|error view = trap cl.withDeadline(-1);
    test:assertTrue(view is error, "A negative deadline was accepted");
}

// The body of a response is read after the response is returned, and its time is still part of the call.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutDeadlineCoversTheBodyReadAfterTheResponseIsReturned() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(7, callTimeout = 1.5));
    http:Response res = check cl->get("/http2CallTimeoutBackend/stalledBody");
    time:Utc startedAt = time:utcNow();
    string|error payload = res.getTextPayload();
    decimal elapsed = http2CallTimeoutSeconds(startedAt);
    test:assertTrue(payload is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(payload));
    test:assertTrue(elapsed < 4d, "The body read ended after " + elapsed.toString() + " seconds");

    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/http2CallTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(http2CallTimeoutSeconds(startedAt) < 3d, "The connection of the timed out call was not released");
}

// The retries of a call and the waits between them spend one time, and a call that ran out of it is not retried.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutRetriesShareOneDeadline() returns error? {
    http2CallTimeoutReset();
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(8, callTimeout = 2,
        retryConfig = {count: 10, interval: 0.5, statusCodes: [503]}));
    time:Utc startedAt = time:utcNow();
    http:Response|error result = cl->get("/http2CallTimeoutBackend/flaky");
    decimal elapsed = http2CallTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(result));
    test:assertTrue(elapsed >= 1.8d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");
    int hits = 0;
    lock {
        hits = http2CallTimeoutFlakyHits;
    }
    test:assertTrue(hits >= 2 && hits <= 5, "Unexpected number of attempts: " + hits.toString());
}

// The redirects of a call spend one time as well.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutRedirectsShareOneDeadline() returns error? {
    http2CallTimeoutReset();
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(9, callTimeout = 2,
        followRedirects = {enabled: true, maxCount: 10}));
    time:Utc startedAt = time:utcNow();
    http:Response|error result = cl->get("/http2CallTimeoutBackend/hop/0");
    decimal elapsed = http2CallTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(result));
    test:assertTrue(elapsed >= 1.8d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");
    int hops = 0;
    lock {
        hops = http2CallTimeoutRedirectHops;
    }
    test:assertTrue(hops >= 2 && hops <= 4, "Unexpected number of redirects: " + hops.toString());
}

// Cancelling a submitted request aborts it, releases its connection, and fails the response with its own error.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutCancelAbortsTheSubmittedRequest() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(3));
    http:HttpFuture httpFuture = check cl->submit("GET", "/http2CallTimeoutBackend/slow", ());
    time:Utc startedAt = time:utcNow();
    http:ClientError? cancelled = cl->cancel(httpFuture);
    test:assertEquals(cancelled, ());
    http:Response|http:ClientError response = cl->getResponse(httpFuture);
    test:assertTrue(response is http:CallCancelledError, "Expected an http:CallCancelledError but got " + http2CallTimeoutDescribe(response));
    test:assertTrue(http2CallTimeoutSeconds(startedAt) < 2d, "The cancelled call took " + http2CallTimeoutSeconds(startedAt).toString() + " seconds");

    // The connection was released, and the one connection of the pool serves the next call
    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/http2CallTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(http2CallTimeoutSeconds(startedAt) < 3d, "The connection of the cancelled call was not released");
}

@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutCancelOfACompletedRequestDoesNothing() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(4));
    http:HttpFuture httpFuture = check cl->submit("GET", "/http2CallTimeoutBackend/fast", ());
    http:Response response = check cl->getResponse(httpFuture);
    test:assertEquals(check response.getTextPayload(), "fast");
    http:ClientError? cancelled = cl->cancel(httpFuture);
    test:assertEquals(cancelled, ());
    string fast = check cl->get("/http2CallTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
}

// A call that ran out of its time is a failure of the remote endpoint to the circuit breaker, which opens.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutCircuitBreakerCountsTimedOutCalls() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(10, callTimeout = 0.5, circuitBreaker = {
        rollingWindow: {timeWindow: 60, bucketSize: 20, requestVolumeThreshold: 2},
        failureThreshold: 0.5,
        resetTime: 60,
        statusCodes: [500]
    }));
    foreach int _ in 0 ..< 2 {
        string|error result = cl->get("/http2CallTimeoutBackend/slow");
        test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(result));
    }
    string|error rejected = cl->get("/http2CallTimeoutBackend/fast");
    test:assertTrue(rejected is http:UpstreamServiceUnavailableError,
        "Expected the circuit to be open but got " + http2CallTimeoutDescribe(rejected));
}

// Binding the body to a type reads it as well, and fails with the same error.
@test:Config {groups: ["callTimeout"]}
function http2CallTimeoutDataBindingOfTheBodyFailsWithTheCallTimeoutError() returns error? {
    http:Client cl = check new (http2CallTimeoutUrl, http2CallTimeoutConfig(11, callTimeout = 1.5));
    time:Utc startedAt = time:utcNow();
    string|error payload = cl->get("/http2CallTimeoutBackend/stalledBody");
    decimal elapsed = http2CallTimeoutSeconds(startedAt);
    test:assertTrue(payload is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + http2CallTimeoutDescribe(payload));
    test:assertTrue(elapsed < 4d, "The call took " + elapsed.toString() + " seconds");
}
