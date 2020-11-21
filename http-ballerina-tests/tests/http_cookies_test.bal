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

@http:ServiceConfig {
    basePath: "/cookie"
}
service cookie on new http:Listener(9253) {

   @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_1"
   }
    resource function addPersistentAndSessionCookies(http:Caller caller, http:Request req) {
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
        cookie1.path = "/cookie/cookieBackend_1";
        cookie1.domain = "localhost:9253";
        cookie1.httpOnly = true;
        cookie1.secure = false;
        cookie1.expires = "2030-06-26 05:46:22";

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34");
        cookie2.path = "/cookie/cookieBackend_1";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = true;
        cookie2.secure = false;
        cookie2.expires = "2030-07-15 05:46:22";

        http:Cookie cookie3 = new("SID003", "895gd4dmnmsddd34");
        cookie3.path = "/cookie/cookieBackend_1";
        cookie3.domain = "localhost:9253";
        cookie3.httpOnly = true;
        cookie3.secure = false;

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie1);
            res.addCookie(cookie3);
            var result = caller->respond(res);
        } else if (reqstCookies.length() == 2) {
            res.addCookie(cookie2);
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
          path: "/cookieBackend_2"
    }
    resource function addSimilarSessionCookie(http:Caller caller, http:Request req) {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
        cookie1.path = "/cookie";
        cookie1.domain = "localhost:9253";
        cookie1.httpOnly = true;

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34");
        cookie2.path = "/cookie";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = false;

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies only if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
          path: "/cookieBackend_3"
    }
    resource function removeSessionCookie(http:Caller caller, http:Request req) {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
        cookie1.path = "/cookie";
        cookie1.domain = "localhost:9253";
        cookie1.httpOnly = true;

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34");
        cookie2.path = "/cookie/cookieBackend_3";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = true;
        cookie2.secure = false;

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            var result = caller->respond(res);
        } else if (reqstCookies.length() == 2) {
            res.removeCookiesFromRemoteStore(cookie1);
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

   @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_4"
   }
    resource function sendSimilarPersistentCookies(http:Caller caller, http:Request req) {
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
        cookie1.path = "/cookie/cookieBackend_4";
        cookie1.domain = "localhost:9253";
        cookie1.httpOnly = false;
        cookie1.secure = false;
        cookie1.expires = "2030-06-26 05:46:22";

        http:Cookie cookie3 = new("SID001", "895gd4dmnmsddd34");
        cookie3.path = "/cookie/cookieBackend_4";
        cookie3.domain = "localhost:9253";
        cookie3.httpOnly = true;
        cookie3.secure = false;
        cookie3.expires = "2030-06-26 05:46:22";
        http:Response res = new;

        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie1);
            res.addCookie(cookie3);
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

   @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_5"
   }
    resource function sendSimilarPersistentAndSessionCookies_1(http:Caller caller, http:Request req) {
        http:Cookie cookie2 = new("SID003", "895gd4dmnmsddd34");
        cookie2.path = "/cookie/cookieBackend_5";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = true;
        cookie2.secure = false;

        http:Cookie cookie3 = new("SID003", "aeaa895gd4dmnmsddd34");
        cookie3.path = "/cookie/cookieBackend_5";
        cookie3.domain = "localhost:9253";
        cookie3.httpOnly = false;
        cookie3.secure = false;
        cookie3.expires = "2030-07-15 05:46:22";

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie2); // Adds a session cookie.
            res.addCookie(cookie3); // Adds a similar persistent cookie.
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

   @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_6"
   }
    resource function sendSimilarPersistentAndSessionCookies_2(http:Caller caller, http:Request req) {
        http:Cookie cookie2 = new("SID003", "aeaa895gd4dmnmsddd34");
        cookie2.path = "/cookie/cookieBackend_6";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = false;
        cookie2.secure = false;
        cookie2.expires = "2030-07-15 05:46:22";

        http:Cookie cookie3 = new("SID003", "895gd4dmnmsddd34");
        cookie3.path = "/cookie/cookieBackend_6";
        cookie3.domain = "localhost:9253";
        cookie3.httpOnly = true;
        cookie3.secure = false;

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie2); // Adds a persistent cookie.
            res.addCookie(cookie3); // Adds a similar session cookie.
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

   @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_7"
   }
    resource function removePersistentCookieByServer(http:Caller caller, http:Request req) {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34");
        cookie1.path = "/cookie/cookieBackend_7";
        cookie1.domain = "localhost:9253";
        cookie1.httpOnly = true;
        cookie1.expires = "2030-07-15 05:46:22";

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34");
        cookie2.path = "/cookie/cookieBackend_7";
        cookie2.domain = "localhost:9253";
        cookie2.httpOnly = true;
        cookie2.secure = false;

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if (reqstCookies.length() == 0) {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            var result = caller->respond(res);
        } else if (reqstCookies.length() == 2) {
            res.removeCookiesFromRemoteStore(cookie1);
            var result = caller->respond(res);
        } else {
            string cookieHeader = req.getHeader("Cookie");
            res.setPayload(<@untainted> cookieHeader);
            var result = caller->respond(res);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/cookieBackend_13"
   }
    resource function validateCookie(http:Caller caller, http:Request req) {
        http:Cookie[] reqstCookies = req.getCookies();
        string message = "Valid cookies: ";
        foreach http:Cookie cookie in reqstCookies {
            var value = cookie.value;
            var name = cookie.name;
            if (value is string && name is string) {
                message = message.concat(name, "=", value , ",");
            }
        }
        http:Response res = new;
        res.setPayload(<@untainted> message);
        var result = caller->respond(res);
    }
}

