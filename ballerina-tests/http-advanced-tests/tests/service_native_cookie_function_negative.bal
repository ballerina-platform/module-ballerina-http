// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/file;
import ballerina/io;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

// Test to add a cookie with unmatched domain to the cookie store
@test:Config {}
function testAddCookieWithUnmatchedDomain() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "foo.example.com");
    http:CookieConfig cookieConfig = {enabled: true};
    error? result = cookieStore.addCookie(cookie1, cookieConfig, "http://bar.example.com", "/sample");
    if result is error {
        io:println(result);
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to add a cookie with unmatched path to the cookie store
@test:Config {}
function testAddCookieWithUnmatchedPath() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/mail/inbox", domain = "example.com");
    http:CookieConfig cookieConfig = {enabled: true};
    error? result = cookieStore.addCookie(cookie1, cookieConfig, "http://example.com", "/mail");
    if result is error {
        io:println(result);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to add a similar cookie as in the cookie store coming from a non-http request url, but
// existing old cookie is http only
@test:Config {}
function testAddSimilarCookie() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", httpOnly = true);
    http:Cookie cookie2 = new ("SID002", "6789mnmsddd34", path = "/sample", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true};
    error? result = cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    if result is error {
        io:println(result);
    }
    result = cookieStore.addCookie(cookie2, cookieConfig, "google.com", "/sample");
    if result is error {
        io:println(result);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
    test:assertEquals(cookies[0].value, "239d4dmnmsddd34", msg = "Invalid cookie value");
}

// Test to add a http only cookie coming from a non-http url
@test:Config {}
function testAddHttpOnlyCookie() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", httpOnly = true);
    http:CookieConfig cookieConfig = {enabled: true};
    error? result = cookieStore.addCookie(cookie1, cookieConfig, "google.com", "/sample");
    if result is error {
        io:println(result);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a secure only cookie to unsecured request url
@test:Config {}
function testNegativeGetSecureCookieFromCookieStore() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", secure = true);
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to get a http only cookie to non-http request url
@test:Config {}
function testGetHttpOnlyCookieFromCookieStore() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", httpOnly = true);
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    http:Cookie[] cookies = cookieStore.getCookies("google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to get a host only cookie to a sub-domain from the cookie store
@test:Config {}
function testGetCookieToUnmatchedDomain1() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample");
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    http:Cookie[] cookies = cookieStore.getCookies("http://mail.google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to get a cookie to unmatched request domain
@test:Config {}
function testGetCookieToUnmatchedDomain2() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "foo.google.com");
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://foo.google.com", "/sample");
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to get a cookie to unmatched request path
@test:Config {}
function testGetCookieToUnmatchedPath1() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/mail/inbox", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/mail/inbox");
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/mail");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to get a cookie with unspecified path to unmatched request path
@test:Config {}
function testGetCookieToUnmatchedPath2() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/mail");
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
    return;
}

// Test to remove a specific cookie which is not in the cookie store when persistent cookie handler is not configured
@test:Config {}
function testNegativeRemoveCookieFromCookieStore() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    var removeResult = cookieStore.removeCookie("SID003", "google.com", "/sample");
    if (removeResult is error) {
        io:println(removeResult);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
    return;
}

// Test to add cookies more than the number in maxTotalCookieCount in cookie configuration
@test:Config {}
function testCheckMaxTotalCookieCount() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID001", "239d4dmnmsddd34", path = "/sample", domain = "google.com");
    http:Cookie cookie2 = new ("SID002", "jka6mnmsddd34", path = "/sample", domain = "google.com");
    http:Cookie cookie3 = new ("SID003", "kafh34dmnmsddd34", path = "/sample", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true, maxTotalCookieCount: 2};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    _ = check cookieStore.addCookie(cookie2, cookieConfig, "http://google.com", "/sample");
    error? result = cookieStore.addCookie(cookie3, cookieConfig, "http://google.com", "/sample");
    if result is error {
        common:assertTrueTextPayload(result.message(), "Number of total cookies in the cookie store can not exceed");
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
    return;
}

// Test to add cookies more than the number in maxCookiesPerDomain in cookie configuration
@test:Config {}
function testCheckMaxCookiesPerDomain() returns error? {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new ("SID001", "239d4dmnmsddd34", path = "/sample", domain = "google.com");
    http:Cookie cookie2 = new ("SID002", "jka6mnmsddd34", path = "/sample", domain = "google.com");
    http:Cookie cookie3 = new ("SID003", "kafh34dmnmsddd34", path = "/sample", domain = "google.com");
    http:CookieConfig cookieConfig = {enabled: true, maxCookiesPerDomain: 2};
    _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
    _ = check cookieStore.addCookie(cookie2, cookieConfig, "http://google.com", "/sample");
    error? result = cookieStore.addCookie(cookie3, cookieConfig, "http://google.com", "/sample");
    if result is error {
        common:assertTrueTextPayload(result.message(), "Number of total cookies for the domain");
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
    return;
}

// Test to give invalid file extension when creating a CsvPersistentCookieHandler object
@test:Config {}
function testAddPersistentCookieWithoutPersistentStore() returns error? {
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", expires = "2030-07-15 05:46:22");
    http:CookieConfig cookieConfig = {enabled: true};
    http:Client cookieClientEndpoint = check new ("http://google.com", cookieConfig = cookieConfig);
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    http:Cookie[] cookies = [];
    boolean|error validCookie1 = cookie1.isValid();
    if (cookieStore is http:CookieStore && validCookie1 is boolean && validCookie1) {
        error? result = cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
        if result is error {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove a specific cookie which is not in the cookie store, when there is a persistent cookie store
@test:Config {}
function testRemovePersistentCookieFromCookieStore_1() returns error? {
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = "google.com", expires = "2030-07-15 05:46:22");
    http:CsvPersistentCookieHandler myPersistentStore = new (filePath + "client-6.csv");
    http:CookieConfig cookieConfig = {enabled: true, persistentCookieHandler: myPersistentStore};
    http:Client cookieClientEndpoint = check new ("http://google.com", cookieConfig = cookieConfig);
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    http:Cookie[] cookies = [];
    boolean|error validCookie1 = cookie1.isValid();
    if (cookieStore is http:CookieStore && validCookie1 is boolean && validCookie1) {
        _ = check cookieStore.addCookie(cookie1, cookieConfig, "http://google.com", "/sample");
        error? result1 = trap cookieStore.removeCookie("SID003", "google.com", "/sample");
        if (result1 is error) {
            test:assertEquals(result1.message(), "{ballerina/lang.table}KeyNotFound", msg = "Incorrect error");
        }
        cookies = cookieStore.getAllCookies();
    }
    _ = check file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
    return;
}

// Test to remove a specific cookie which is not in the cookie store, when there is no persistent cookie store
@test:Config {}
function testRemovePersistentCookieFromCookieStore_2() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new (filePath + "client-7.csv");
    http:CookieConfig cookieConfig = {enabled: true, persistentCookieHandler: myPersistentStore};
    http:Client cookieClientEndpoint = check new ("http://google.com", cookieConfig = cookieConfig);
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    http:Cookie[] cookies = [];
    if (cookieStore is http:CookieStore) {
        error? result = cookieStore.removeCookie("SID003", "google.com", "/sample");
        if result is error {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove all cookies when there is no persistent cookie store
@test:Config {}
function testRemoveAllCookiesFromCookieStore() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new (filePath + "client-8.csv");
    http:CookieConfig cookieConfig = {enabled: true, persistentCookieHandler: myPersistentStore};
    http:Client cookieClientEndpoint = check new ("http://google.com", cookieConfig = cookieConfig);
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    http:Cookie[] cookies = [];
    if (cookieStore is http:CookieStore) {
        error? result = cookieStore.removeAllCookies();
        if result is error {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}
