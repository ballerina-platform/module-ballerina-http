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
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener CookieTestServerEP = new (cookieTestPort1, httpVersion = http:HTTP_1_1);

http:ListenerConfiguration http2SslServiceConf = {
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener CookieTestHTTPSServerEP = new (cookieTestPort2, http2SslServiceConf);

service /cookie on CookieTestServerEP {

    resource function get addPersistentAndSessionCookies(http:Caller caller, http:Request req) returns error? {

        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookies",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false,
            expires = "2030-06-26 05:46:22");

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookies",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false,
            expires = "2030-07-15 05:46:22");


        http:Cookie cookie3 = new("SID003", "895gd4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookies",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie3);
            check caller->respond(res);
        } else if reqstCookies.length() == 2 {
            res.addCookie(cookie2);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get addSimilarSessionCookie(http:Caller caller, http:Request req) returns error? {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34",
            path = "/cookie",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true);

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34",
            path = "/cookie",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies only if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get removeSessionCookie(http:Caller caller, http:Request req) returns error? {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34",
            path = "/cookie",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true);

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34",
            path = "/cookie/removeSessionCookie",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            check caller->respond(res);
        } else if reqstCookies.length() == 2 {
            res.removeCookiesFromRemoteStore(cookie1);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get sendSimilarPersistentCookies(http:Caller caller, http:Request req) returns error? {
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentCookies",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = false,
            secure = false,
            expires = "2030-06-26 05:46:22");

        http:Cookie cookie3 = new("SID001", "895gd4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentCookies",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false,
            expires = "2030-06-26 05:46:22");
        http:Response res = new;

        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie3);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get sendSimilarPersistentAndSessionCookies_1(http:Caller caller, http:Request req)
            returns error? {
        http:Cookie cookie2 = new("SID003", "895gd4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentAndSessionCookies_1",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Cookie cookie3 = new("SID003", "aeaa895gd4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentAndSessionCookies_1",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = false,
            secure = false,
            expires = "2030-07-15 05:46:22");

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie2); // Adds a session cookie.
            res.addCookie(cookie3); // Adds a similar persistent cookie.
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get sendSimilarPersistentAndSessionCookies_2(http:Caller caller, http:Request req)
            returns error? {
        http:Cookie cookie2 = new("SID003", "aeaa895gd4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentAndSessionCookies_2",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = false,
            secure = false,
            expires = "2030-07-15 05:46:22");

        http:Cookie cookie3 = new("SID003", "895gd4dmnmsddd34",
            path = "/cookie/sendSimilarPersistentAndSessionCookies_2",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie2); // Adds a persistent cookie.
            res.addCookie(cookie3); // Adds a similar session cookie.
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get removePersistentCookieByServer(http:Caller caller, http:Request req) returns error? {
        // Creates the cookies.
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34",
            path = "/cookie/removePersistentCookieByServer",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            expires = "2030-07-15 05:46:22");

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34",
            path = "/cookie/removePersistentCookieByServer",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie2);
            check caller->respond(res);
        } else if reqstCookies.length() == 2 {
            res.removeCookiesFromRemoteStore(cookie1);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }

    resource function get validateCookie(http:Caller caller, http:Request req) returns error? {
        http:Cookie[] reqstCookies = req.getCookies();
        string message = "Valid cookies: ";
        foreach http:Cookie cookie in reqstCookies {
            message = message.concat(cookie.name, "=", cookie.value , ",");
        }
        http:Response res = new;
        res.setPayload(message);
        check caller->respond(res);
    }

    resource function 'default addPersistentAndSessionCookiesDefault(http:Caller caller, http:Request req)
            returns error? {
        http:Cookie cookie1 = new("SID001", "239d4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookiesDefault",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false,
            expires = "2030-06-26 05:46:22");

        http:Cookie cookie2 = new("SID002", "178gd4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookiesDefault",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false,
            expires = "2030-07-15 05:46:22");

        http:Cookie cookie3 = new("SID003", "895gd4dmnmsddd34",
            path = "/cookie/addPersistentAndSessionCookiesDefault",
            domain = string `localhost:${cookieTestPort1}`,
            httpOnly = true,
            secure = false);

        http:Response res = new;
        http:Cookie[] reqstCookies=req.getCookies();
        // Adds cookies if there are no cookies in the inbound request.
        if reqstCookies.length() == 0 {
            res.addCookie(cookie1);
            res.addCookie(cookie3);
            check caller->respond(res);
        } else if reqstCookies.length() == 2 {
            res.addCookie(cookie2);
            check caller->respond(res);
        } else {
            string cookieHeader = check req.getHeader("Cookie");
            res.setPayload(cookieHeader);
            check caller->respond(res);
        }
    }
}