// Test to send requests by cookie client for first, second and third times
@test:Config {}
public function testSendRequestsByCookieClient() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-1.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends the cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Third request is with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34; SID001=239d4dmnmsddd34; SID002=178gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE); // Removes persistent store file.
}

// Test to remove a session cookie by client
@test:Config {}
public function testRemoveSessionCookieByClient() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-2.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Removes a session cookie.
    http:CookieStore? myCookieStore = cookieClientEndpoint.getCookieStore();
    if (myCookieStore is http:CookieStore) {
        var removeResult = myCookieStore.removeCookie("SID003", "localhost:9253", "/cookie/cookieBackend_1");
        if (removeResult is error) {
            io:println(removeResult);
        }
    }
    // Sends a request again after one session cookie is removed.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID001=239d4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test sending similar session cookies in the response by server,old cookie is replaced by new
// cookie in the cookie store
@test:Config {}
public function testAddSimilarSessionCookies() {
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true }
        });
    http:Request req = new;
    // Server sends similar session cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_2", req);
    // Sends second request after replacing the old cookie with the new.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_2", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test to remove a session cookie by server
@test:Config {}
public function testRemoveSessionCookieByServer() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookies-test-data/client-4.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends the session cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_3", req);
    // Server removes an existing session cookie in the cookie store by sending an expired cookie in the response.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_3", req);
    // Third request after removing the cookie.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_3", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test to send concurrent requests by cookie client
