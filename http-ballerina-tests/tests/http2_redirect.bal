// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener http2RedirectServiceEndpoint1 = new(http2RedirectTestPort1, { httpVersion: "2.0" });

listener http:Listener http2RedirectServiceEndpoint2 = new(http2RedirectTestPort2, { httpVersion: "2.0" });

listener http:Listener http2RedirectServiceEndpoint3 = new(http2RedirectTestPort3, { httpVersion: "2.0" });


http:Client http2RedirectClient = new("http://localhost:" + http2RedirectTestPort1.toString());

http:Client http2RedirectEndPoint1 = new("http://localhost:" + http2RedirectTestPort2.toString(), {
    httpVersion: "2.0",
    followRedirects: { enabled: true, maxCount: 3 }
});

http:Client http2RedirectEndPoint2 = new("http://localhost:" + http2RedirectTestPort2.toString(), {
    httpVersion: "2.0",
    followRedirects: { enabled: true, maxCount: 5 }
});

http:Client http2RedirectEndPoint3 = new("http://localhost:" + http2RedirectTestPort3.toString(), {
    httpVersion: "2.0",
    followRedirects: { enabled: true }
});

@http:ServiceConfig {
    basePath: "/service1"
}
service testHttp2Redirect on http2RedirectServiceEndpoint1 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirectClient(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint1->get("/redirect1");
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response.resolvedRequestedURI);
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/maxRedirect"
    }
    resource function maxRedirectClient(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint1->get("/redirect1/round1");
        if (response is http:Response) {
            string value = "";
            if (response.hasHeader(http:LOCATION)) {
                value = response.getHeader(http:LOCATION);
            }
            value = value + ":" + response.resolvedRequestedURI;
            checkpanic caller->respond(<@untainted> value);
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/crossDomain"
    }
    resource function crossDomain(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint2->get("/redirect1/round1");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/noRedirect"
    }
    resource function noRedirect(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint3->get("/redirect2");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithRelativePath"
    }
    resource function qpWithRelativePath(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint2->get("/redirect1/qpWithRelativePath");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithAbsolutePath"
    }
    resource function qpWithAbsolutePath(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint2->get("/redirect1/qpWithAbsolutePath");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/originalRequestWithQP"
    }
    resource function originalRequestWithQP(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint2->get("/redirect1/round4?key=value&lang=ballerina");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/test303"
    }
    resource function test303(http:Caller caller, http:Request req) {
        var response = http2RedirectEndPoint3->post("/redirect2/test303", "Test value!");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                panic <error>value;
            }
        } else {
            io:println("Connector error!");
        }
    }
}

@http:ServiceConfig {
    basePath: "/redirect1"
}
service http2redirect1 on http2RedirectServiceEndpoint2 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirect1(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, ["http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/round1"
    }
    resource function round1(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, ["/redirect1/round2"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/round2"
    }
    resource function round2(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_USE_PROXY_305, ["/redirect1/round3"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/round3"
    }
    resource function round3(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_MULTIPLE_CHOICES_300, ["/redirect1/round4"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/round4"
    }
    resource function round4(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_MOVED_PERMANENTLY_301, ["/redirect1/round5"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/round5"
    }
    resource function round5(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_FOUND_302, ["http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithRelativePath"
    }
    resource function qpWithRelativePath(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307,
                ["/redirect1/processQP?key=value&lang=ballerina"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithAbsolutePath"
    }
    resource function qpWithAbsolutePath(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307,
                ["http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/processQP"
    }
    resource function processQP(http:Caller caller, http:Request req) {
        map<string[]> paramsMap = req.getQueryParams();
        string[]? val1 = paramsMap["key"];
        string[]? val2 = paramsMap["lang"];
        string returnVal = (val1 is string[] ? val1[0] : "") + ":" + (val2 is string[] ? val2[0] : "");
        checkpanic caller->respond(<@untainted> returnVal);
    }
}

@http:ServiceConfig {
    basePath: "/redirect2"
}
service http2redirect2 on http2RedirectServiceEndpoint3 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirect2(http:Caller caller, http:Request req) {
        checkpanic caller->respond("hello world");
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/test303"
    }
    resource function test303(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect2"]);
    }
}

//Test http redirection and test whether the resolvedRequestedURI in the response is correct.
@test:Config {}
function testHTTP2Redirect() {
    var response = http2RedirectClient->get("/service1/");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//When the maximum redirect count is reached, client should do no more redirects.
@test:Config {}
function testHTTP2MaxRedirect() {
    var response = http2RedirectClient->get("/service1/maxRedirect");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "/redirect1/round5:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/round4");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Original request and the final redirect request goes to two different domains and the max redirect count gets equal to current redirect count
@test:Config {}
function testHTTP2CrossDomain() {
    var response = http2RedirectClient->get("/service1/crossDomain");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Redirect is on, but the first response received is not a redirect
@test:Config {}
function testHTTP2NoRedirect() {
    var response = http2RedirectClient->get("/service1/noRedirect");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Include query params in relative path of a redirect location
@test:Config {}
function testHTTP2QPWithRelativePath() {
    var response = http2RedirectClient->get("/service1/qpWithRelativePath");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "value:ballerina:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Include query params in absolute path of a redirect location
@test:Config {}
function testHTTP2QPWithAbsolutePath() {
    var response = http2RedirectClient->get("/service1/qpWithAbsolutePath");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "value:ballerina:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test original request with query params. NOTE:Query params in the original request should be ignored while resolving redirect url
@test:Config {}
function testHTTP2OriginalRequestWithQP() {
    var response = http2RedirectClient->get("/service1/originalRequestWithQP");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/305
@test:Config {enable:false}
function testHTTP2303Status() {
    var response = http2RedirectClient->get("/service1/test303");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
