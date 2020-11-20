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

@test:Config {}
function testResponseNegativeContentType() {
    http:Response res = new;
    checkpanic res.setContentType("application/x-custom-type+json");
    test:assertEquals(res.getContentType(), "application/x-custom-type+json", msg = "Content type mismatched");
}

@test:Config {}
function testResposeGetContentLength() {
    http:Response res = new;
    string length = "Ballerina".length().toString();
    res.setHeader("content-length", length);
    test:assertEquals(res.getHeader("content-length"), length, msg = "Content length mismatched");
}

@test:Config {}
function testResposeAddHeader() {
    http:Response res = new;
    string key = "lang";
    string value = "Ballerina";
    res.addHeader(key, value);
    test:assertEquals(res.getHeader(key), value, msg = "Value mismatched");
}

@test:Config {}
function testResposeGetHeader() {
    http:Response res = new;
    string key = "lang";
    string value = "Ballerina";
    res.addHeader(key, value);
    test:assertEquals(res.getHeader(key), value, msg = "Value mismatched");
}

@test:Config {}
function testResposeGetHeaders() {
    http:Response res = new;
    string key = "header1";
    string value = "abc, xyz";
    res.setHeader(key, "1stHeader");
    res.addHeader(key, value);
    string[] headers = res.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Header value mismatched");
    test:assertEquals(headers[1], "abc, xyz", msg = "Header value mismatched");
}

@test:Config {}
function testResposeGetJsonPayload() {
    http:Response res = new;
    json value = {name:"wso2"};
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
    error|string output = trap res.getHeader("Expect");
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
    error|string output = trap res.getHeader("Expect1");
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Outptut mismatched");
    }
}

@test:Config {}
function testResposeSetHeader() {
    http:Response res = new;
    string key = "lang";
    string value = "ballerina; a=6";
    res.setHeader(key, "abc");
    res.setHeader(key, value);
    test:assertEquals(res.getHeader(key), value, msg = "Header value mismatched");
}

@test:Config {}
function testResposeSetJsonPayload() {
    http:Response res = new;
    json value = {name:"wso2"};
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
    http:Cookie cookie = new("SID3", "31d4d96e407aad42");
    cookie.domain = "google.com";
    cookie.path = "/sample";
    cookie.maxAge = 3600 ;
    cookie.expires = "2017-06-26 05:46:22";
    cookie.httpOnly = true;
    cookie.secure = true;
    res.addCookie(cookie);
    http:Cookie[] cookiesInRequest = res.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID3", msg = "Invalid cookie name");
}

@test:Config {}
function testResposeRemoveCookiesFromRemoteStore() {
    http:Response res = new;
    http:Cookie cookie = new("SID3", "31d4d96e407aad42");
    cookie.expires = "2017-06-26 05:46:22";
    res.removeCookiesFromRemoteStore(cookie);
    http:Cookie[] cookiesInRequest = res.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
}

@test:Config {}
function testResposeGetCookies() {
    http:Response res = new;
    http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
    cookie1.path = "/sample";
    cookie1.domain = ".GOOGLE.com.";
    cookie1.maxAge = 3600 ;
    cookie1.expires = "2017-06-26 05:46:22";
    cookie1.httpOnly = true;
    cookie1.secure = true;
    res.addCookie(cookie1);
    // Gets the added cookies from response.
    http:Cookie[] cookiesInResponse=res.getCookies();
    test:assertEquals(cookiesInResponse.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInResponse[0].name, "SID002", msg = "Invalid cookie name");
}

listener http:Listener responseEp = new(responseTest);

