// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
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
import ballerina/test;

service /api on new http:Listener(setCookieParserPort) {

    resource function get cookieAttributesWithoutSpaces() returns http:Ok {
        return {
            body: {
                "message": "Hello"
            },
            headers: {
                "Set-Cookie": "cookie=value;Path=/;HttpOnly"
            }
        };
    }

    resource function get caseInsensitiveCookieAttribute() returns http:Ok {
        return {
            body: {
                "message": "Hello"
            },
            headers: {
                "Set-Cookie": "cookie=value; path=/api;httponly; secure"
            }
        };
    }
}

@test:Config
function testSetCookieWithCookieAttributesWithoutSpaces() returns error? {
    http:Client clientEp = check new (string `localhost:${setCookieParserPort}`,
        cookieConfig = {
            enabled: true
        }
    );

    http:CookieStore? cookieStore = clientEp.getCookieStore();
    if cookieStore !is http:CookieStore {
        test:assertFail("Failed to get cookie store");
    }
    test:assertTrue(cookieStore.getCookiesByName("cookie").length() == 0, msg = "Cookie store should be empty before request");

    json resp = check clientEp->/api/cookieAttributesWithoutSpaces;
    test:assertEquals(resp.message, "Hello", msg = "Response message mismatch");
    test:assertTrue(cookieStore.getCookiesByName("cookie").length() == 1, msg = "Cookie store should have one cookie");

    http:Cookie cookie = cookieStore.getCookiesByName("cookie")[0];
    test:assertEquals(cookie.name, "cookie", msg = "Cookie name mismatch");
    test:assertEquals(cookie.value, "value", msg = "Cookie value mismatch");
    test:assertEquals(cookie.path, "/", msg = "Cookie path mismatch");
    test:assertEquals(cookie.httpOnly, true, msg = "Cookie httpOnly mismatch");
}

@test:Config
function testSetCookieWithCaseInsensitiveCookieAttribute() returns error? {
    http:Client clientEp = check new (string `localhost:${setCookieParserPort}`,
        cookieConfig = {
            enabled: true
        }
    );

    http:CookieStore? cookieStore = clientEp.getCookieStore();
    if cookieStore !is http:CookieStore {
        test:assertFail("Failed to get cookie store");
    }
    test:assertTrue(cookieStore.getCookiesByName("cookie").length() == 0, msg = "Cookie store should be empty before request");

    json resp = check clientEp->/api/caseInsensitiveCookieAttribute;
    test:assertEquals(resp.message, "Hello", msg = "Response message mismatch");
    test:assertTrue(cookieStore.getCookiesByName("cookie").length() == 1, msg = "Cookie store should have one cookie");

    http:Cookie cookie = cookieStore.getCookiesByName("cookie")[0];
    test:assertEquals(cookie.name, "cookie", msg = "Cookie name mismatch");
    test:assertEquals(cookie.value, "value", msg = "Cookie value mismatch");
    test:assertEquals(cookie.path, "/api", msg = "Cookie path mismatch");
    test:assertEquals(cookie.httpOnly, true, msg = "Cookie httpOnly mismatch");
    test:assertEquals(cookie.secure, true, msg = "Cookie secure mismatch");
}
