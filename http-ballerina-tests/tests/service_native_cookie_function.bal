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

string filePath = "tests/resources/";

// "Test to add cookie with same domain and path values as in the request url , into cookie store"
@test:Config {}
function testAddCookieToCookieStore1() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add cookie coming from a sub domain of the cookie's domain value, into cookie store
@test:Config {}
function testAddCookieToCookieStore2() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://mail.google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://mail.google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add a host only cookie into cookie store
@test:Config {}
function testAddCookieToCookieStore3() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add cookie with unspecified path value, into cookie store
@test:Config {}
function testAddCookieToCookieStore4() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://mail.google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie name");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add cookie coming from a sub directory of the cookie's path value, into cookie store
@test:Config {}
function testAddCookieToCookieStore5() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.domain = "google.com";
    cookie1.path = "/mail";
    http:Client cookieClientEndpoint = new("http://mail.google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://mail.google.com", "/mail/inbox");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add a third party cookie into cookie store
@test:Config {}
function testAddThirdPartyCookieToCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.domain = "ad.doubleclick.net";
    cookie1.path = "/home";
    http:Client cookieClientEndpoint = new("http://mail.google.com", { cookieConfig: { enabled: true,
                                            blockThirdPartyCookies:false } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://mail.google.com", "/mail/inbox");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add a third party cookie into cookie store
@test:Config {}
function testAddCookiesToCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "239d4dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Cookie[] cookiesToadd =[cookie1, cookie2];
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        cookieStore.addCookies(cookiesToadd, cookieConfigVal, "http://google.com", "/sample");
    }
     // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
}

// Test to add a similar cookie as in the store
@test:Config {}
function testAddSimilarCookieToCookieStore() {
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
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
    test:assertEquals(cookies[0].value, "6789mnmsddd34", msg = "Invalid cookie value");
}

// Test to add cookies concurrently into cookie store
@test:Config {}
function testAddCookiesConcurrentlyToCookieStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie[] cookiesToadd = [cookie1];
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    worker w1 {
        if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
            var result = cookieStore.addCookies(cookiesToadd, cookieConfigVal, "http://google.com", "/sample");
        }
    }
    worker w2 {
        if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
            var result = cookieStore.addCookies(cookiesToadd, cookieConfigVal, "http://google.com", "/sample");
        }
    }
    worker w3 {
        if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
            var result = cookieStore.addCookies(cookiesToadd, cookieConfigVal, "http://google.com", "/sample");
        }
    }
    worker w4 {
        if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore) {
            var result = cookieStore.addCookies(cookiesToadd, cookieConfigVal, "http://google.com", "/sample");
        }
    }
    _ = wait {w1, w2, w3, w4};
    http:Cookie[] cookies = [];
    if (cookieStore is http:CookieStore) {
        cookies = cookieStore.getAllCookies();
    }
    // Gets all the cookies.
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get the relevant cookie with same domain and path values as in the request url from cookie store
@test:Config {}
function testGetCookiesFromCookieStore1() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    // Adds cookie.
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get the relevant cookie to a sub domain of the cookie's domain value from cookie store
@test:Config {}
function testGetCookiesFromCookieStore2() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get a host only cookie to the relevant domain from cookie store
@test:Config {}
function testGetCookiesFromCookieStore3() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get the relevant cookie to a sub directory of the cookie's path value from cookie store
@test:Config {}
function testGetCookiesFromCookieStore4() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/mail";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/mail");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/mail/inbox");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get a cookie with unspecified path value to the relevant path from cookie store
@test:Config {}
function testGetCookiesFromCookieStore5() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get cookies when both matched and unmatched cookies are available in the cookie store
@test:Config {}
function testGetCookiesFromCookieStore6() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "7Av239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.secure = true;
    http:Cookie cookie2 = new("SID002", "239d4dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
    }
    // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("http://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get a secure cookie to a secure url from cookie store
