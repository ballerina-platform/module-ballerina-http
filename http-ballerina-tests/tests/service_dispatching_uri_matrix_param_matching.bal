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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;

listener http:Listener matrixEP = new(uriMatrixParamMatchingTest);
http:Client matrixClient = new("http://localhost:" + uriMatrixParamMatchingTest.toString());

@http:ServiceConfig {
    basePath:"/hello"
}
service testService on matrixEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/t1/{person}/bar/{yearParam}/foo"
    }
    resource function test1(http:Caller caller, http:Request req, string person, string yearParam) {
        http:Response res = new;
        map<json> outJson = {};
        outJson["pathParams"] = string `${person}, ${yearParam}`;

        map<any> personMParams = req.getMatrixParams(string `/hello/t1/${person}`);
        string age = <string> personMParams["age"];
        string color = <string> personMParams["color"];
        outJson["personMatrix"] = string `age=${age};color=${color}`;

        map<any> yearMParams = req.getMatrixParams(string `/hello/t1/${person}/bar/${yearParam}`);
        string monthValue = <string> yearMParams["month"];
        string dayValue = <string> yearMParams["day"];
        outJson["yearMatrix"] = string `month=${monthValue};day=${dayValue}`;

        map<any> fooMParams = req.getMatrixParams(string `/hello/t1/${person}/bar/${yearParam}/foo`);
        string a = <string> fooMParams["a"];
        string b = <string> fooMParams["b"];
        outJson["fooMatrix"] = string `a=${a};b=${b}`;

        map<string[]> queryParams = req.getQueryParams();
        string[]? x = queryParams["x"];
        string[]? y = queryParams["y"];
        string xVal = x is string[] ? x[0] : "";
        string yVal = y is string[] ? y[0] : "";
        outJson["queryParams"] = string `x=${xVal}&y=${yVal}`;

        res.setJsonPayload(<@untainted json> outJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/t2/{person}/foo%3Ba%3D5%3Bb%3D10"
    }
    resource function testEncoded(http:Caller caller, http:Request req, string person) {
        http:Response res = new;
        map<json> outJson = {};
        outJson["person"] = person;

        map<any> personMParams = req.getMatrixParams(string `/hello/t2/${person}`);
        outJson["personParamSize"] = personMParams.length();

        map<any> fooMParams = req.getMatrixParams(string `/hello/t2/${person}/foo`);
        outJson["fooParamSize"] = fooMParams.length();

        res.setJsonPayload(<@untainted json> outJson);
        checkpanic caller->respond(res);
    }
}

@test:Config {}
function testMatrixParamsAndQueryParamsMatching() {
    string path = "/hello/t1/john;age=10;color=white/bar/1991;month=may;day=12/foo;a=5;b=10?x=10&y=5";
    var response = matrixClient->get(path);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "pathParams", "john, 1991");
        assertJsonValue(response.getJsonPayload(), "personMatrix", "age=10;color=white");
        assertJsonValue(response.getJsonPayload(), "yearMatrix", "month=may;day=12");
        assertJsonValue(response.getJsonPayload(), "fooMatrix", "a=5;b=10");
        assertJsonValue(response.getJsonPayload(), "queryParams", "x=10&y=5");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEncodedPathDispatching() {
    string path = "/hello/t2/john;age=2;color=white/foo%3Ba%3D5%3Bb%3D10"; // encoded URI
    var response = matrixClient->get(path);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "person", "john");
        assertJsonValue(response.getJsonPayload(), "personParamSize", 2);
        assertJsonValue(response.getJsonPayload(), "fooParamSize", 0);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEncodedPathParamDispatching() {
    string path = "/hello/t2/john%3Bage%3D2%3Bcolor%3Dwhite/foo%3Ba%3D5%3Bb%3D10"; // encoded URI
    var response = matrixClient->get(path);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "person", "john;age=2;color=white");
        assertJsonValue(response.getJsonPayload(), "personParamSize", 0);
        assertJsonValue(response.getJsonPayload(), "fooParamSize", 0);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNonEncodedUrlDispatching() {
    string path = "/hello/t2/john;age=2;color=white/foo;a=5;b=10"; // encoded URI
    var response = matrixClient->get(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching resource found for path : /hello/t2/john/foo , method : GET");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testErrorReportInURI() {
    string path = "/hello/t2/john;age;color=white/foo;a=5;b=10"; // encoded URI
    var response = matrixClient->get(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "found non-matrix parameter 'age' in path 'hello/t2/john;age;color=white/foo;a=5;b=10'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
