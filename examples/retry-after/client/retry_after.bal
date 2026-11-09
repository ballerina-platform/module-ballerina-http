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
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/time;

// Statuses that servers use to throttle a client.
final readonly & int[] THROTTLED_STATUS_CODES = [429, 503];

// The most the integration is willing to wait for one Retry-After, in seconds.
configurable decimal maxRetryAfterWait = 30;

// The most calls to make, including the first one.
configurable int maxAttempts = 4;

# Details of a `RateLimitedError`.
#
# + statusCode - Status code of the throttled response
# + retryAfterSeconds - Seconds the server asked the caller to wait
# + retryAt - Time (RFC 3339, UTC) when a retry is allowed
public type RateLimitedErrorDetail record {|
    int statusCode;
    decimal retryAfterSeconds;
    string retryAt;
|};

# Returned when the server asks for a longer wait than `maxRetryAfterWait`.
public type RateLimitedError distinct error<RateLimitedErrorDetail>;

# Reads a Retry-After value, which is a number of seconds or an HTTP-date.
#
# + value - The header value
# + return - Seconds to wait (0 for a date in the past), or `()` if the value is not valid
isolated function parseRetryAfter(string value) returns decimal? {
    string trimmed = value.trim();
    int|error seconds = int:fromString(trimmed);
    if seconds is int {
        return seconds >= 0 ? <decimal>seconds : ();
    }
    // HTTP-dates end in "GMT", which the email-date parser rejects. "+0000" is the same instant.
    string normalized = trimmed.endsWith("GMT") ? trimmed.substring(0, trimmed.length() - 3) + "+0000" : trimmed;
    time:Civil|error civil = time:civilFromEmailString(normalized);
    if civil is error {
        return;
    }
    time:Utc|error date = time:utcFromCivil(civil);
    if date is error {
        return;
    }
    decimal remaining = time:utcDiffSeconds(date, time:utcNow());
    return remaining > 0d ? remaining : 0d;
}

// Waits for the requested time, or returns a RateLimitedError if it is over the limit.
function waitFor(int statusCode, decimal? retryAfter) returns RateLimitedError? {
    decimal seconds = retryAfter ?: 1d;
    if seconds > maxRetryAfterWait {
        string retryAt = time:utcToString(time:utcAddSeconds(time:utcNow(), seconds));
        log:printWarn("Not retrying, the server asks for a longer wait than allowed",
                statusCode = statusCode, waitSeconds = seconds, maxWaitSeconds = maxRetryAfterWait);
        return error RateLimitedError(string `HTTP ${statusCode}: retry allowed after ${seconds}s`,
                statusCode = statusCode, retryAfterSeconds = seconds, retryAt = retryAt);
    }
    log:printDebug("Waiting before retry", statusCode = statusCode, waitSeconds = seconds);
    runtime:sleep(seconds);
}

# Calls `call` again after the time in Retry-After when the server throttles it. For typed calls
# (connector operations, `client->get(path, targetType)`), where 4xx/5xx responses are errors.
#
# + call - The call to make. It is repeated, so it must be safe to repeat
# + return - The result, the last error when attempts run out, or a `RateLimitedError`
public function callWithRetryAfter(function () returns anydata|error call) returns anydata|error {
    int attempt = 1;
    while true {
        anydata|error result = call();
        if result !is http:ApplicationResponseError || THROTTLED_STATUS_CODES.indexOf(result.detail().statusCode) is ()
                || attempt >= maxAttempts {
            return result;
        }
        decimal? retryAfter = ();
        foreach var [name, values] in result.detail().headers.entries() {
            if name.toLowerAscii() == "retry-after" && values.length() > 0 {
                retryAfter = parseRetryAfter(values[0]);
            }
        }
        RateLimitedError? tooLong = waitFor(result.detail().statusCode, retryAfter);
        if tooLong is RateLimitedError {
            return tooLong;
        }
        attempt += 1;
    }
}

# Same as `callWithRetryAfter`, for calls that return an `http:Response`.
#
# + call - The call to make. It is repeated, so it must be safe to repeat
# + return - The first response that is not throttled, the last response when attempts run out, or a `RateLimitedError`
public function callWithRetryAfterResponse(function () returns http:Response|error call) returns http:Response|error {
    int attempt = 1;
    while true {
        http:Response response = check call();
        if THROTTLED_STATUS_CODES.indexOf(response.statusCode) is () || attempt >= maxAttempts {
            return response;
        }
        string|http:HeaderNotFoundError header = response.getHeader("Retry-After");
        RateLimitedError? tooLong = waitFor(response.statusCode, header is string ? parseRetryAfter(header) : ());
        if tooLong is RateLimitedError {
            return tooLong;
        }
        attempt += 1;
    }
}
