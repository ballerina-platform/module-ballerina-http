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
import ballerina/http_test_common as common;

listener http:Listener http2RedirectServiceEndpoint1 = new (http2RedirectTestPort1);

listener http:Listener http2RedirectServiceEndpoint2 = new (http2RedirectTestPort2);

listener http:Listener http2RedirectServiceEndpoint3 = new (http2RedirectTestPort3);

final http:Client http2RedirectClient = check new ("http://localhost:" + http2RedirectTestPort1.toString());

final http:Client http2RedirectEndPoint1 = check new ("http://localhost:" + http2RedirectTestPort2.toString(),
    followRedirects = {enabled: true, maxCount: 3});

final http:Client http2RedirectEndPoint2 = check new ("http://localhost:" + http2RedirectTestPort2.toString(),
    followRedirects = {enabled: true, maxCount: 5});

final http:Client http2RedirectEndPoint3 = check new ("http://localhost:" + http2RedirectTestPort3.toString(),
    followRedirects = {enabled: true});

service /testHttp2Redirect on http2RedirectServiceEndpoint1 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint1->get("/redirect1");
        if response is http:Response {
            check caller->respond(response.resolvedRequestedURI);
        } else {
            io:println("Connector error!");
        }
    }

    resource function get maxRedirect(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint1->get("/redirect1/round1");
        if response is http:Response {
            string value = "";
            if (response.hasHeader(http:LOCATION)) {
                value = check response.getHeader(http:LOCATION);
            }
            value = value + ":" + response.resolvedRequestedURI;
            check caller->respond(value);
        } else {
            io:println("Connector error!");
        }
    }

    resource function get crossDomain(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint2->get("/redirect1/round1");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get noRedirect(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint3->get("/redirect2");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get qpWithRelativePath(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint2->get("/redirect1/qpWithRelativePath");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get qpWithAbsolutePath(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint2->get("/redirect1/qpWithAbsolutePath");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get originalRequestWithQP(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint2->get("/redirect1/round4?key=value&lang=ballerina");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get test303(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2RedirectEndPoint3->post("/redirect2/test303", "Test value!");
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                return value;
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }
}

service /redirect1 on http2RedirectServiceEndpoint2 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, ["http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2"]);
    }

    resource function get round1(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, ["/redirect1/round2"]);
    }

    resource function get round2(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_USE_PROXY_305, ["/redirect1/round3"]);
    }

    resource function get round3(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_MULTIPLE_CHOICES_300, ["/redirect1/round4"]);
    }

    resource function get round4(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_MOVED_PERMANENTLY_301, ["/redirect1/round5"]);
    }

    resource function get round5(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_FOUND_302, ["http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2"]);
    }

    resource function get qpWithRelativePath(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307,
                ["/redirect1/processQP?key=value&lang=ballerina"]);
    }

    resource function get qpWithAbsolutePath(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307,
                ["http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina"]);
    }

    resource function get processQP(http:Caller caller, http:Request req) returns error? {
        map<string[]> paramsMap = req.getQueryParams();
        string[]? val1 = paramsMap["key"];
        string[]? val2 = paramsMap["lang"];
        string returnVal = (val1 is string[] ? val1[0] : "") + ":" + (val2 is string[] ? val2[0] : "");
        check caller->respond(returnVal);
    }
}

service /redirect2 on http2RedirectServiceEndpoint3 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("hello world");
    }

    resource function post test303(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect2"]);
    }
}

//Test http redirection and test whether the resolvedRequestedURI in the response is correct.
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2Redirect() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//When the maximum redirect count is reached, client should do no more redirects.
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2MaxRedirect() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/maxRedirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "/redirect1/round5:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/round4");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Original request and the final redirect request goes to two different domains and the max redirect count gets equal to current redirect count
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2CrossDomain() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/crossDomain");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Redirect is on, but the first response received is not a redirect
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2NoRedirect() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/noRedirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Include query params in relative path of a redirect location
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2QPWithRelativePath() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/qpWithRelativePath");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "value:ballerina:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Include query params in absolute path of a redirect location
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2QPWithAbsolutePath() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/qpWithAbsolutePath");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "value:ballerina:http://localhost:" + http2RedirectTestPort2.toString() + "/redirect1/processQP?key=value&lang=ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test original request with query params. NOTE:Query params in the original request should be ignored while resolving redirect url
@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2OriginalRequestWithQP() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/originalRequestWithQP");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["http2Redirect"]
}
function testHTTP2303Status() returns error? {
    http:Response|error response = http2RedirectClient->get("/testHttp2Redirect/test303");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world:http://localhost:" + http2RedirectTestPort3.toString() + "/redirect2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
