// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/http;

listener http:Listener keepAliveListenerEP = new(keepAliveClientTestPort);
http:Client keepAliveClient = new("http://localhost:" + keepAliveClientTestPort.toString());

http:Client http_1_1_default = new("http://localhost:" + keepAliveClientTestPort.toString());

http:Client http_1_1_auto = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { http1Settings : { keepAlive: http:KEEPALIVE_AUTO }});

http:Client http_1_1_always = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { http1Settings : { keepAlive: http:KEEPALIVE_ALWAYS }});

http:Client http_1_1_never = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { http1Settings : { keepAlive: http:KEEPALIVE_NEVER }});

http:Client http_1_0_default = new("http://localhost:" + keepAliveClientTestPort.toString(), { httpVersion: "1.0" } );

http:Client http_1_0_auto = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { httpVersion: "1.0", http1Settings : { keepAlive: http:KEEPALIVE_AUTO }});

http:Client http_1_0_always = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { httpVersion: "1.0", http1Settings : { keepAlive: http:KEEPALIVE_ALWAYS }});

http:Client http_1_0_never = new("http://localhost:" + keepAliveClientTestPort.toString(),
                                 { httpVersion: "1.0", http1Settings : { keepAlive: http:KEEPALIVE_NEVER }});

service keepAliveTest on keepAliveListenerEP {

    @http:ResourceConfig {
        path: "/h1_1"
    }
    resource function h1_1_test(http:Caller caller, http:Request req) {
        var res1 = <http:Response> checkpanic http_1_1_default->post("/test", { "name": "Ballerina" });
        var res2 = <http:Response> checkpanic http_1_1_auto->post("/test", { "name": "Ballerina" });
        var res3 = <http:Response> checkpanic http_1_1_always->post("/test", { "name": "Ballerina" });
        var res4 = <http:Response> checkpanic http_1_1_never->post("/test", { "name": "Ballerina" });

        http:Response[] resArr = [res1, res2, res3, res4];
        string result = processResponse("http_1_1", resArr);
        checkpanic caller->respond(<@untainted> result);
    }

    @http:ResourceConfig {
        path: "/h1_0"
    }
    resource function h1_0_test(http:Caller caller, http:Request req) {
        var res1 = <http:Response> checkpanic http_1_0_default->post("/test", { "name": "Ballerina" });
        var res2 = <http:Response> checkpanic http_1_0_auto->post("/test", { "name": "Ballerina" });
        var res3 = <http:Response> checkpanic http_1_0_always->post("/test", { "name": "Ballerina" });
        var res4 = <http:Response> checkpanic http_1_0_never->post("/test", { "name": "Ballerina" });

        http:Response[] resArr = [res1, res2, res3, res4];
        string result = processResponse("http_1_0", resArr);
        checkpanic caller->respond(<@untainted> result);
    }
}
@http:ServiceConfig {basePath:"/test"}
service keepAliveTest2 on keepAliveListenerEP {
    @http:ResourceConfig {
        path: "/"
    }
    resource function echoResource(http:Caller caller, http:Request req) {
        string value;
        if (req.hasHeader("connection")) {
            value = req.getHeader("connection");
            if (req.hasHeader("keep-alive")) {
                value += "--" + req.getHeader("keep-alive");
            }
        } else {
            value = "No connection header found";
        }
        checkpanic caller->respond(value);
    }
}

function processResponse(string protocol, http:Response[] responseArr) returns @tainted string {
    string returnValue = protocol;
    foreach var response in responseArr {
       string payload = checkpanic response.getTextPayload();
       returnValue +=  "--" + payload;
    }
    return returnValue;
}

//Test keep-alive with HTTP clients.
@test:Config {}
function testWithHttp_1_1() {
    var response = keepAliveClient->get("/keepAliveTest/h1_1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "http_1_1--keep-alive--keep-alive--keep-alive--close");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWithHttp_1_0() {
    var response = keepAliveClient->get("/keepAliveTest/h1_0");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "http_1_0--close--close--keep-alive--close");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
