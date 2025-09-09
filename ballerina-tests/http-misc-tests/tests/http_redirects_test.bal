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

import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener serviceEndpoint2 = new (redirectTestPort1, httpVersion = http:HTTP_1_1);

listener http:Listener serviceEndpoint3 = new (redirectTestPort2, httpVersion = http:HTTP_1_1);

http:ListenerConfiguration httpsEPConfig = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener httpsEP = new (redirectTestPort3, httpsEPConfig);

http:ClientConfiguration endPoint1Config = {
    httpVersion: http:HTTP_1_1,
    followRedirects: {enabled: true, maxCount: 3}
};

http:ClientConfiguration endPoint2Config = {
    httpVersion: http:HTTP_1_1,
    followRedirects: {enabled: true, maxCount: 5}
};

// Type should be `final readonly & http:ClientConfiguration` to preserve the isolated root inside an isolated
// resource. But it is not possible until https://github.com/ballerina-platform/ballerina-spec/issues/544 is fixed
final http:ClientConfiguration endPoint3Config = {
    httpVersion: http:HTTP_1_1,
    followRedirects: {enabled: true}
};

http:ClientConfiguration endPoint5Config = {
    httpVersion: http:HTTP_1_1,
    followRedirects: {enabled: true},
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
};

final http:Client endPoint1 = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1, followRedirects = {enabled: true, maxCount: 3});
final http:Client endPoint2 = check new (string `http://localhost:${redirectTestPort2}`, endPoint2Config);
final http:Client endPoint3 = check new (string `http://localhost:${redirectTestPort1}`, endPoint3Config);
final http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
final http:Client endPoint5 = check new (string `https://localhost:${redirectTestPort3}`, endPoint5Config);

