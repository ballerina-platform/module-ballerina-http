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

listener http:Listener serviceEndpoint2 = new(9102);

listener http:Listener serviceEndpoint3 = new(9103);

http:ListenerConfiguration httpsEPConfig = {
    secureSocket: {
        keyStore: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

listener http:Listener httpsEP = new(9104, httpsEPConfig);

http:ClientConfiguration endPoint1Config = {
    followRedirects: { enabled: true, maxCount: 3 }
};

http:ClientConfiguration endPoint2Config = {
    followRedirects: { enabled: true, maxCount: 5 }
};

http:ClientConfiguration endPoint3Config = {
    followRedirects: { enabled: true }
};

http:ClientConfiguration endPoint4Config = {
    followRedirects: { enabled: true, allowAuthHeaders : true }
};

http:ClientConfiguration endPoint5Config = {
    followRedirects: { enabled: true },
    secureSocket: {
        trustStore: {
            path: "tests/certsandkeys/ballerinaTruststore.p12",
            password: "ballerina"
        }
    }
};

http:Client endPoint1 = new("http://localhost:9103", endPoint1Config );
http:Client endPoint2 = new("http://localhost:9103", endPoint2Config );
http:Client endPoint3 = new("http://localhost:9102", endPoint3Config );
http:Client endPoint4 = new("http://localhost:9103");
http:Client endPoint5 = new("https://localhost:9104", endPoint5Config );

@http:ServiceConfig {
    basePath: "/service1"
}
service testRedirectService on serviceEndpoint3 {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirectClient(http:Caller caller, http:Request req) {
        var response = endPoint1->get("/redirect1");
        http:Response finalResponse = new;
        if (response is http:Response) {
            finalResponse.setPayload(<@untainted> response.resolvedRequestedURI);
            checkpanic caller->respond(<@untainted> finalResponse);
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/maxRedirect"
    }
    resource function maxRedirectClient(http:Caller caller, http:Request req) {
        var response = endPoint1->get("/redirect1/round1");
        if (response is http:Response) {
            string value = "";
            if (response.hasHeader(http:LOCATION)) {
                value = response.getHeader(http:LOCATION);
            }
            value = value + ":" + response.resolvedRequestedURI;
            checkpanic caller->respond(<@untainted> value);
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/crossDomain"
    }
    resource function crossDomain(http:Caller caller, http:Request req) {
        var response = endPoint2->get("/redirect1/round1");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/noRedirect"
    }
    resource function NoRedirect(http:Caller caller, http:Request req) {
        var response = endPoint3->get("/redirect2");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithRelativePath"
    }
    resource function qpWithRelativePath(http:Caller caller, http:Request req) {
        var response = endPoint2->get("/redirect1/qpWithRelativePath");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else  {
                io:println("Payload error!");
            }
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithAbsolutePath"
    }
    resource function qpWithAbsolutePath(http:Caller caller, http:Request req) {
        var response = endPoint2->get("/redirect1/qpWithAbsolutePath");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else if (response is error) {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/originalRequestWithQP"
    }
    resource function originalRequestWithQP(http:Caller caller, http:Request req) {
        var response = endPoint2->get("/redirect1/round4?key=value&lang=ballerina");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
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
        var response = endPoint3->post("/redirect2/test303", "Test value!");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/redirectOff"
    }
    resource function redirectOff(http:Caller caller, http:Request req) {
        var response = endPoint4->get("/redirect1/round1");
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
        path: "/httpsRedirect"
    }
    resource function redirectWithHTTPs(http:Caller caller, http:Request req) {
        var response = endPoint5->get("/redirect3");
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/doPost"
    }
    resource function PostClearText(http:Caller caller, http:Request request) {
        http:Client endPoint4 = new("http://localhost:9103", endPoint4Config );
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Payload redirected");
        var response = endPoint4->post("/redirect1/handlePost", req);
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/doSecurePut"
    }
    resource function testSecurePut(http:Caller caller, http:Request request) {
        http:Request req = new;
        req.setHeader("Proxy-Authorization", "Basic YWxhZGRpbjpvcGVuc2VzYW1l");
        req.setTextPayload("Secure payload");
        var response = endPoint5->put("/redirect3/handlePost", req);
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/testMultipart"
    }
    resource function PostMultipart(http:Caller caller, http:Request req) {
        http:Client endPoint3 = new("http://localhost:9103", endPoint3Config );
        mime:Entity jsonBodyPart = new;
        jsonBodyPart.setContentDisposition(getContentDispositionForFormData("json part"));
        jsonBodyPart.setJson({"name": "wso2"});
        mime:Entity[] bodyParts = [jsonBodyPart];
        http:Request request = new;
        request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);

        var response = endPoint3->post("/redirect1/handlePost", request);
        if (response is http:Response) {
            var value = response.getTextPayload();
            if (value is string) {
                value = value + ":" + response.resolvedRequestedURI;
                checkpanic caller->respond(<@untainted> value);
            } else {
                io:println("Payload error!");
            }
        } else {
            io:println("Connector error!");
        }
    }
}

@http:ServiceConfig {
    basePath: "/redirect1"
}
service redirect1 on serviceEndpoint3 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirect1(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, ["http://localhost:9102/redirect2"]);
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
        checkpanic caller->redirect(res, http:REDIRECT_FOUND_302, ["http://localhost:9102/redirect2"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithRelativePath"
    }
    resource function qpWithRelativePath(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, ["/redirect1/processQP?key=value&lang=ballerina"
            ]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/qpWithAbsolutePath"
    }
    resource function qpWithAbsolutePath(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
                "http://localhost:9103/redirect1/processQP?key=value&lang=ballerina"]);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/processQP"
    }
    resource function processQP(http:Caller caller, http:Request req) {
        map<string[]> paramsMap = req.getQueryParams();
        string[]? arr1 = paramsMap["key"];
        string[]? arr2 = paramsMap["lang"];
        string returnVal = (arr1 is string[] ? arr1[0] : "") + ":" + (arr2 is string[] ? arr2[0] : "");
        checkpanic caller->respond(<@untainted> returnVal);
    }

    @http:ResourceConfig {
        methods: ["POST", "PUT"]
    }
    resource function handlePost(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_TEMPORARY_REDIRECT_307, [
                "http://localhost:9102/redirect2/echo"]);
    }
}

@http:ServiceConfig {
    basePath: "/redirect2"
}
service redirect2 on serviceEndpoint2 {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function redirect2(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setPayload("hello world");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/test303"
    }
    resource function test303(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect2"]);
    }

    @http:ResourceConfig {
        methods: ["POST", "PUT"]
    }
    resource function echo(http:Caller caller, http:Request req) {
        string hasAuthHeader = "No Proxy";
        if (req.hasHeader("Proxy-Authorization")) {
            hasAuthHeader = "Proxy";
        }



        var value = req.getTextPayload();
        if (value is string) {
            value = "Received:" + value + ":" + hasAuthHeader;
            checkpanic caller->respond(<@untainted> value);
        } else {
            http:Response res = new;
            var bodyParts = req.getBodyParts();
            if (bodyParts is mime:Entity[]) {
                foreach var part in bodyParts {
                    var payload = part.getJson();
                    if (payload is json) {
                        res.setPayload(<@untainted> payload);
                    } else {
                        res.setPayload(<@untainted> payload.message());
                    }
                    break; //Accepts only one part
                }
            } else {
                res.setPayload("Payload retrieval error!");
                res.statusCode = 500;
            }
            checkpanic caller->respond(res);
        }
    }
}

@http:ServiceConfig {
    basePath:"/redirect3"
}

service redirect3 on httpsEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function firstRedirect(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_SEE_OTHER_303, ["/redirect3/result"]);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/result"
    }
    resource function finalResult(http:Caller caller, http:Request req) {
        checkpanic caller->respond("HTTPs Result");
    }

    @http:ResourceConfig {
        methods: ["PUT"]
    }
    resource function handlePost(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, [
                "http://localhost:9103/redirect1/handlePost"]);
    }
}

