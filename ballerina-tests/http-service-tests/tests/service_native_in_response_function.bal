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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

@test:Config {}
function testResponseNegativeContentType() returns error? {
    http:Response res = new;
    check res.setContentType("application/x-custom-type+json");
    test:assertEquals(res.getContentType(), "application/x-custom-type+json", msg = "Content type mismatched");
}

@test:Config {}
function testResposeGetContentLength() returns error? {
    http:Response res = new;
    string length = "Ballerina".length().toString();
    res.setHeader("content-length", length);
    test:assertEquals(check res.getHeader("content-length"), length, msg = "Content length mismatched");
}

@test:Config {}
function testResposeAddHeader() returns error? {
    http:Response res = new;
    string key = "lang";
    string value = "Ballerina";
    res.addHeader(key, value);
    test:assertEquals(check res.getHeader(key), value, msg = "Value mismatched");
}

@test:Config {}
function testResposeGetHeader() returns error? {
    http:Response res = new;
    string key = "lang";
    string value = "Ballerina";
    res.addHeader(key, value);
    test:assertEquals(check res.getHeader(key), value, msg = "Value mismatched");
}

@test:Config {}
function testResposeGetHeaders() returns error? {
    http:Response res = new;
    string key = "header1";
    string value = "abc, xyz";
    res.setHeader(key, "1stHeader");
    res.addHeader(key, value);
    string[] headers = check res.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Header value mismatched");
    test:assertEquals(headers[1], "abc, xyz", msg = "Header value mismatched");
}

@test:Config {}
function testResposeGetJsonPayload() {
    http:Response res = new;
    json value = {name: "wso2"};
    res.setJsonPayload(value);
    test:assertEquals(res.getJsonPayload(), value, msg = "Json payload mismatched");
}

@test:Config {}
function testResposeGetTextPayload() {
    http:Response res = new;
    string value = "Ballerina";
    res.setTextPayload(value);
    test:assertEquals(res.getTextPayload(), value, msg = "String payload mismatched");
}

@test:Config {}
function testResposeGetBinaryPayload() {
    http:Response res = new;
    byte[] value = [5];
    res.setBinaryPayload(value);
    test:assertEquals(res.getBinaryPayload(), value, msg = "Binary payload mismatched");
}

@test:Config {}
function testResposeGetXmlPayload() {
    http:Response res = new;
    xml value = xml `<name>Ballerina</name>`;
    res.setXmlPayload(value);
    test:assertEquals(res.getXmlPayload(), value, msg = "Xml payload mismatched");
}

@test:Config {}
function testResposeSetPayloadAndGetText() {
    http:Response res = new;
    string value = "Hello Ballerina !";
    res.setPayload(value);
    test:assertEquals(res.getTextPayload(), value, msg = "Xml payload mismatched");
}

@test:Config {}
function testResposeRemoveHeader() {
    http:Response res = new;
    res.setHeader("Expect", "100-continue");
    res.removeHeader("Expect");
    error|string output = res.getHeader("Expect");
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Outptut mismatched");
    }
}

@test:Config {}
function testResposeRemoveAllHeaders() {
    http:Response res = new;
    res.setHeader("Expect", "100-continue");
    res.setHeader("Expect1", "100-continue1");
    res.removeAllHeaders();
    error|string output = res.getHeader("Expect1");
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Outptut mismatched");
    }
}

@test:Config {}
function testResposeSetHeader() returns error? {
    http:Response res = new;
    string key = "lang";
    string value = "ballerina; a=6";
    res.setHeader(key, "abc");
    res.setHeader(key, value);
    test:assertEquals(check res.getHeader(key), value, msg = "Header value mismatched");
}

@test:Config {}
function testResposeSetJsonPayload() {
    http:Response res = new;
    json value = {name: "wso2"};
    res.setJsonPayload(value);
    test:assertEquals(res.getJsonPayload(), value, msg = "Json payload mismatched");
}

@test:Config {}
function testResposeSetStringPayload() {
    string value = "Ballerina";
    http:Response res = new;
    res.setTextPayload(value);
    test:assertEquals(res.getTextPayload(), value, msg = "Mismatched string payload");
}

@test:Config {}
function testResposeSetXmlPayload() {
    xml value = xml `<name>Ballerina</name>`;
    http:Response res = new;
    res.setXmlPayload(value);
    test:assertEquals(res.getXmlPayload(), value, msg = "Mismatched xml payload");
}

@test:Config {}
function testResposeAddCookie() {
    http:Response res = new;
    http:Cookie cookie = new ("SID3", "31d4d96e407aad42", path = "/sample", domain = "google.com", maxAge = 3600,
        expires = "2017-06-26 05:46:22", httpOnly = true, secure = true);
    res.addCookie(cookie);
    http:Cookie[] cookiesInRequest = res.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID3", msg = "Invalid cookie name");
}

