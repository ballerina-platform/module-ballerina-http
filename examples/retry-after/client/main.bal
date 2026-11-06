// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
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
import ballerina/time;

const string BASE_URL = "http://localhost:9095/api";

type Order record {|
    int id;
    string item;
|};

final time:Utc startedAt = time:utcNow();

function say(string message) {
    decimal elapsed = time:utcDiffSeconds(time:utcNow(), startedAt);
    io:println(string `[client +${elapsed.round(1)}s] ${message}`);
}

function banner(string title) {
    io:println();
    io:println(string `=== ${title} ===`);
}

// Starts every scenario from a clean server state.
function reset() returns error? {
    http:Client plain = check new (BASE_URL);
    http:Response _ = check plain->post("/reset", ());
}

// The built-in retry: it retries the throttled status, but on its own schedule and ignoring `Retry-After`.
function builtInRetry() returns error? {
    banner("1. Built-in retryConfig (interval 1s, 3 retries, statusCodes [429]); the server says Retry-After: 4");
    check reset();
    http:Client orderApi = check new (BASE_URL, retryConfig = {count: 3, interval: 1, statusCodes: [429]});
    http:Response res = check orderApi->get("/orders/seconds?failures=10&retryAfter=4");
    say(string `final result: HTTP ${res.statusCode}, all retries used up although the server asked for 4s between calls`);
}

// A typed call (the shape of a connector operation) wrapped with `callWithRetryAfter`.
function typedCall(string title, string path) returns error? {
    banner(title);
    check reset();
    http:Client orderApi = check new (BASE_URL);
    Order[] orders = check callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get(path);
    }).ensureType();
    say(string `final result: ${orders.toString()}`);
}

// A call that returns the raw `http:Response`, wrapped with `callWithRetryAfterResponse`.
function rawCall() returns error? {
    banner("5. Raw http:Response call (429, Retry-After: 2)");
    check reset();
    http:Client orderApi = check new (BASE_URL);
    http:Response res = check callWithRetryAfterResponse(function () returns http:Response|error {
        return orderApi->get("/orders/seconds?failures=1&retryAfter=2");
    });
    say(string `final result: HTTP ${res.statusCode}`);
}

// A very long `Retry-After`: the call fails fast with an error that tells the caller when to come back.
function tooLong() returns error? {
    banner("6. Retry-After: 86400 (one day) -> fail fast and hand back the retry time");
    check reset();
    http:Client orderApi = check new (BASE_URL);
    anydata|error result = callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get("/orders/long");
    });
    if result is RateLimitedError {
        say(string `the caller can reschedule: ${result.message()}; retryAt=${result.detail().retryAt}`);
    } else {
        say(string `unexpected: ${result is error ? result.message() : result.toString()}`);
    }
}

public function main() returns error? {
    check builtInRetry();
    check typedCall("2. 429 with Retry-After in seconds (two failures)", "/orders/seconds?failures=2&retryAfter=3");
    check typedCall("3. 429 with Retry-After as an HTTP-date (about 4s ahead)", "/orders/date?failures=1&delay=4");
    check typedCall("4. 503 with Retry-After in seconds", "/orders/maintenance?failures=1&retryAfter=2");
    check rawCall();
    check tooLong();
}
