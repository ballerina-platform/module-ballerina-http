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
import ballerina/log;

type Order record {|
    int id;
    string item;
|};

// The rate-limited service from the `server` package.
final http:Client orderApi = check new ("http://localhost:9095/api");

public function main() returns error? {

    // Without the helper: the built-in retry retries the throttled status, but on its own schedule. It ignores
    // `Retry-After`, so it comes back too early and gives up with a 429.
    scenario("Built-in retryConfig (interval 1s, 3 retries); the server says Retry-After: 4");
    http:Client builtIn = check new ("http://localhost:9095/api", retryConfig = {count: 3, interval: 1, statusCodes: [429]});
    http:Response res = check builtIn->get("/orders/seconds?failures=10&retryAfter=4");
    io:println("result: HTTP ", res.statusCode);

    // With the helper: wrap the call. A 429 or 503 with `Retry-After` in seconds makes it wait that long, then retry.
    scenario("Retry-After in seconds (429, 3s, two failures)");
    Order[] orders = check callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get("/orders/seconds?failures=2&retryAfter=3");
    }).ensureType();
    io:println("result: ", orders);

    // `Retry-After` can also be an HTTP-date, and it is not specific to 429.
    scenario("Retry-After as an HTTP-date (429, about 4s ahead)");
    orders = check callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get("/orders/date?failures=1&delay=4");
    }).ensureType();
    io:println("result: ", orders);

    scenario("Retry-After on a 503");
    orders = check callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get("/orders/maintenance?failures=1&retryAfter=2");
    }).ensureType();
    io:println("result: ", orders);

    // A call that returns the raw `http:Response` uses the other wrapper.
    scenario("Raw http:Response call (429, 2s)");
    res = check callWithRetryAfterResponse(function () returns http:Response|error {
        return orderApi->get("/orders/seconds?failures=1&retryAfter=2");
    });
    io:println("result: HTTP ", res.statusCode);

    // A wait over `maxRetryAfterWait` is not slept through. The call fails fast with a `RateLimitedError`, so the
    // caller can reschedule instead of blocking.
    scenario("Retry-After: 86400 (one day)");
    anydata|error result = callWithRetryAfter(function () returns Order[]|error {
        return orderApi->get("/orders/long");
    });
    if result is RateLimitedError {
        log:printInfo("rate limited, reschedule the work", retryAt = result.detail().retryAt);
    }
}

// Prints a heading and clears the service's counters, so each scenario starts from a clean state.
function scenario(string title) {
    io:println();
    io:println("=== ", title, " ===");
    http:Client|error plain = new ("http://localhost:9095/api");
    if plain is http:Client {
        http:Response|error reset = plain->post("/reset", ());
        if reset is error {
            log:printWarn("could not reset the service", 'error = reset);
        }
    }
}