@http:ServiceConfig {basePath : "/hello"}
service response on responseEp {

    @http:ResourceConfig {
        path:"/11"
    }
    resource function echo1 (http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/12/{phase}"
    }
    resource function echo2 (http:Caller caller, http:Request req, string phase) {
        http:Response res = new;
        res.reasonPhrase = phase;
        checkpanic caller->respond(<@untainted http:Response> res);
    }

    @http:ResourceConfig {
        path:"/13"
    }
    resource function echo3 (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = 203;
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/addheader/{key}/{value}"
    }
    resource function addheader (http:Caller caller, http:Request req, string key, string value) {
        http:Response res = new;
        res.addHeader(<@untainted string> key, value);
        string result = <@untainted string> res.getHeader(<@untainted string> key);
        res.setJsonPayload({lang:result});
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/getHeader/{header}/{value}"
    }
    resource function getHeader (http:Caller caller, http:Request req, string header, string value) {
        http:Response res = new;
        res.setHeader(<@untainted string> header, value);
        string result = <@untainted string> res.getHeader(<@untainted string> header);
        res.setJsonPayload({value:result});
        checkpanic caller->respond(<@untainted> res);
    }

    @http:ResourceConfig {
        path:"/getJsonPayload/{value}"
    }
    resource function getJsonPayload(http:Caller caller, http:Request req, string value) {
        http:Response res = new;
        json jsonStr = {lang:value};
        res.setJsonPayload(<@untainted json> jsonStr);
        var returnResult = res.getJsonPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(<@untainted json> returnResult.lang);
        }
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/GetTextPayload/{valueStr}"
    }
    resource function getTextPayload(http:Caller caller, http:Request req, string valueStr) {
        http:Response res = new;
        res.setTextPayload(<@untainted string> valueStr);
        var returnResult = res.getTextPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode =500;
        } else {
            res.setTextPayload(<@untainted string> returnResult);
        }
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/GetXmlPayload"
    }
    resource function getXmlPayload(http:Caller caller, http:Request req) {
        http:Response res = new;
        xml xmlStr = xml `<name>ballerina</name>`;
        res.setXmlPayload(xmlStr);
        var returnResult = res.getXmlPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode =500;
        } else {
            var name = (returnResult/*).toString();
            res.setTextPayload(<@untainted string> name);
        }
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/RemoveHeader/{key}/{value}"
    }
    resource function removeHeader (http:Caller caller, http:Request req, string key, string value) {
        http:Response res = new;
        res.setHeader(<@untainted string> key, value);
        res.removeHeader(<@untainted string> key);
        string header = "";
        if (!res.hasHeader(<@untainted> key)) {
            header = "value is null";
        }
        res.setJsonPayload({value:header});
        checkpanic caller->respond(<@untainted> res);
    }

    @http:ResourceConfig {
        path:"/RemoveAllHeaders"
    }
    resource function removeAllHeaders (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("Expect", "100-continue");
        res.setHeader("Range", "bytes=500-999");
        res.removeAllHeaders();
        string header = "";
        if(!res.hasHeader("Range")) {
            header = "value is null";
        }
        res.setJsonPayload({value:header});
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/addCookie"
    }
    resource function addCookie (http:Caller caller, http:Request req) {
        http:Response res = new;
        http:Cookie cookie = new("SID3", "31d4d96e407aad42");
        cookie.domain = "google.com";
        cookie.path = "/sample";
        cookie.maxAge = 3600 ;
        cookie.expires = "2017-06-26 05:46:22";
        cookie.httpOnly = true;
        cookie.secure = true;
        res.addCookie(cookie);
        string result = <@untainted string> res.getHeader(<@untainted string> "Set-Cookie");
        res.setJsonPayload({SetCookieHeader:result});
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/removeCookieByServer"
    }
    resource function removeCookieByServer (http:Caller caller, http:Request req) {
        http:Response res = new;
        http:Cookie cookie = new("SID3", "31d4d96e407aad42");
        cookie.expires="2017-06-26 05:46:22";
        res.removeCookiesFromRemoteStore(cookie);
        string result = <@untainted string> res.getHeader(<@untainted string> "Set-Cookie");
        res.setJsonPayload({SetCookieHeader:result});
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/getCookies"
    }
    resource function getCookies (http:Caller caller, http:Request req) {
        http:Response res = new;
        http:Cookie cookie1 = new("SID002", "239d4dmnmsddd34");
        cookie1.path = "/sample";
        cookie1.domain = ".GOOGLE.com.";
        cookie1.maxAge = 3600 ;
        cookie1.expires = "2017-06-26 05:46:22";
        cookie1.httpOnly = true;
        cookie1.secure = true;
        res.addCookie(cookie1);
        //Gets the added cookies from response.
        http:Cookie[] cookiesInResponse=res.getCookies();
        string result = <@untainted string>  cookiesInResponse[0].name ;
        res.setJsonPayload({cookie:result});
        checkpanic caller->respond(res);
    }
}

http:Client responseClient = new("http://localhost:" + responseTest.toString());

// Test addHeader function within a service
@test:Config {}
function testResponseServiceAddHeader() {
    string key = "lang";
    string value = "ballerina";
    string path = "/hello/addheader/" + key + "/" + value;
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {lang:"ballerina"});
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetHeader function within a service
@test:Config {}
function testResponseServiceGetHeader() {
    string value = "test-header-value";
    string path = "/hello/getHeader/" + "test-header-name" + "/" + value;
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value: value});
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetJsonPayload function within a service
@test:Config {}
function testResponseServiceGetJsonPayload() {
    string value = "ballerina";
    string path = "/hello/getJsonPayload/" + value;
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), value);
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetTextPayload function within a service
@test:Config {}
function testResponseServiceGetTextPayload() {
    string value = "ballerina";
    string path = "/hello/GetTextPayload/" + value;
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), value);
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetXmlPayload function within a service
@test:Config {}
function testResponseServiceGetXmlPayload() {
    string value = "ballerina";
    string path = "/hello/GetXmlPayload";
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), value);
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testForwardMethod() {
    string path = "/hello/11";
    var response = responseClient->get(path);
    test:assertTrue(response is http:Response, msg = "Found unexpected output");
}

// Test RemoveHeader function within a service
@test:Config {}
function testResponseServiceRemoveHeader() {
    string value = "x-www-form-urlencoded";
    string path = "/hello/RemoveHeader/Content-Type/" + value;
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "{\"value\":\"value is null\"}");
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test RemoveAllHeaders function within a service
@test:Config {}
function testResponseServiceRemoveAllHeaders() {
    string path = "/hello/RemoveAllHeaders";
    var response = responseClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "{\"value\":\"value is null\"}");
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testRespondMethod() {
    string path = "/hello/11";
    var response = responseClient->get(path);
    test:assertTrue(response is http:Response, msg = "Found unexpected output");
}

@test:Config {}
function testSetReasonPhase() {
    string phase = "ballerina";
    string path = "/hello/12/" + phase;
    var response = responseClient->get(path);
    if (response is http:Response) {
        test:assertEquals(response.reasonPhrase, "OK");
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testSetStatusCode() {
    string path = "/hello/13";
    var response = responseClient->get(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 203);
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testTrailingAddHeader() {
    http:Response res = new;
    string headerName = "Max-Forwards";
    string headerValue = "eighty two";
    string retrieval = "max-forwards";
    res.addHeader(headerName, headerValue, position = "trailing");
    test:assertEquals(res.getHeader(retrieval, position = "trailing"), "eighty two");
}

@test:Config {}
function testAddingMultipleValuesToSameTrailingHeader() {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    string[] output = res.getHeaders("header1", position = "trailing");
    test:assertEquals(res.getHeader("header1", position = "trailing"), "value1");
    test:assertEquals(output.length(), 2);
    test:assertEquals(output[0], "value1");
    test:assertEquals(output[1], "value2");
}

@test:Config {}
function testSetTrailingHeaderAfterAddHeader() {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    res.addHeader("hEader2", "value3", position = "trailing");
    string[] output = res.getHeaders("header1", position = "trailing");
    test:assertEquals(res.getHeader("header2", position = "trailing"), "value3");
    test:assertEquals(output.length(), 2);
    test:assertEquals(output[0], "value1");
    test:assertEquals(output[1], "value2");
}

@test:Config {}
function testRemoveTrailingHeader() {
    http:Response res = new;
    res.addHeader("heAder1", "value1", position = "trailing");
    res.addHeader("header1", "value2", position = "trailing");
    res.addHeader("header1", "value3", position = "trailing");
    res.addHeader("hEader2", "value3", position = "trailing");
    res.addHeader("headeR2", "value4", position = "trailing");
    res.setHeader("HeADEr2", "totally different value", position = "trailing");
    res.removeHeader("HEADER1", position = "trailing");
    res.removeHeader("NONE_EXISTENCE_HEADER", position = "trailing");
    string[] output = res.getHeaders("header1", position = "trailing");
    test:assertEquals(res.getHeader("header2", position = "trailing"), "totally different value");
    test:assertEquals(output.length(), 0);
}

@test:Config {}
function testNonExistenceTrailingHeader() {
    http:Response res = new;
    string headerName = "heAder1";
    string headerValue = "value1";
    res.addHeader(headerName, headerValue, position = http:TRAILING);
    error|string output = trap res.getHeader("header", position = http:TRAILING);
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
