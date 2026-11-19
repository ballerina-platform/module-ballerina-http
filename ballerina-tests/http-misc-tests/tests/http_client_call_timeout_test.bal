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

const int callTimeoutTestPort = 9770;
final string callTimeoutUrl = "http://localhost:" + callTimeoutTestPort.toString();

listener http:Listener callTimeoutListener = new (callTimeoutTestPort, httpVersion = http:HTTP_1_1);

isolated int callTimeoutFlakyHits = 0;
isolated int callTimeoutRedirectHops = 0;

class CallTimeoutStalledStream {
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

service /callTimeoutBackend on callTimeoutListener {

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
            callTimeoutFlakyHits += 1;
        }
        runtime:sleep(0.3);
        return {body: "unavailable"};
    }

    resource function get hop/[int count]() returns http:Response {
        lock {
            callTimeoutRedirectHops += 1;
        }
        runtime:sleep(0.7);
        http:Response res = new;
        res.statusCode = 302;
        res.setHeader("Location", "/callTimeoutBackend/hop/" + (count + 1).toString());
        return res;
    }

    resource function get stalledBody() returns http:Response {
        http:Response res = new;
        res.setByteStream(new stream<byte[], io:Error?>(new CallTimeoutStalledStream()), "text/plain");
        return res;
    }
}

// The timeout differs per use, so no two clients share a connection pool
function callTimeoutConfig(int id, *http:ClientConfiguration overrides) returns http:ClientConfiguration {
    return {
        httpVersion: http:HTTP_1_1,
        poolConfig: {maxActiveConnections: 1, waitTime: 20},
        timeout: 30d + <decimal>id,
        callTimeout: overrides.callTimeout,
        retryConfig: overrides.retryConfig,
        followRedirects: overrides.followRedirects,
        circuitBreaker: overrides.circuitBreaker
    };
}

function callTimeoutSeconds(time:Utc since) returns decimal {
    return time:utcDiffSeconds(time:utcNow(), since);
}

function callTimeoutDescribe(any|error value) returns string {
    return value is error ? value.toString() : value.toString();
}

function callTimeoutReset() {
    lock {
        callTimeoutFlakyHits = 0;
    }
    lock {
        callTimeoutRedirectHops = 0;
    }
}

// The client's callTimeout ends a call whose response never comes in time, with an error that is not the idle timeout
// error, and the connection is released: the pool allows one connection, so the next call would otherwise wait for it.
@test:Config {groups: ["callTimeout"]}
function callTimeoutCallTimeoutOfTheClientBoundsTheCall() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(5, callTimeout = 1));
    time:Utc startedAt = time:utcNow();
    string|error result = cl->get("/callTimeoutBackend/slow");
    decimal elapsed = callTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(result));
    test:assertFalse(result is http:IdleTimeoutError);
    test:assertTrue(elapsed >= 0.9d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");

    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/callTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(callTimeoutSeconds(startedAt) < 3d, "The connection of the timed out call was not released");
}

@test:Config {groups: ["callTimeout"]}
function callTimeoutWithDeadlineOverridesTheClientDefault() returns error? {
    http:Client unlimited = check new (callTimeoutUrl, callTimeoutConfig(1));
    // The remote method and the resource method of a view with a shorter time both time out
    http:Client shortView = unlimited.withDeadline(1);
    string|error viaRemote = shortView->get("/callTimeoutBackend/delayed");
    test:assertTrue(viaRemote is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(viaRemote));
    string|error viaResource = shortView->/callTimeoutBackend/delayed;
    test:assertTrue(viaResource is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(viaResource));

    runtime:sleep(0.5);
    // The client itself keeps having no limit, and the view does not leak its time into it
    string plain = check unlimited->get("/callTimeoutBackend/delayed");
    test:assertEquals(plain, "delayed");

    // A view with a longer time than the default of the client lets a call through
    http:Client limited = check new (callTimeoutUrl, callTimeoutConfig(6, callTimeout = 1));
    string|error limitedResult = limited->get("/callTimeoutBackend/delayed");
    test:assertTrue(limitedResult is http:CallTimeoutError);
    runtime:sleep(0.5);
    http:Client longerView = limited.withDeadline(10);
    string longer = check longerView->get("/callTimeoutBackend/delayed");
    test:assertEquals(longer, "delayed");
    // And one with 0 removes the limit
    http:Client noneView = limited.withDeadline(0);
    string none = check noneView->get("/callTimeoutBackend/delayed");
    test:assertEquals(none, "delayed");
}

@test:Config {groups: ["callTimeout"]}
function callTimeoutNegativeDeadlineIsRejected() returns error? {
    http:Client|error negative = new (callTimeoutUrl, callTimeout = -1);
    test:assertTrue(negative is error, "A negative callTimeout was accepted");
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(2));
    http:Client|error view = trap cl.withDeadline(-1);
    test:assertTrue(view is error, "A negative deadline was accepted");
}

// The body of a response is read after the response is returned, and its time is still part of the call.
@test:Config {groups: ["callTimeout"]}
function callTimeoutDeadlineCoversTheBodyReadAfterTheResponseIsReturned() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(7, callTimeout = 1.5));
    http:Response res = check cl->get("/callTimeoutBackend/stalledBody");
    time:Utc startedAt = time:utcNow();
    string|error payload = res.getTextPayload();
    decimal elapsed = callTimeoutSeconds(startedAt);
    test:assertTrue(payload is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(payload));
    test:assertTrue(elapsed < 4d, "The body read ended after " + elapsed.toString() + " seconds");

    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/callTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(callTimeoutSeconds(startedAt) < 3d, "The connection of the timed out call was not released");
}