@test:Config {}
function testResposeRemoveCookiesFromRemoteStore() {
    http:Response res = new;
    http:Cookie cookie = new ("SID3", "31d4d96e407aad42", expires = "2017-06-26 05:46:22");
    res.removeCookiesFromRemoteStore(cookie);
    http:Cookie[] cookiesInRequest = res.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
}

@test:Config {}
function testResposeGetCookies() {
    http:Response res = new;
    http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = ".GOOGLE.com.", maxAge = 3600,
        expires = "2017-06-26 05:46:22", httpOnly = true, secure = true);
    res.addCookie(cookie1);
    // Gets the added cookies from response.
    http:Cookie[] cookiesInResponse = res.getCookies();
    test:assertEquals(cookiesInResponse.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInResponse[0].name, "SID002", msg = "Invalid cookie name");
}

listener http:Listener responseEp = new (responseTestPort, httpVersion = http:HTTP_1_1);

service /response on responseEp {

    resource function get eleven(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->respond(res);
    }

    resource function get twelve/[string phase](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.reasonPhrase = phase;
        check caller->respond(res);
    }

    resource function get thirteen(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.statusCode = 203;
        check caller->respond(res);
    }

    resource function get addheader/[string key]/[string value](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.addHeader(key, value);
        string result = check res.getHeader(key);
        res.setJsonPayload({lang: result});
        check caller->respond(res);
    }

    resource function get getHeader/[string header]/[string value](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader(header, value);
        string result = check res.getHeader(header);
        res.setJsonPayload({value: result});
        check caller->respond(res);
    }

    resource function get getJsonPayload/[string value](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json jsonStr = {lang: value};
        res.setJsonPayload(jsonStr);
        var returnResult = res.getJsonPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(check returnResult.lang);
        }
        check caller->respond(res);
    }

    resource function get GetTextPayload/[string valueStr](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload(valueStr);
        var returnResult = res.getTextPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setTextPayload(returnResult);
        }
        check caller->respond(res);
    }

    resource function get GetXmlPayload(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        xml xmlStr = xml `<name>ballerina</name>`;
        res.setXmlPayload(xmlStr);
        var returnResult = res.getXmlPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = (returnResult/*).toString();
            res.setTextPayload(<string>name);
        }
        check caller->respond(res);
    }

    resource function get RemoveHeader/[string key]/[string value](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader(key, value);
        res.removeHeader(key);
        string header = "";
        if (!res.hasHeader(key)) {
            header = "value is null";
        }
        res.setJsonPayload({value: header});
        check caller->respond(res);
    }

    resource function get RemoveAllHeaders(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Expect", "100-continue");
        res.setHeader("Range", "bytes=500-999");
        res.removeAllHeaders();
        string header = "";
        if (!res.hasHeader("Range")) {
            header = "value is null";
        }
        res.setJsonPayload({value: header});
        check caller->respond(res);
    }

    resource function get addCookie(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:Cookie cookie = new ("SID3", "31d4d96e407aad42", path = "/sample", domain = "google.com", maxAge = 3600,
            expires = "2017-06-26 05:46:22", httpOnly = true, secure = true);
        res.addCookie(cookie);
        string result = check res.getHeader("Set-Cookie");
        res.setJsonPayload({SetCookieHeader: result});
        check caller->respond(res);
    }

    resource function get removeCookieByServer(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:Cookie cookie = new ("SID3", "31d4d96e407aad42", expires = "2017-06-26 05:46:22");
        res.removeCookiesFromRemoteStore(cookie);
        string result = check res.getHeader("Set-Cookie");
        res.setJsonPayload({SetCookieHeader: result});
        check caller->respond(res);
    }

    resource function get getCookies(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:Cookie cookie1 = new ("SID002", "239d4dmnmsddd34", path = "/sample", domain = ".GOOGLE.com.", maxAge = 3600,
            expires = "2017-06-26 05:46:22", httpOnly = true, secure = true);
        res.addCookie(cookie1);
        //Gets the added cookies from response.
        http:Cookie[] cookiesInResponse = res.getCookies();
        string result = <string>cookiesInResponse[0].name;
        res.setJsonPayload({cookie: result});
        check caller->respond(res);
    }
}

final http:Client responseClient = check new ("http://localhost:" + responseTestPort.toString(), httpVersion = http:HTTP_1_1);

// Test addHeader function within a service
@test:Config {}
function testResponseServiceAddHeader() {
    string key = "lang";
    string value = "ballerina";
    string path = "/response/addheader/" + key + "/" + value;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {lang: "ballerina"});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetHeader function within a service
@test:Config {}
function testResponseServiceGetHeader() {
    string value = "test-header-value";
    string path = "/response/getHeader/" + "test-header-name" + "/" + value;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value: value});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetJsonPayload function within a service
@test:Config {}
function testResponseServiceGetJsonPayload() {
    string value = "ballerina";
    string path = "/response/getJsonPayload/" + value;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), value);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetTextPayload function within a service
@test:Config {}
function testResponseServiceGetTextPayload() {
    string value = "ballerina";
    string path = "/response/GetTextPayload/" + value;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), value);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetXmlPayload function within a service
@test:Config {}
function testResponseServiceGetXmlPayload() {
    string value = "ballerina";
    string path = "/response/GetXmlPayload";
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), value);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testForwardMethod() {
    string path = "/response/eleven";
    http:Response|error response = responseClient->get(path);
    test:assertTrue(response is http:Response, msg = "Found unexpected output");
}

// Test RemoveHeader function within a service
@test:Config {}
function testResponseServiceRemoveHeader() {
    string value = "x-www-form-urlencoded";
    string path = "/response/RemoveHeader/Content-Type/" + value;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "{\"value\":\"value is null\"}");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test RemoveAllHeaders function within a service
@test:Config {}
function testResponseServiceRemoveAllHeaders() {
    string path = "/response/RemoveAllHeaders";
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "{\"value\":\"value is null\"}");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testRespondMethod() {
    string path = "/response/eleven";
    http:Response|error response = responseClient->get(path);
    test:assertTrue(response is http:Response, msg = "Found unexpected output");
}

@test:Config {}
function testSetReasonPhase() {
    string phase = "ballerina";
    string path = "/response/twelve/" + phase;
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        test:assertEquals(response.reasonPhrase, phase);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testSetStatusCode() {
    string path = "/response/thirteen";
    http:Response|error response = responseClient->get(path);
    if response is http:Response {
        test:assertEquals(response.statusCode, 203);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testTrailingAddHeader() returns error? {
    http:Response res = new;
    string headerName = "Max-Forwards";
    string headerValue = "eighty two";
    string retrieval = "max-forwards";
    res.addHeader(headerName, headerValue, position = "trailing");
    test:assertEquals(check res.getHeader(retrieval, position = "trailing"), "eighty two");
}

@test:Config {}
function testAddingMultipleValuesToSameTrailingHeader() returns error? {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    string[] output = check res.getHeaders("header1", position = "trailing");
    test:assertEquals(check res.getHeader("header1", position = "trailing"), "value1");
    test:assertEquals(output.length(), 2);
    test:assertEquals(output[0], "value1");
    test:assertEquals(output[1], "value2");
}

@test:Config {}
function testSetTrailingHeaderAfterAddHeader() returns error? {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    res.addHeader("hEader2", "value3", position = "trailing");
    string[] output = check res.getHeaders("header1", position = "trailing");
    test:assertEquals(check res.getHeader("header2", position = "trailing"), "value3");
    test:assertEquals(output.length(), 2);
    test:assertEquals(output[0], "value1");
    test:assertEquals(output[1], "value2");
}

@test:Config {}
function testRemoveTrailingHeader() returns error? {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    res.addHeader("header1", "value3", position = "trailing");
    res.addHeader("hEader2", "value3", position = "trailing");
    res.addHeader("headeR2", "value4", position = "trailing");
    res.setHeader("HeADEr2", "totally different value", position = "trailing");
    res.removeHeader("HEADER1", position = "trailing");
    res.removeHeader("NONE_EXISTENCE_HEADER", position = "trailing");
    string[]|error output = res.getHeaders("header1", position = "trailing");
    test:assertEquals(check res.getHeader("header2", position = "trailing"), "totally different value");
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testNonExistenceTrailingHeader() {
    http:Response res = new;
    string headerName = "heAder1";
    string headerValue = "value1";
    res.addHeader(headerName, headerValue, position = http:TRAILING);
    error|string output = res.getHeader("header", position = http:TRAILING);
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testGetTrailingHeaderNames() {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = http:TRAILING);
    res.addHeader("header1", "value2", position = http:TRAILING);
    res.addHeader("header1", "value3", position = http:TRAILING);
    res.addHeader("hEader2", "value3", position = http:TRAILING);
    res.addHeader("headeR2", "value4", position = http:TRAILING);
    res.addHeader("HeADEr2", "totally different value", position = http:TRAILING);
    res.addHeader("HEADER3", "testVal", position = http:TRAILING);
    string[] output = res.getHeaderNames(position = http:TRAILING);
    test:assertEquals(output.length(), 3);
    test:assertEquals(output[0], "heAder1", msg = "Outptut mismatched");
    test:assertEquals(output[1], "hEader2", msg = "Outptut mismatched");
    test:assertEquals(output[2], "HEADER3", msg = "Outptut mismatched");
}

@test:Config {}
function testTrailingHasHeader() {
    http:Response res = new;
    string headerName = "heAder1";
    string headerValue = "value1";
    res.setHeader(headerName, headerValue, position = http:TRAILING);
    test:assertTrue(res.hasHeader("header1", position = http:TRAILING));
}

@test:Config {}
function testTrailingHeaderWithNewEntity() {
    http:Response res = new;
    test:assertFalse(res.hasHeader("header1", position = http:TRAILING));
    string[] output = res.getHeaderNames(position = http:TRAILING);
    test:assertEquals(output.length(), 0, msg = "Outptut mismatched");
}
