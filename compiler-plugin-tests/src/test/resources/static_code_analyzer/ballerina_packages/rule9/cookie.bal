// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com)
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

// Neither flag set, so both default to false
function defaultCookie() returns http:Cookie {
    return new ("session", "abc123");
}

// The secure flag explicitly switched off
function insecureCookie() returns http:Cookie {
    return new ("session", "abc123", secure = false, httpOnly = true);
}

// Readable from JavaScript, supplied as a positional options record
function scriptReadableCookie() returns http:Cookie {
    return new ("session", "abc123", {
        secure: true,
        httpOnly: false
    });
}

// Only one of the two flags set, so the other still defaults to false
function partiallyConfiguredCookie() returns http:Cookie {
    return new ("session", "abc123", secure = true);
}

// Negative case - both flags set
function secureCookie() returns http:Cookie {
    return new ("session", "abc123", secure = true, httpOnly = true);
}