// The retries of a call and the waits between them spend one time, and a call that ran out of it is not retried.
@test:Config {groups: ["callTimeout"]}
function callTimeoutRetriesShareOneDeadline() returns error? {
    callTimeoutReset();
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(8, callTimeout = 2,
        retryConfig = {count: 10, interval: 0.5, statusCodes: [503]}));
    time:Utc startedAt = time:utcNow();
    http:Response|error result = cl->get("/callTimeoutBackend/flaky");
    decimal elapsed = callTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(result));
    test:assertTrue(elapsed >= 1.8d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");
    int hits = 0;
    lock {
        hits = callTimeoutFlakyHits;
    }
    test:assertTrue(hits >= 2 && hits <= 5, "Unexpected number of attempts: " + hits.toString());
}

// The redirects of a call spend one time as well.
@test:Config {groups: ["callTimeout"]}
function callTimeoutRedirectsShareOneDeadline() returns error? {
    callTimeoutReset();
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(9, callTimeout = 2,
        followRedirects = {enabled: true, maxCount: 10}));
    time:Utc startedAt = time:utcNow();
    http:Response|error result = cl->get("/callTimeoutBackend/hop/0");
    decimal elapsed = callTimeoutSeconds(startedAt);
    test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(result));
    test:assertTrue(elapsed >= 1.8d && elapsed < 3.5d, "The call took " + elapsed.toString() + " seconds");
    int hops = 0;
    lock {
        hops = callTimeoutRedirectHops;
    }
    test:assertTrue(hops >= 2 && hops <= 4, "Unexpected number of redirects: " + hops.toString());
}

// Cancelling a submitted request aborts it, releases its connection, and fails the response with its own error.
@test:Config {groups: ["callTimeout"]}
function callTimeoutCancelAbortsTheSubmittedRequest() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(3));
    http:HttpFuture httpFuture = check cl->submit("GET", "/callTimeoutBackend/slow", ());
    time:Utc startedAt = time:utcNow();
    http:ClientError? cancelled = cl->cancel(httpFuture);
    test:assertEquals(cancelled, ());
    http:Response|http:ClientError response = cl->getResponse(httpFuture);
    test:assertTrue(response is http:CallCancelledError, "Expected an http:CallCancelledError but got " + callTimeoutDescribe(response));
    test:assertTrue(callTimeoutSeconds(startedAt) < 2d, "The cancelled call took " + callTimeoutSeconds(startedAt).toString() + " seconds");

    // The connection was released, and the one connection of the pool serves the next call
    // The Ballerina HTTP/2 listener closes the connection when a stream is reset, so the client is given the time to
    // notice it before the connection is used again
    runtime:sleep(0.5);
    startedAt = time:utcNow();
    string fast = check cl->get("/callTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
    test:assertTrue(callTimeoutSeconds(startedAt) < 3d, "The connection of the cancelled call was not released");
}

@test:Config {groups: ["callTimeout"]}
function callTimeoutCancelOfACompletedRequestDoesNothing() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(4));
    http:HttpFuture httpFuture = check cl->submit("GET", "/callTimeoutBackend/fast", ());
    http:Response response = check cl->getResponse(httpFuture);
    test:assertEquals(check response.getTextPayload(), "fast");
    http:ClientError? cancelled = cl->cancel(httpFuture);
    test:assertEquals(cancelled, ());
    string fast = check cl->get("/callTimeoutBackend/fast");
    test:assertEquals(fast, "fast");
}

// A call that ran out of its time is a failure of the remote endpoint to the circuit breaker, which opens.
@test:Config {groups: ["callTimeout"]}
function callTimeoutCircuitBreakerCountsTimedOutCalls() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(10, callTimeout = 0.5, circuitBreaker = {
        rollingWindow: {timeWindow: 60, bucketSize: 20, requestVolumeThreshold: 2},
        failureThreshold: 0.5,
        resetTime: 60,
        statusCodes: [500]
    }));
    foreach int _ in 0 ..< 2 {
        string|error result = cl->get("/callTimeoutBackend/slow");
        test:assertTrue(result is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(result));
    }
    string|error rejected = cl->get("/callTimeoutBackend/fast");
    test:assertTrue(rejected is http:UpstreamServiceUnavailableError,
        "Expected the circuit to be open but got " + callTimeoutDescribe(rejected));
}

// Binding the body to a type reads it as well, and fails with the same error.
@test:Config {groups: ["callTimeout"]}
function callTimeoutDataBindingOfTheBodyFailsWithTheCallTimeoutError() returns error? {
    http:Client cl = check new (callTimeoutUrl, callTimeoutConfig(11, callTimeout = 1.5));
    time:Utc startedAt = time:utcNow();
    string|error payload = cl->get("/callTimeoutBackend/stalledBody");
    decimal elapsed = callTimeoutSeconds(startedAt);
    test:assertTrue(payload is http:CallTimeoutError, "Expected an http:CallTimeoutError but got " + callTimeoutDescribe(payload));
    test:assertTrue(elapsed < 4d, "The call took " + elapsed.toString() + " seconds");
}