service /testRedirectService on serviceEndpoint3 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint1->get("/redirect1");
        http:Response finalResponse = new;
        if response is http:Response {
            finalResponse.setPayload(response.resolvedRequestedURI);
            check caller->respond(finalResponse);
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get maxRedirect(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint1->get("/redirect1/round1");
        if response is http:Response {
            string value = "";
            if response.hasHeader(http:LOCATION) {
                value = check response.getHeader(http:LOCATION);
            }
            value = value + ":" + response.resolvedRequestedURI;
            check caller->respond(value);
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get crossDomain(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint2->get("/redirect1/round1");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get noRedirect(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint3->get("/redirect2");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get qpWithRelativePath(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint2->get("/redirect1/qpWithRelativePath");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get qpWithAbsolutePath(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint2->get("/redirect1/qpWithAbsolutePath");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get originalRequestWithQP(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint2->get("/redirect1/round4?key=value&lang=ballerina");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get test303(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint3->post("/redirect2/test303", "Test value!");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get redirectOff(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint4->get("/redirect1/round1");
        if response is http:Response {
            string value = "";
            if response.hasHeader(http:LOCATION) {
                value = check response.getHeader(http:LOCATION);
            }
            value = value + ":" + response.resolvedRequestedURI;
            check caller->respond(value);
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get httpsRedirect(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint5->get("/redirect3");
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doPost(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Payload redirected");
        http:Response|error response = endPoint4->post("/redirect1/handlePost", req);
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doHead(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Response|error response = endPoint4->head("/redirect1/handleHead", {"X-Redirect-Action": "HTTP_TEMPORARY_REDIRECT"});
        if response is http:Response {
            var value = response.getHeader("X-Redirect-Details");
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doExecute(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Payload redirected");
        http:Response|error response = endPoint4->execute("POST", "/redirect1/handlePost", req);
        if response is http:Response {
            var value = response.getTextPayload();
            if value is string {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doPatch(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Payload redirected");
        http:Response|error response = endPoint4->patch("/redirect1/handlePost", req);
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doDelete(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Payload redirected");
        http:Response|error response = endPoint4->delete("/redirect1/handlePost", req);
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doOptions(http:Caller caller, http:Request request) returns error? {
        http:ClientConfiguration endPoint4Config = {
            httpVersion: http:HTTP_1_1,
            followRedirects: {enabled: true, allowAuthHeaders: true}
        };
        http:Client endPoint4 = check new (string `http://localhost:${redirectTestPort2}`, endPoint4Config);
        http:Response|error response = endPoint4->options("/redirect1/handleOptions");
        if response is http:Response {
            var value = response.getHeader("Allow");
            if (value is string) {
                value = "Received:" + value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get doSecurePut(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Secure payload");
        http:Response|error response = endPoint5->put("/redirect3/handlePost", req);
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }

    resource function get testMultipart(http:Caller caller, http:Request req) returns error? {
        http:Client endPoint3 = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1, followRedirects = {enabled: true});
        mime:Entity jsonBodyPart = new;
        jsonBodyPart.setContentDisposition(common:getContentDispositionForFormData("json part"));
        jsonBodyPart.setJson({"name": "wso2"});
        mime:Entity[] bodyParts = [jsonBodyPart];
        http:Request request = new;
        request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);

        http:Response|error response = endPoint3->post("/redirect1/handlePost", request);
        if response is http:Response {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                check caller->respond(check value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
        return;
    }
}

service /redirect1 on serviceEndpoint3 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [string `http://localhost:${redirectTestPort1}/redirect2`]);
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
        check caller->redirect(res, http:REDIRECT_FOUND_302, [string `http://localhost:${redirectTestPort1}/redirect2`]);
    }

    resource function get qpWithRelativePath(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
            "/redirect1/processQP?key=value&lang=ballerina"
        ]);
    }

    resource function get qpWithAbsolutePath(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
            string `http://localhost:${redirectTestPort2}/redirect1/processQP?key=value&lang=ballerina`
        ]);
    }

    resource function get processQP(http:Caller caller, http:Request req) returns error? {
        map<string[]> paramsMap = req.getQueryParams();
        string[]? arr1 = paramsMap["key"];
        string[]? arr2 = paramsMap["lang"];
        string returnVal = (arr1 is string[] ? arr1[0] : "") + ":" + (arr2 is string[] ? arr2[0] : "");
        check caller->respond(returnVal);
    }

    resource function head handleHead(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
            string `http://localhost:${redirectTestPort1}/redirect2/echo`
        ]);
    }

    resource function options handleOptions(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
            string `http://localhost:${redirectTestPort1}/redirect2/echo`
        ]);
    }

    resource function 'default handlePost(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
            string `http://localhost:${redirectTestPort1}/redirect2/echo`
        ]);
    }
}

service /redirect2 on serviceEndpoint2 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setPayload("hello world");
        check caller->respond(res);
    }

    resource function post test303(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect2"]);
    }

    resource function options echo(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Allow", "OPTIONS, HEAD");
        check caller->respond(res);
    }

    resource function 'default echo(http:Caller caller, http:Request req) returns error? {
        string hasAuthHeader = "No Proxy";
        if (req.hasHeader("Proxy-Authorization")) {
            hasAuthHeader = "Proxy";
        }
        var value = req.getTextPayload();
        if (value is string) {
            value = string `Received:${value}:${hasAuthHeader}`;
            check caller->respond(check value);
        } else if (req.hasHeader("X-Redirect-Action")) {
            string redirectActionName = check req.getHeader("X-Redirect-Action");
            string message = string `Received:${hasAuthHeader}:${redirectActionName}`;
            http:Response res = new;
            res.setHeader("X-Redirect-Details", message);
            check caller->respond(res);
        } else {
            http:Response res = new;
            var bodyParts = req.getBodyParts();
            if (bodyParts is mime:Entity[]) {
                foreach var part in bodyParts {
                    var payload = part.getJson();
                    if (payload is json) {
                        res.setPayload(payload);
                    } else {
                        res.setPayload(payload.message());
                    }
                    break; //Accepts only one part
                }
            } else {
                res.setPayload("Payload retrieval error!");
                res.statusCode = 500;
            }
            check caller->respond(res);
        }
        return;
    }
}

service /redirect3 on httpsEP {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect3/result"]);
    }

    resource function get result(http:Caller caller, http:Request req) returns error? {
        check caller->respond("HTTPs Result");
    }

    resource function put handlePost(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, [
            string `http://localhost:${redirectTestPort2}/redirect1/handlePost`
        ]);
    }
}

listener http:Listener httpsAuthEP = new (redirectTestPort4, httpsEPConfig);

listener http:Listener externalRedirectedEP = new (redirectTestPort5, httpVersion = http:HTTP_1_1);

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ]
}
service /api on httpsAuthEP {

    resource function get redirect(boolean 'external = false) returns http:Found {
        string redirectUrl = 'external ?
            string `http://localhost:${redirectTestPort5}/api/hello` :
            string `https://localhost:${redirectTestPort4}/api/hello`;
        return {
            headers: {
                "Location": redirectUrl
            }
        };
    }

    resource function get hello() returns string {
        return "Hello, World!";
    }
}

service /api on externalRedirectedEP {

    resource function get hello(@http:Header string? Authorization) returns string {
        return Authorization is string ? "Hello, authenticated user!" : "Hello from external service!";
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithAllowAuthHeaders() returns error? {
    http:ClientConfiguration clientConfig = {
        httpVersion: http:HTTP_1_1,
        followRedirects: {enabled: true, allowAuthHeaders: true},
        auth: {
            username: "alice",
            password: "xxx"
        },
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    };
    http:Client httpClient = check new (string `https://localhost:${redirectTestPort4}/api`, clientConfig);
    string|error resp = httpClient->/redirect;
    if resp is string {
        test:assertEquals(resp, "Hello, World!");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = httpClient->/redirect('external = true);
    if resp is string {
        test:assertEquals(resp, "Hello, authenticated user!");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithoutAuthHeaders() returns error? {
    http:ClientConfiguration clientConfig = {
        httpVersion: http:HTTP_1_1,
        followRedirects: {enabled: true, allowAuthHeaders: false},
        auth: {
            username: "alice",
            password: "xxx"
        },
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    };
    http:Client httpClient = check new (string `https://localhost:${redirectTestPort4}/api`, clientConfig);
    string|error resp = httpClient->/redirect;
    if resp is error {
        test:assertEquals(resp.message(), "Unauthorized");
    } else {
        test:assertFail(msg = "Expected an error but found: " + resp);
    }

    resp = httpClient->/redirect('external = true);
    if resp is string {
        test:assertEquals(resp, "Hello from external service!");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testHttpRedirects() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/");
    if resp is http:Response {
        assertRedirectResponse(resp, string `http://localhost:${redirectTestPort1}/redirect2`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testMaxRedirect() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/maxRedirect");
    if resp is http:Response {
        assertRedirectResponse(resp, string `/redirect1/round5:http://localhost:${redirectTestPort2}/redirect1/round4`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testCrossDomain() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/noRedirect");
    if resp is http:Response {
        assertRedirectResponse(resp, string `hello world:http://localhost:${redirectTestPort1}/redirect2`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testNoRedirect() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/crossDomain");
    if resp is http:Response {
        assertRedirectResponse(resp, string `hello world:http://localhost:${redirectTestPort1}/redirect2`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectOff() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/redirectOff");
    if resp is http:Response {
        assertRedirectResponse(resp, "/redirect1/round2:");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testQPWithRelativePath() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/qpWithRelativePath");
    if resp is http:Response {
        assertRedirectResponse(resp, string `value:ballerina:http://localhost:${redirectTestPort2}/redirect1/processQP?key=value&lang=ballerina`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testQPWithAbsolutePath() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/qpWithAbsolutePath");
    if resp is http:Response {
        assertRedirectResponse(resp, string `value:ballerina:http://localhost:${redirectTestPort2}/redirect1/processQP?key=value&lang=ballerina`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testOriginalRequestWithQP() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/originalRequestWithQP");
    if resp is http:Response {
        assertRedirectResponse(resp, string `hello world:http://localhost:${redirectTestPort1}/redirect2`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function test303Status() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/test303");
    if resp is http:Response {
        assertRedirectResponse(resp, string `hello world:http://localhost:${redirectTestPort1}/redirect2`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithHTTPs() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/httpsRedirect");
    if resp is http:Response {
        assertRedirectResponse(resp, string `HTTPs Result:https://localhost:${redirectTestPort3}/redirect3/result`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithPOST() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doPost");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:Payload redirected:Proxy:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithHead() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doHead");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:No Proxy:HTTP_TEMPORARY_REDIRECT:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithExecute() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doExecute");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:Payload redirected:Proxy:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithPatch() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doPatch");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:Payload redirected:Proxy:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithDelete() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doDelete");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:Payload redirected:Proxy:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testRedirectWithOptions() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doOptions");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:OPTIONS, HEAD:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testWithHTTPs() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/doSecurePut");
    if resp is http:Response {
        assertRedirectResponse(resp, string `Received:Secure payload:No Proxy:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    groups: ["httpRedirect"]
}
public function testMultipartRedirect() returns error? {
    http:Client httpClient = check new (string `http://localhost:${redirectTestPort2}`, httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/testRedirectService/testMultipart");
    if resp is http:Response {
        assertRedirectResponse(resp, string `{"name":"wso2"}:http://localhost:${redirectTestPort1}/redirect2/echo`);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

public function assertRedirectResponse(http:Response response, string expected) {
    var body = response.getTextPayload();
    if (body is string) {
        test:assertEquals(body, expected, msg = common:errorMessage);
    } else {
        test:assertFail(msg = common:errorMessage + body.message());
    }
}
