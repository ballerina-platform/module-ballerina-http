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

import ballerina/http;
import ballerina/test;

listener http:Listener QueryBindingEP = new(queryParamBindingTest);
http:Client queryBindingClient = new("http://localhost:" + queryParamBindingTest.toString());

service /queryparamservice on QueryBindingEP {

    resource function get .(string foo, http:Caller caller, int bar, http:Request req) {
        json responseJson = { value1: foo, value2: bar};
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    resource function get q1(int id, string PersoN, http:Caller caller, float val, boolean isPresent, decimal dc) {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    resource function get q2(int[] id, string[] PersoN, float[] val, boolean[] isPresent, 
            http:Caller caller, decimal[] dc) {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    resource function get q3(http:Caller caller, int? id, string? PersoN, float? val, 
            boolean? isPresent, decimal? dc) {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    resource function get q4(int[]? id, string[]? PersoN, float[]? val, boolean[]? isPresent, 
            http:Caller caller, decimal[]? dc) {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        checkpanic caller->respond(<@untainted json> responseJson);
    }
}

@test:Config {}
function testStringQueryBinding() {
    var response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=56");
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value1:"WSO2", value2:56});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice?foo=bal&bar=12");
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value1:"bal", value2:12});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Query params are case sensitive, https://tools.ietf.org/html/rfc7230#page-19
@test:Config {}
function testNegativeStringQueryBindingCaseSensitivity() {
    var response = queryBindingClient->get("/queryparamservice/?FOO=WSO2&bar=go");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'foo'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNegativeIntQueryBindingCastingError() {
    var response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=go");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500);
        assertTextPayload(response.getTextPayload(), "Error in casting query param : For input string: \"go\"");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeQueryBinding() {
    var response = queryBindingClient->get(
        "/queryparamservice/q1?id=324441&isPresent=true&dc=5.67&PersoN=hello&val=1.11");
    json expected = {iValue:324441, sValue:"hello", fValue: 1.11, bValue: true, dValue: 5.67};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q1?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67,2.34" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue:5652, sValue:"no", fValue: 53.9, bValue: false, dValue: 4.78 };
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeArrQueryBinding() {
    var response = queryBindingClient->get(
        "/queryparamservice/q2?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    json expected = {iValue:[324441, 5652], sValue:["hello", "gool"], fValue:[1.11, 53.9], 
            bValue:[true, false], dValue:[4.78, 5.67]};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryBinding() {
    var response = queryBindingClient->get("/queryparamservice/q3");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q3?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue:5652, sValue:"no", fValue: 53.9, bValue: false, dValue: 4.78};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryArrBinding() {
    var response = queryBindingClient->get("/queryparamservice/q4?ID=8?lang=bal");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q4?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    expected = {iValue:[324441, 5652], sValue:["hello", "gool"], fValue:[1.11, 53.9], 
            bValue:[true, false], dValue:[4.78, 5.67]};
    if (response is http:Response) {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