@test:Config {
    enable: false
}
public function testSendConcurrentRequests() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-5.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    worker w1 {
        http:Request req = new;
        var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    }
    worker w2 {
        http:Request req = new;
        var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    }
    worker w3 {
        http:Request req = new;
        var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    }
    worker w4 {
        http:Request req = new;
        var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    }
    _ = wait {w1, w2, w3, w4};
    http:CookieStore? myCookieStore = cookieClientEndpoint.getCookieStore();
    string[] names =[];
    if (myCookieStore is http:CookieStore) {
        http:Cookie[] cookies = myCookieStore.getAllCookies();
        io:println(cookies.length());
        int i = 0;
        test:assertEquals(cookies.length(), 3, msg = "Found unexpected output");
        foreach var item in cookies {
            string? name = item.name;
            if (name is string) {
                names[i] = name;
            }
            i = i + 1;
        }
        test:assertEquals(names, ["SID003", "SID001", "SID002"], msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send requests by a client with Circuit Breaker, Retry and Cookie configurations are enabled
@test:Config {}
public function testSendRequestsByClient() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-6.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            retryConfig: {
                intervalInMillis: 3000,
                count: 3,
                backOffFactor: 2.0,
                maxWaitIntervalInMillis: 20000
            },
            circuitBreaker: {
                rollingWindow: {
                    timeWindowInMillis: 10000,
                    bucketSizeInMillis: 2000,
                    requestVolumeThreshold: 0
                },
                failureThreshold: 0.2,
                resetTimeInMillis: 10000,
                statusCodes: [400, 404, 500]
            },
            cookieConfig: {
                enabled: true,
                persistentCookieHandler: myPersistentStore
            }
        });
    http:Request req = new;
    // Server sends cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
     // Third request is with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34; SID001=239d4dmnmsddd34; SID002=178gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to remove a persistent cookie by the client
@test:Config {}
public function testRemovePersistentCookieByClient() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-7.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends the cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Removes a persistent cookie.
    http:CookieStore? myCookieStore = cookieClientEndpoint.getCookieStore();
    if (myCookieStore is http:CookieStore) {
        var removeResult = myCookieStore.removeCookie("SID001", "localhost:9253", "/cookie/cookieBackend_1");
        if (removeResult is error) {
            io:println(removeResult);
        }
    }
    // Sends a request again after one persistent cookie is removed.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send similar persistent cookies in the response by server. The old cookie is
// replaced by the new cookie in the cookie store
@test:Config {}
public function testAddSimilarPersistentCookies() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-8.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends similar persistent cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_4", req);
    // Sends the second request after replacing the old cookie with the new.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_4", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID001=895gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send a session cookie and a similar persistent cookie in the response by server.
// The old session cookie is replaced by the new persistent cookie in the cookie store
@test:Config {}
public function testSendSimilarPersistentAndSessionCookies_1() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-9.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends a session cookie and a similar persistent cookie in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_5", req);
    // Sends the second request after replacing the session cookie with the new persistent cookie.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_5", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=aeaa895gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send a persistent cookie and a similar session cookie in the response by the server.
// The old persistent cookie is replaced by the new session cookie in the cookie store
@test:Config {}
public function testSendSimilarPersistentAndSessionCookies_2() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-10.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends a persistent cookie and a similar session cookie in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_6", req);
    // Sends the second request after replacing the persistent cookie with the new session cookie.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_6", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to remove a persistent cookie by the server
@test:Config {}
public function testRemovePersistentCookieByServer() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-11.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true, persistentCookieHandler: myPersistentStore }
        });
    http:Request req = new;
    // Server sends cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_7", req);
    // Server removes an existing persistent cookie in the cookie store by sending an expired cookie in the response.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_7", req);
    // Third request is sent after removing the cookie.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_7", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send persistent cookies when the persistentCookieHandler is not configured
@test:Config {}
public function testSendPersistentCookiesWithoutPersistentCookieHandler() {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-12.csv");
    http:Client cookieClientEndpoint = new ("http://localhost:9253", {
            cookieConfig: { enabled: true }
        });
    http:Request req = new;
    // Server sends the cookies in the response for the first request.
    var response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/cookieBackend_1", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    error? removeResults = file:remove("./cookie-test-data", file:RECURSIVE); // Removes persistent store file.
}

// Test the cookie validation when using the getCookies()
@test:Config {}
public function testCookieValidation() {
    http:Client clientEP = new("http://localhost:9253");
    http:Request req = new;
    req.addHeader("Cookie", "user=John; asd=; =sdsdfsf; =gffg; ");
    var response = clientEP->get("/cookie/cookieBackend_13", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Valid cookies: user=John,asd=,");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
