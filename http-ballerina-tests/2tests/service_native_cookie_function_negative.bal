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

// Test to add a cookie with unmatched domain to the cookie store
@test:Config {}
function testAddCookieWithUnmatchedDomain() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "foo.example.com";
    http:Client cookieClientEndpoint = new("http://bar.example.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://bar.example.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to add a cookie with unmatched path to the cookie store
@test:Config {}
function testAddCookieWithUnmatchedPath() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/mail/inbox";
    cookie1.domain = "example.com";
    http:Client cookieClientEndpoint = new("http://example.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://example.com", "/mail");
        if (result is error) {
            io:println(result);
        }
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to add a similar cookie as in the cookie store coming from a non-http request url, but
// existing old cookie is http only
@test:Config {}
function testAddSimilarCookie() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.httpOnly = true;
    http:Cookie cookie2 = new("SID002", "6789mnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
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
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.httpOnly = true;
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a secure only cookie to unsecured request url
@test:Config {}
function testNegativeGetSecureCookieFromCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.secure = true;
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a http only cookie to non-http request url
@test:Config {}
function testGetHttpOnlyCookieFromCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.httpOnly = true;
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookies("google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a host only cookie to a sub-domain from the cookie store
@test:Config {}
function testGetCookieToUnmatchedDomain1() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookies("http://mail.google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a cookie to unmatched request domain
@test:Config {}
function testGetCookieToUnmatchedDomain2() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "foo.google.com";
    http:Client cookieClientEndpoint = new("http://foo.google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://foo.google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a cookie to unmatched request path
@test:Config {}
function testGetCookieToUnmatchedPath1() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/mail/inbox";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/mail/inbox");
    }
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/mail");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get a cookie with unspecified path to unmatched request path
@test:Config {}
function testGetCookieToUnmatchedPath2() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/mail");
    }
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove a specific cookie which is not in the cookie store when persistent cookie handler is not configured
@test:Config {}
function testNegativeRemoveCookieFromCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample" );
    }
    var removeResult = cookieStore.removeCookie("SID003", "google.com", "/sample");
    if (removeResult is error) {
        io:println(removeResult);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add cookies more than the number in maxTotalCookieCount in cookie configuration
@test:Config {}
function testCheckMaxTotalCookieCount() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "jka6mnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Cookie cookie3 = new("SID003", "kafh34dmnmsddd34");
    cookie3.path = "/sample";
    cookie3.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true, maxTotalCookieCount:2 } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie3, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
}

// Test to add cookies more than the number in maxCookiesPerDomain in cookie configuration
@test:Config {}
function testCheckMaxCookiesPerDomain() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "jka6mnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Cookie cookie3 = new("SID003", "kafh34dmnmsddd34");
    cookie3.path = "/sample";
    cookie3.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true, maxCookiesPerDomain:2 } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie3, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
}

// Test to give invalid file extension when creating a CsvPersistentCookieHandler object
@test:Config {}
function testAddPersistentCookieWithoutPersistentStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "2030-07-15 05:46:22";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove a specific cookie which is not in the cookie store, when there is a persistent cookie store
@test:Config {}
function testRemovePersistentCookieFromCookieStore_1() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "2030-07-15 05:46:22";
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-6.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true,
                                            persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        error? result1 = trap cookieStore.removeCookie("SID003", "google.com", "/sample");
        if (result1 is error) {
            test:assertEquals(result1.message(), "{ballerina/lang.table}KeyNotFound", msg = "Incorrect error");
        }
        cookies = cookieStore.getAllCookies();
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to remove a specific cookie which is not in the cookie store, when there is no persistent cookie store
@test:Config {}
function testRemovePersistentCookieFromCookieStore_2() {
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-7.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true,
                                            persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
        var result = cookieStore.removeCookie("SID003", "google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove all cookies when there is no persistent cookie store
@test:Config {}
function testRemoveAllCookiesFromCookieStore() {
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-8.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true,
                                            persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
        var result = cookieStore.removeAllCookies();
        if (result is error) {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}
