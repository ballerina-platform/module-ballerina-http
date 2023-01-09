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
import ballerina/http_test_common as common;

listener http:Listener keepAliveListenerEP = new (keepAliveClientTestPort, httpVersion = http:HTTP_1_1);
final http:Client keepAliveClient = check new ("http://localhost:" + keepAliveClientTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client http_1_1_default = check new ("http://localhost:" + keepAliveClientTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client http_1_1_auto = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_1, http1Settings = {keepAlive: http:KEEPALIVE_AUTO});

final http:Client http_1_1_always = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_1, http1Settings = {keepAlive: http:KEEPALIVE_ALWAYS});

final http:Client http_1_1_never = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_1, http1Settings = {keepAlive: http:KEEPALIVE_NEVER});

final http:Client http_1_0_default = check new ("http://localhost:" + keepAliveClientTestPort.toString(), httpVersion = http:HTTP_1_0);

final http:Client http_1_0_auto = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_0, http1Settings = {keepAlive: http:KEEPALIVE_AUTO});

final http:Client http_1_0_always = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_0, http1Settings = {keepAlive: http:KEEPALIVE_ALWAYS});

final http:Client http_1_0_never = check new ("http://localhost:" + keepAliveClientTestPort.toString(),
    httpVersion = http:HTTP_1_0, http1Settings = {keepAlive: http:KEEPALIVE_NEVER});

service /keepAliveTest on keepAliveListenerEP {

    resource function 'default h1_1(http:Caller caller, http:Request req) returns error? {
        http:Response res1 = check http_1_1_default->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res2 = check http_1_1_auto->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res3 = check http_1_1_always->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res4 = check http_1_1_never->post("/keepAliveTest2", {"name": "Ballerina"});

        http:Response[] resArr = [res1, res2, res3, res4];
        string result = check processResponse("http_1_1", resArr);
        check caller->respond(result);
    }

    resource function 'default h1_0(http:Caller caller, http:Request req) returns error? {
        http:Response res1 = check http_1_0_default->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res2 = check http_1_0_auto->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res3 = check http_1_0_always->post("/keepAliveTest2", {"name": "Ballerina"});
        http:Response res4 = check http_1_0_never->post("/keepAliveTest2", {"name": "Ballerina"});

        http:Response[] resArr = [res1, res2, res3, res4];
        string result = check processResponse("http_1_0", resArr);
        check caller->respond(result);
    }
}

service /keepAliveTest2 on keepAliveListenerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        string value;
        if req.hasHeader("connection") {
            value = check req.getHeader("connection");
            if req.hasHeader("keep-alive") {
                value += "--" + check req.getHeader("keep-alive");
            }
        } else {
            value = "No connection header found";
        }
        check caller->respond(value);
    }
}

function processResponse(string protocol, http:Response[] responseArr) returns string|error {
    string returnValue = protocol;
    foreach var response in responseArr {
        string payload = check response.getTextPayload();
        returnValue += "--" + payload;
    }
    return returnValue;
}

//Test keep-alive with HTTP clients.
@test:Config {}
function testWithHttp_1_1() returns error? {
    http:Response|error response = keepAliveClient->get("/keepAliveTest/h1_1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "http_1_1--keep-alive--keep-alive--keep-alive--close");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWithHttp_1_0() returns error? {
    http:Response|error response = keepAliveClient->get("/keepAliveTest/h1_0");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "http_1_0--close--close--keep-alive--close");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