service /cookieDemo on CookieTestServerEP {
    resource function post login(http:Request req) returns http:Response|http:BadRequest {
        json|error details = req.getJsonPayload();
        if details is json {
            json|error name = details.name;
            json|error password = details.password;

            if name is json && password is json {
                if password == "p@ssw0rd" {
                    http:Cookie cookie = new("username", name.toString(), path = "/", hostOnly = false);
                    http:Response response = new;
                    response.addCookie(cookie);
                    response.setTextPayload("Login succeeded");
                    return response;
                }
            }
        }
        return {body: "Invalid request payload"};
    }

    resource function get welcome(http:Request req) returns string {
        http:Cookie[] cookies = req.getCookies();
        http:Cookie[] usernameCookie = cookies.filter(function
                                (http:Cookie cookie) returns boolean {
            return cookie.name == "username";
        });

        if usernameCookie.length() > 0 {
            string? user = usernameCookie[0].value;
            if user is string {
                return "Welcome back " + user;
            } else {
                return "Please login";
            }
        } else {
            return "Please login";
        }
    }
}

service /cookies on CookieTestServerEP {

    resource function get path(http:Request req) returns http:Response|string {
        http:Cookie[] userCookie = from http:Cookie cookie in req.getCookies()
            where cookie.name == "user"
            limit 1
            select cookie;
        if userCookie.length() == 0 {
            http:Cookie cookie = new ("user", "ballerina", {path: "/cookies"});
            http:Response res = new;
            res.addCookie(cookie);
            return res;
        }
        return userCookie[0].value;
    }

    resource function get .(http:Request req) returns http:Response|string {
        http:Cookie[] userCookie = from http:Cookie cookie in req.getCookies()
            where cookie.name == "user"
            limit 1
            select cookie;
        if userCookie.length() == 0 {
            http:Cookie cookie = new ("user", "ballerina", {path: "/cookies"});
            http:Response res = new;
            res.addCookie(cookie);
            return res;
        }
        return userCookie[0].value;
    }
}

service /cookies on CookieTestHTTPSServerEP {

    resource function get path(http:Request req) returns http:Response|string {
        http:Cookie[] userCookie = from http:Cookie cookie in req.getCookies()
            where cookie.name == "user"
            limit 1
            select cookie;
        if userCookie.length() == 0 {
            http:Cookie cookie = new ("user", "ballerina", {path: "/cookies"});
            http:Response res = new;
            res.addCookie(cookie);
            return res;
        }
        return userCookie[0].value;
    }

    resource function get .(http:Request req) returns http:Response|string {
        http:Cookie[] userCookie = from http:Cookie cookie in req.getCookies()
            where cookie.name == "user"
            limit 1
            select cookie;
        if userCookie.length() == 0 {
            http:Cookie cookie = new ("user", "ballerina", {path: "/cookies"});
            http:Response res = new;
            res.addCookie(cookie);
            return res;
        }
        return userCookie[0].value;
    }
}

// Test to send requests by cookie client for first, second and third times
@test:Config {}
public isolated function testSendRequestsByCookieClient() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-1.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Third request is with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34; SID001=239d4dmnmsddd34; SID002=178gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE); // Removes persistent store file.
}

// Test to remove a session cookie by client
@test:Config {}
public isolated function testRemoveSessionCookieByClient() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-2.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Removes a session cookie.
    http:CookieStore? myCookieStore = cookieClientEndpoint.getCookieStore();
    if myCookieStore is http:CookieStore {
        http:CookieHandlingError? removeResult =
                myCookieStore.removeCookie("SID003", string `localhost:${cookieTestPort1}`, "/cookie/addPersistentAndSessionCookies");
        if removeResult is http:CookieHandlingError {
            // log:printError("Error retrieving", 'error = removeResult);
        }
    }
    // Sends a request again after one session cookie is removed.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID001=239d4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test sending similar session cookies in the response by server,old cookie is replaced by new
