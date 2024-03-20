// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/lang.'int as ints;
import ballerina/log;
import ballerina/time;

// Returns the cookie object from the string value of the "Set-Cookie" header.
isolated function parseSetCookieHeader(string cookieStringValue) returns Cookie {
    string cookieValue = cookieStringValue;
    string[] result = re`;\s`.split(cookieValue);
    string[] nameValuePair = re`=`.split(result[0]);
    string cookieName = nameValuePair[0];
    string cookieVal = nameValuePair[1];
    CookieOptions options = {};
    foreach var item in result {
        nameValuePair = re`=`.split(item);
        match nameValuePair[0] {
            DOMAIN_ATTRIBUTE => {
                options.domain = nameValuePair[1];
            }
            PATH_ATTRIBUTE => {
                options.path = nameValuePair[1];
            }
            MAX_AGE_ATTRIBUTE => {
                int|error age = ints:fromString(nameValuePair[1]);
                if age is int {
                    options.maxAge = age;
                }
            }
            EXPIRES_ATTRIBUTE => {
                options.expires = nameValuePair[1];
            }
            SECURE_ATTRIBUTE => {
                options.secure = true;
            }
            HTTP_ONLY_ATTRIBUTE => {
                options.httpOnly = true;
            }
        }
    }
    Cookie cookie = new (cookieName, cookieVal, options);
    return cookie;
}

// Returns an array of cookie objects from the string value of the "Cookie" header.
isolated function parseCookieHeader(string cookieStringValue) returns Cookie[] {
    Cookie[] cookiesInRequest = [];
    string cookieValue = cookieStringValue;
    string[] nameValuePairs = re`;\s`.split(cookieValue);
    foreach var item in nameValuePairs {
        if re`^([^=]+)=.*$`.isFullMatch(item) {
            string[] nameValue = re`=`.split(item);
            Cookie cookie;
            if nameValue.length() > 1 {
                cookie = new (nameValue[0], nameValue[1]);
            } else {
                cookie = new (nameValue[0], "");
            }
            cookiesInRequest.push(cookie);
        } else {
            log:printError("Invalid cookie: " + item + ", which must be in the format as [{name}=].");
        }
    }
    return cookiesInRequest;
}

// Returns a value to be used for sorting an array of cookies in order to create the "Cookie" header in the request.
// This value is returned according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.4).
isolated function comparator(Cookie c1, Cookie c2) returns int {
    var cookiePath1 = c1.path;
    var cookiePath2 = c2.path;
    int l1 = 0;
    int l2 = 0;
    if cookiePath1 is string {
        l1 = cookiePath1.length();
    }
    if cookiePath2 is string {
        l2 = cookiePath2.length();
    }
    if l1 != l2 {
        return l2 - l1;
    }
    return <int> time:utcDiffSeconds(c1.createdTime, c2.createdTime);
}

isolated function getClone(Cookie cookie, time:Utc createdTime, time:Utc lastAccessedTime) returns Cookie {
    CookieOptions options = {};
    if cookie.domain is string {
        options.domain = cookie.domain;
    }
    if cookie.path is string {
        options.path = cookie.path;
    }
    if cookie.expires is string {
        options.expires = cookie.expires;
    }
    options.maxAge = cookie.maxAge;
    options.httpOnly = cookie.httpOnly;
    options.secure = cookie.secure;
    options.hostOnly = cookie.hostOnly;
    options.createdTime = createdTime;
    options.lastAccessedTime = lastAccessedTime;
    return new Cookie(cookie.name, cookie.value, options);
}

isolated function getCloneWithExpiresAndMaxAge(Cookie cookie, string expires, int maxAge) returns Cookie {
    CookieOptions options = {};
    if cookie.domain is string {
        options.domain = cookie.domain;
    }
    if cookie.path is string {
        options.path = cookie.path;
    }
    options.expires = expires;
    options.maxAge = maxAge;
    options.httpOnly = cookie.httpOnly;
    options.secure = cookie.secure;
    options.hostOnly = cookie.hostOnly;
    options.createdTime = cookie.createdTime;
    options.lastAccessedTime = cookie.lastAccessedTime;
    return new Cookie(cookie.name, cookie.value, options);
}

isolated function getCloneWithPath(Cookie cookie, string path) returns Cookie {
    CookieOptions options = {};
    if cookie.domain is string {
        options.domain = cookie.domain;
    }
    if cookie.expires is string {
        options.expires = cookie.expires;
    }
    options.path = path;
    options.maxAge = cookie.maxAge;
    options.httpOnly = cookie.httpOnly;
    options.secure = cookie.secure;
    options.hostOnly = cookie.hostOnly;
    options.createdTime = cookie.createdTime;
    options.lastAccessedTime = cookie.lastAccessedTime;
    return new Cookie(cookie.name, cookie.value, options);
}

isolated function getCloneWithDomainAndHostOnly(Cookie cookie, string domain, boolean hostOnly) returns Cookie {
    CookieOptions options = {};
    if cookie.path is string {
        options.path = cookie.path;
    }
    if cookie.expires is string {
        options.expires = cookie.expires;
    }
    options.domain = domain;
    options.maxAge = cookie.maxAge;
    options.httpOnly = cookie.httpOnly;
    options.secure = cookie.secure;
    options.hostOnly = hostOnly;
    options.createdTime = cookie.createdTime;
    options.lastAccessedTime = cookie.lastAccessedTime;
    return new Cookie(cookie.name, cookie.value, options);
}

isolated function getCloneWithHostOnly(Cookie cookie, boolean hostOnly) returns Cookie {
    CookieOptions options = {};
    if cookie.path is string {
        options.path = cookie.path;
    }
    if cookie.domain is string {
        options.domain = cookie.domain;
    }
    if cookie.expires is string {
        options.expires = cookie.expires;
    }
    options.maxAge = cookie.maxAge;
    options.httpOnly = cookie.httpOnly;
    options.secure = cookie.secure;
    options.hostOnly = hostOnly;
    options.createdTime = cookie.createdTime;
    options.lastAccessedTime = cookie.lastAccessedTime;
    return new Cookie(cookie.name, cookie.value, options);
}

isolated function updateLastAccessedTime(Cookie[] cookiesToAdd) {
    Cookie[] tempCookies = [];
    int endValue = cookiesToAdd.length();
    foreach var i in 0 ..< endValue {
        Cookie cookie = cookiesToAdd.pop();
        time:Utc lastAccessedTime = time:utcNow();
        tempCookies.push(getClone(cookie, cookie.createdTime, lastAccessedTime));
    }

    foreach var i in 0 ..< endValue {
        cookiesToAdd.push(tempCookies.pop());
    }
}
