// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

service /api on new http:Listener(identicalCookiePort) {

    resource function get .(@http:Header string? cookie) returns http:Response {
        http:Response res = new;
        http:Cookie resCookie = new ("cookie", "default", path = "/api");
        res.addCookie(resCookie);
        res.setTextPayload("Hello, World!");
        if cookie is string {
            res.setHeader("Req-Cookies", cookie);
        }
        return res;
    }

    resource function get foo(@http:Header string? cookie, string value = "foo") returns http:Response {
        http:Response res = new;
        http:Cookie resCookie = new ("cookie", value, path = "/api/foo");
        res.addCookie(resCookie);
        res.setTextPayload("Hello, World!");
        if cookie is string {
            res.setHeader("Req-Cookies", cookie);
        }
        return res;
    }

    resource function get bar(@http:Header string? cookie) returns http:Response {
        http:Response res = new;
        http:Cookie resCookie = new ("cookie", "bar", path = "/api/bar");
        res.addCookie(resCookie);
        res.setTextPayload("Hello, World!");
        if cookie is string {
            res.setHeader("Req-Cookies", cookie);
        }
        return res;
    }

    resource function 'default [string... path](@http:Header string? cookie) returns http:Response {
        http:Response res = new;
        http:Cookie resCookie = new ("cookie", string:'join("/", ...path), path = "/api/");
        res.addCookie(resCookie);
        res.setTextPayload("Hello, World!");
        if cookie is string {
            res.setHeader("Req-Cookies", cookie);
        }
        return res;
    }
}

@test:Config {}
function testIdenticalCookieOverwrite1() returns error? {
    http:Client cookieClient = check new (string `localhost:${identicalCookiePort}`,
        cookieConfig = {
            enabled: true
        }
    );
    http:Response res = check cookieClient->/api/foo;
    test:assertFalse(res.hasHeader("Req-Cookies"), "Req-Cookies header should not be present");

    res = check cookieClient->/api/foo(value = "random");
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=foo", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/foo;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=random", "Req-Cookies header value mismatched");
}

@test:Config {}
function testIdenticalCookieOverwrite2() returns error? {
    http:Client cookieClient = check new (string `localhost:${identicalCookiePort}`,
        cookieConfig = {
            enabled: true
        }
    );
    http:Response res = check cookieClient->/api/baz;
    test:assertFalse(res.hasHeader("Req-Cookies"), "Req-Cookies header should not be present");

    res = check cookieClient->/api/foo/baz();
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=baz", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/baz;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=foo/baz", "Req-Cookies header value mismatched");
}

@test:Config {}
function testNonIdenticalCookieWithSameName1() returns error? {
    http:Client cookieClient = check new (string `localhost:${identicalCookiePort}`,
        cookieConfig = {
            enabled: true
        }
    );
    http:Response res = check cookieClient->/api;
    test:assertFalse(res.hasHeader("Req-Cookies"), "Req-Cookies header should not be present");

    res = check cookieClient->/api/foo;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/foo(value = "new");
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default; cookie=foo", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/foo;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default; cookie=new", "Req-Cookies header value mismatched");
}

@test:Config {}
function testNonIdenticalCookieWithSameName2() returns error? {
    http:Client cookieClient = check new (string `localhost:${identicalCookiePort}`,
        cookieConfig = {
            enabled: true
        }
    );
    http:Response res = check cookieClient->/api;
    test:assertFalse(res.hasHeader("Req-Cookies"), "Req-Cookies header should not be present");

    res = check cookieClient->/api/baz;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/baz/foo;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default; cookie=baz", "Req-Cookies header value mismatched");

    res = check cookieClient->/api/baz;
    test:assertEquals(res.getHeader("Req-Cookies"), "cookie=default; cookie=baz/foo", "Req-Cookies header value mismatched");
}