// cookie in the cookie store
@test:Config {}
public isolated function testAddSimilarSessionCookies() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends similar session cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addSimilarSessionCookie");
    // Sends second request after replacing the old cookie with the new.
    response = cookieClientEndpoint->get("/cookie/addSimilarSessionCookie");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test to remove a session cookie by server
@test:Config {}
public isolated function testRemoveSessionCookieByServer() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookies-test-data/client-4.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends the session cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/removeSessionCookie");
    // Server removes an existing session cookie in the cookie store by sending an expired cookie in the response.
    response = cookieClientEndpoint->get("/cookie/removeSessionCookie");
    // Third request after removing the cookie.
    response = cookieClientEndpoint->get("/cookie/removeSessionCookie");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test to send requests by a client with Circuit Breaker, Retry and Cookie configurations are enabled
@test:Config {}
public isolated function testSendRequestsByClient() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-6.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1,
        retryConfig = {
            interval: 3,
            count: 3,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        circuitBreaker = {
            rollingWindow: {
                timeWindow: 10,
                bucketSize: 2,
                requestVolumeThreshold: 0
            },
            failureThreshold: 0.2,
            resetTime: 10,
            statusCodes: [400, 404, 500]
        },
        cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
     // Third request is with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34; SID001=239d4dmnmsddd34; SID002=178gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to remove a persistent cookie by the client
@test:Config {}
public function testRemovePersistentCookieByClient() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-7.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Removes a persistent cookie.
    http:CookieStore? myCookieStore = cookieClientEndpoint.getCookieStore();
    if myCookieStore is http:CookieStore {
        http:CookieHandlingError? removeResult =
            myCookieStore.removeCookie("SID001", string `localhost:${cookieTestPort1}`, "/cookie/addPersistentAndSessionCookies");
        if removeResult is http:CookieHandlingError {
            // log:printError("Error retrieving", 'error = removeResult);
        }
    }
    // Sends a request again after one persistent cookie is removed.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send similar persistent cookies in the response by server. The old cookie is
// replaced by the new cookie in the cookie store
@test:Config {}
public function testAddSimilarPersistentCookies() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-8.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends similar persistent cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentCookies");
    // Sends the second request after replacing the old cookie with the new.
    response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID001=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send a session cookie and a similar persistent cookie in the response by server.
// The old session cookie is replaced by the new persistent cookie in the cookie store
@test:Config {}
public function testSendSimilarPersistentAndSessionCookies_1() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-9.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends a session cookie and a similar persistent cookie in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentAndSessionCookies_1");
    // Sends the second request after replacing the session cookie with the new persistent cookie.
    response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentAndSessionCookies_1");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=aeaa895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send a persistent cookie and a similar session cookie in the response by the server.
// The old persistent cookie is replaced by the new session cookie in the cookie store
@test:Config {}
public function testSendSimilarPersistentAndSessionCookies_2() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-10.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends a persistent cookie and a similar session cookie in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentAndSessionCookies_2");
    // Sends the second request after replacing the persistent cookie with the new session cookie.
    response = cookieClientEndpoint->get("/cookie/sendSimilarPersistentAndSessionCookies_2");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to remove a persistent cookie by the server
@test:Config {}
public function testRemovePersistentCookieByServer() returns error? {
    http:CsvPersistentCookieHandler myPersistentStore = new("./cookie-test-data/client-11.csv");
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true, persistentCookieHandler: myPersistentStore });
    // Server sends cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/removePersistentCookieByServer");
    // Server removes an existing persistent cookie in the cookie store by sending an expired cookie in the response.
    response = cookieClientEndpoint->get("/cookie/removePersistentCookieByServer");
    // Third request is sent after removing the cookie.
    response = cookieClientEndpoint->get("/cookie/removePersistentCookieByServer");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID002=178gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    check file:remove("./cookie-test-data", file:RECURSIVE);
}