@test:Config {}
public function testHttpRedirects() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "http://localhost:9102/redirect2");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testMaxRedirect() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/maxRedirect");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "/redirect1/round5:http://localhost:9103/redirect1/round4");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testCrossDomain() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/noRedirect");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "hello world:http://localhost:9102/redirect2");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testNoRedirect() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/crossDomain");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "hello world:http://localhost:9102/redirect2");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testRedirectOff() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/redirectOff");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "/redirect1/round2:");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testQPWithRelativePath() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/qpWithRelativePath");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "value:ballerina:http://localhost:9103/redirect1/processQP?key=value&lang=ballerina");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testQPWithAbsolutePath() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/qpWithAbsolutePath");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "value:ballerina:http://localhost:9103/redirect1/processQP?key=value&lang=ballerina");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testOriginalRequestWithQP() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/originalRequestWithQP");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "hello world:http://localhost:9102/redirect2");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function test303Status() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/test303");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "hello world:http://localhost:9102/redirect2");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testRedirectWithHTTPs() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/httpsRedirect");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "HTTPs Result:https://localhost:9104/redirect3/result");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testRedirectWithPOST() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/doPost");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "Received:Payload redirected:Proxy:http://localhost:9102/redirect2/echo");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testWithHTTPs() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/doSecurePut");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "Received:Secure payload:No Proxy:http://localhost:9102/redirect2/echo");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testMultipartRedirect() {
    http:Client httpClient = new("http://localhost:9103");
    var resp = httpClient->get("/service1/testMultipart");
    if (resp is http:Response) {
        assertRedirectResponse(resp, "{\"name\":\"wso2\"}:http://localhost:9102/redirect2/echo");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

public function assertRedirectResponse(http:Response response, string expected) {
    var body = response.getTextPayload();
    if (body is string) {
        test:assertEquals(body, expected, msg = errorMessage);
    } else {
        test:assertFail(msg = errorMessage + body.message());
    }
}
