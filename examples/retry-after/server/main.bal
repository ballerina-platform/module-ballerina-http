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

const int PORT = 9095;

isolated map<int> hits = {};

isolated function recordHit(string key) returns int {
    lock {
        int n = (hits[key] ?: 0) + 1;
        hits[key] = n;
        return n;
    }
}

isolated function resetHits() {
    lock {
        hits.removeAll();
    }
}

// HTTP-date (IMF-fixdate) for `seconds` from now, e.g. "Fri, 30 Oct 2026 12:00:05 GMT".
isolated function httpDateIn(int seconds) returns string {
    string date = time:utcToEmailString(time:utcAddSeconds(time:utcNow(), <time:Seconds>seconds));
    return date.endsWith("+0000") ? date.substring(0, date.length() - 5) + "GMT" : date;
}

isolated function tooMany(string key, int status, string retryAfter) returns http:Response {
    int n = recordHit(key);
    http:Response res = new;
    res.statusCode = status;
    res.setHeader("Retry-After", retryAfter);
    res.setHeader("X-Hit", n.toString());
    res.setJsonPayload({message: "slow down", hit: n});
    io:println(string `[server] ${key}: hit #${n} -> HTTP ${status}, Retry-After: ${retryAfter}`);
    return res;
}

isolated function ok(string key) returns http:Response {
    int n = recordHit(key);
    http:Response res = new;
    res.setHeader("X-Hit", n.toString());
    res.setJsonPayload([{id: 1, item: "laptop"}, {id: 2, item: "monitor"}]);
    io:println(string `[server] ${key}: hit #${n} -> HTTP 200`);
    return res;
}

// A service that throttles its callers. Each resource answers `429` or `503` with a `Retry-After` header for the
// first calls and then succeeds.
service /api on new http:Listener(PORT) {

    // Rate limited for the first `failures` calls with `Retry-After: <seconds>`, then 200.
    resource function get orders/seconds(int failures = 2, int retryAfter = 3) returns http:Response {
        return peek("seconds") >= failures ? ok("seconds") : tooMany("seconds", 429, retryAfter.toString());
    }

    // Same, but `Retry-After` is an HTTP-date `delay` seconds from now.
    resource function get orders/date(int failures = 1, int delay = 4) returns http:Response {
        int seen = peek("date");
        return seen >= failures ? ok("date") : tooMany("date", 429, httpDateIn(delay));
    }

    // Always 429 and asks the client to come back after `retryAfter` seconds (default: one day).
    resource function get orders/long(int retryAfter = 86400) returns http:Response {
        return tooMany("long", 429, retryAfter.toString());
    }

    // 503 maintenance window: `Retry-After` for the first `failures` calls, then 200.
    resource function get orders/maintenance(int failures = 1, int retryAfter = 2) returns http:Response {
        int seen = peek("maintenance");
        return seen >= failures ? ok("maintenance") : tooMany("maintenance", 503, retryAfter.toString());
    }

    // Start every scenario from a clean state.
    resource function post reset() returns http:Ok {
        resetHits();
        io:println("[server] --- counters reset ---");
        return http:OK;
    }
}

// Number of calls already made to `key`, without counting this one.
isolated function peek(string key) returns int {
    lock {
        return hits[key] ?: 0;
    }
}