// Test to send persistent cookies when the persistentCookieHandler is not configured
@test:Config {}
public function testSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->get("/cookie/addPersistentAndSessionCookies");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test the cookie validation when using the getCookies()
@test:Config {}
public function testCookieValidation() returns error? {
    http:Client clientEP = check new(string `http://localhost:${cookieTestPort1}`, httpVersion = http:HTTP_1_1);
    http:Response|error response = clientEP->get("/cookie/validateCookie", {"Cookie":"user=John; asd=; =sdsdfsf; =gffg; "});
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Valid cookies: user=John,asd=,");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test for different client methods
// Test to send persistent cookies when the persistentCookieHandler is not configured
@test:Config {}
public function testPostSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->post("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->post("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->post("/cookie/addPersistentAndSessionCookiesDefault", "");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testPutSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->put("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->put("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->put("/cookie/addPersistentAndSessionCookiesDefault", "");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testPatchSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->patch("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->patch("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->patch("/cookie/addPersistentAndSessionCookiesDefault", "");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testDeleteSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->delete("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->delete("/cookie/addPersistentAndSessionCookiesDefault", "");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->delete("/cookie/addPersistentAndSessionCookiesDefault", "");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testHeadSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->head("/cookie/addPersistentAndSessionCookiesDefault");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->head("/cookie/addPersistentAndSessionCookiesDefault");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->head("/cookie/addPersistentAndSessionCookiesDefault");
    if response is error {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testOptionsSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->options("/cookie/addPersistentAndSessionCookiesDefault");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->options("/cookie/addPersistentAndSessionCookiesDefault");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->options("/cookie/addPersistentAndSessionCookiesDefault");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testExecuteSendPersistentCookiesWithoutPersistentCookieHandler() returns error? {
    http:Client cookieClientEndpoint = check new(string `http://localhost:${cookieTestPort1}`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    // Server sends the cookies in the response for the first request.
    http:Response|error response = cookieClientEndpoint->execute("GET",
        "/cookie/addPersistentAndSessionCookiesDefault", "");
    // Second request is with a cookie header and server sends more cookies in the response.
    response = cookieClientEndpoint->execute("GET", "/cookie/addPersistentAndSessionCookiesDefault", "");
    // Third request is sent with the cookie header including all relevant cookies.
    response = cookieClientEndpoint->execute("GET", "/cookie/addPersistentAndSessionCookiesDefault", "");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "SID003=895gd4dmnmsddd34");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
public function testCaseSensitiveDomain() returns error? {
    http:Client httpClient = check new(string `http://localhost:${cookieTestPort1}/cookieDemo`, 
        httpVersion = http:HTTP_1_1, cookieConfig = { enabled: true });
    http:Request request = new;
    json jsonPart = {
        name: "John",
        password: "p@ssw0rd"
    };
    request.setJsonPayload(jsonPart);
    http:Response|error loginResp = httpClient->post("/login", request);

    if loginResp is error {
        test:assertFail(msg = "Found unexpected output type: " + loginResp.message());
    } else {
        string welcomeResp = check httpClient->get("/welcome");
        test:assertEquals(welcomeResp, "Welcome back John");
    }
    return;
}

@test:Config {}
public function testCookieWithEmptyPath() returns error? {
    http:Client httpClient = check new (string `http://localhost:${cookieTestPort1}/cookies`, cookieConfig = {enabled: true});
    http:Response _ = check httpClient->get("");
    string result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `http://localhost:${cookieTestPort1}/cookies/path`, cookieConfig = {enabled: true});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `localhost:${cookieTestPort1}/cookies`, cookieConfig = {enabled: true});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `localhost:${cookieTestPort1}/cookies/path`, cookieConfig = {enabled: true});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `https://localhost:${cookieTestPort2}/cookies`, cookieConfig = {enabled: true}, secureSocket = {enable: false});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `https://localhost:${cookieTestPort2}/cookies/path`, cookieConfig = {enabled: true}, secureSocket = {enable: false});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `localhost:${cookieTestPort2}/cookies`, cookieConfig = {enabled: true}, secureSocket = {enable: false});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");

    httpClient = check new (string `localhost:${cookieTestPort2}/cookies/path`, cookieConfig = {enabled: true}, secureSocket = {enable: false});
    http:Response _ = check httpClient->get("");
    result = check httpClient->get("");
    test:assertEquals(result, "ballerina");
}