@test:Config {}
function testGetSecureCookieFromCookieStore() {
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
     // Gets the relevant cookie from the cookie store.
    http:Cookie[] cookies = cookieStore.getCookies("https://google.com", "/sample");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to remove a specific session cookie from the cookie store
@test:Config {}
function testRemoveCookieFromCookieStore() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
    }
    var result = cookieStore.removeCookie("SID002", "google.com", "/sample");
    if (result is error) {
        io:println(result);
    }
    // Gets all the cookies.
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to remove all cookies from the cookie store
@test:Config {}
function testRemoveAllCookiesInCookieStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID003", "239d4dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    cookie2.expires = "2030-07-15 05:46:22";
    http:Cookie[] cookies = [];
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-5.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true,
                                            persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig  && cookieStore is http:CookieStore && cookie1.isValid() == true &&
        cookie2.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.removeAllCookies();
        if (result is error) {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to add persistent cookie into cookie store
@test:Config {}
function testAddPersistentCookieToCookieStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "2030-07-15 05:46:22";
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-1.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true,
                                            persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        cookies = cookieStore.getAllCookies();
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to add persistent cookie with a value below 69 for the year in expires attribute
@test:Config {}
function testAddPersistentCookieToCookieStore_2() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "0050-07-15 05:46:22";
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-2.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        cookies = cookieStore.getAllCookies();
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get the relevant persistent cookie from the cookie store
@test:Config {}
function testGetPersistentCookieFromCookieStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "2030-07-15 05:46:22";
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-3.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        cookies = cookieStore.getCookies("http://google.com", "/sample");
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to remove a specific persistent cookie from the cookie store
@test:Config {}
function testRemovePersistentCookieFromCookieStore() {
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    cookie1.expires = "2030-07-15 05:46:22";
    http:CsvPersistentCookieHandler myPersistentStore = new(filePath + "client-4.csv");
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore } } );
    http:CookieStore? cookieStore = cookieClientEndpoint.getCookieStore();
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    http:Cookie[] cookies = [];
    if (cookieConfigVal is http:CookieConfig && cookieStore is http:CookieStore && cookie1.isValid() == true) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.removeCookie("SID002", "google.com", "/sample");
        if (result is error) {
            io:println(result);
        }
        cookies = cookieStore.getAllCookies();
    }
    error? removeResults = file:remove(filePath, file:RECURSIVE);
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}

// Test to get all cookies from the cookie store, which match the given cookie name
@test:Config {}
function testGetCookiesByName() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "gha74dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookiesByName("SID002");
    test:assertEquals(cookies.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID002", msg = "Invalid cookie name");
}

// Test to get all cookies from the cookie store, which match the given cookie domain
@test:Config {}
function testGetCookiesByDomain() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "gha74dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
    }
    http:Cookie[] cookies = cookieStore.getCookiesByDomain("google.com");
    test:assertEquals(cookies.length(), 2, msg = "Invalid cookie object");
    test:assertEquals(cookies[0].name, "SID001", msg = "Invalid cookie name");
    test:assertEquals(cookies[1].name, "SID002", msg = "Invalid cookie name");
}

// Test to remove all cookies from the cookie store, which match the given cookie domain
@test:Config {}
function testRemoveCookiesByDomain() {
    http:CookieStore cookieStore = new;
    http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = "google.com";
    http:Cookie cookie2 = new("SID002", "gha74dmnmsddd34");
    cookie2.path = "/sample";
    cookie2.domain = "google.com";
    http:Client cookieClientEndpoint = new("http://google.com", { cookieConfig: { enabled: true } } );
    var cookieConfigVal = cookieClientEndpoint.config.cookieConfig;
    if (cookieConfigVal is http:CookieConfig) {
        var result = cookieStore.addCookie(cookie1, cookieConfigVal, "http://google.com", "/sample");
        result = cookieStore.addCookie(cookie2, cookieConfigVal, "http://google.com", "/sample");
    }
    var removeResult = cookieStore.removeCookiesByDomain("google.com");
    if (removeResult is error) {
        io:println(removeResult);
    }
    http:Cookie[] cookies = cookieStore.getAllCookies();
    test:assertEquals(cookies.length(), 0, msg = "Invalid cookie object");
}
