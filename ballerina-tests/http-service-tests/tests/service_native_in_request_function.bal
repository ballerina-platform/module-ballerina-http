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

import ballerina/file;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

@test:Config {}
function testContentType() returns error? {
    http:Request req = new;
    string contentType = "application/x-custom-type+json";
    check req.setContentType(contentType);
    test:assertEquals(req.getContentType(), contentType, msg = "Mismatched content type");
}

@test:Config {}
function testGetContentLength() returns error? {
    http:Request req = new;
    string payload = "ballerina";
    req.setHeader(common:CONTENT_LENGTH, payload.length().toString());
    test:assertEquals(check req.getHeader(common:CONTENT_LENGTH), payload.length().toString(), msg = "Mismatched content length");
}

@test:Config {}
function testAddHeader() returns error? {
    http:Request req = new;
    string key = "header1";
    string value = "abc, xyz";
    req.setHeader(key, "1stHeader");
    req.addHeader(key, value);
    string[] headers = check req.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Mismatched header value");
    test:assertEquals(headers[1], "abc, xyz", msg = "Mismatched header value");
}

@test:Config {}
function testSetHeader() returns error? {
    http:Request req = new;
    string key = "lang";
    string value = "ballerina; a=6";
    req.setHeader(key, "abc");
    req.setHeader(key, value);
    test:assertEquals(check req.getHeader(key), value, msg = "Mismatched header value");
}

@test:Config {}
function testSetJsonPayload() {
    json value = {name: "wso2"};
    http:Request req = new;
    req.setJsonPayload(value);
    test:assertEquals(req.getJsonPayload(), value, msg = "Mismatched json payload");
}

@test:Config {}
function testSetStringPayload() {
    string value = "Ballerina";
    http:Request req = new;
    req.setTextPayload(value);
    test:assertEquals(req.getTextPayload(), value, msg = "Mismatched string payload");
}

@test:Config {}
function testSetXmlPayload() {
    xml value = xml `<name>Ballerina</name>`;
    http:Request req = new;
    req.setXmlPayload(value);
    test:assertEquals(req.getXmlPayload(), value, msg = "Mismatched xml payload");
}

@test:Config {}
function testSetBinaryPayload() {
    byte[] value = [5];
    http:Request req = new;
    req.setBinaryPayload(value);
    test:assertEquals(req.getBinaryPayload(), value, msg = "Mismatched binary payload");
}

@test:Config {}
function testSetEntityBody() returns error? {
    error? createFileResults = file:create("test.json");
    string value = "{\"name\":\"wso2\"}";
    string filePath = "";
    if (createFileResults is ()) {
        filePath = check file:getAbsolutePath("test.json");
    }
    io:WritableByteChannel writableFileResult = check io:openWritableFile("test.json");
    io:WritableCharacterChannel destinationChannel = new (writableFileResult, "UTF-8");
    _ = check destinationChannel.write(value, 0);
    _ = check destinationChannel.close();
    http:Request req = new;
    req.setFileAsPayload(filePath);
    var payload = req.getEntity();
    _ = check file:remove(filePath);
    test:assertTrue(payload is mime:Entity, msg = "Payload mismatched");
    return;
}

@test:Config {}
function testSetPayloadAndGetText() {
    http:Request req = new;
    string value = "Hello Ballerina !";
    req.setPayload(value);
    test:assertEquals(req.getTextPayload(), value, msg = "Mismatched string payload");
}

@test:Config {}
function testGetHeader() returns error? {
    http:Request req = new;
    string key = "lang";
    string value = "ballerina; a=6";
    req.setHeader(key, value);
    test:assertEquals(check req.getHeader(key), value, msg = "Mismatched header value");
}

@test:Config {}
function testGetHeaders() returns error? {
    http:Request req = new;
    string key = "header1";
    string value = "abc, xyz";
    req.setHeader(key, "1stHeader");
    req.addHeader(key, value);
    string[] headers = check req.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Mismatched header value");
    test:assertEquals(headers[1], "abc, xyz", msg = "Mismatched header value");
}

@test:Config {}
function testGetJsonPayload() {
    json value = {name: "wso2"};
    http:Request req = new;
    req.setJsonPayload(value);
    test:assertEquals(req.getJsonPayload(), value, msg = "Mismatched json payload");
}

@test:Config {}
function testGetMethod() {
    http:Request req = new;
    req.method = "GET";
    test:assertEquals(req.method, "GET", msg = "Mismatched json payload");
}

@test:Config {}
function testGetTextPayload() {
    string value = "Ballerina";
    http:Request req = new;
    req.setTextPayload(value);
    test:assertEquals(req.getTextPayload(), value, msg = "Mismatched string payload");
}

@test:Config {}
function testGetBinaryPayload() {
    byte[] value = [5];
    http:Request req = new;
    req.setBinaryPayload(value);
    test:assertEquals(req.getBinaryPayload(), value, msg = "Mismatched binary payload");
}

@test:Config {}
function testGetXmlPayload() {
    xml value = xml `<name>Ballerina</name>`;
    http:Request req = new;
    req.setXmlPayload(value);
    test:assertEquals(req.getXmlPayload(), value, msg = "Mismatched xml payload");
}

@test:Config {}
function testAddCookies() {
    http:Request req = new;
    http:Cookie cookie1 = new ("SID1", "31d4d96e407aad42", path = "/sample", domain = "google.com");
    http:Cookie cookie2 = new ("SID2", "2638747623468bce72", path = "/sample/about", domain = "google.com");
    http:Cookie cookie3 = new ("SID3", "782638747668bce72", path = "/sample", domain = "google.com");
    http:Cookie[] cookiesToAdd = [cookie1, cookie2, cookie3];
    req.addCookies(cookiesToAdd);
    http:Cookie[] cookiesInRequest = req.getCookies();
    test:assertEquals(cookiesInRequest.length(), 3, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID1", msg = "Invalid cookie name");
    test:assertEquals(cookiesInRequest[1].name, "SID3", msg = "Invalid cookie name");
    test:assertEquals(cookiesInRequest[2].name, "SID2", msg = "Invalid cookie name");
}

@test:Config {}
function testGetCookies() {
    http:Request req = new;
    http:Cookie cookie1 = new ("SID1", "31d4d96e407aad42", path = "/sample", domain = "google.com");
    http:Cookie[] cookiesToAdd = [cookie1];
    req.addCookies(cookiesToAdd);
    http:Cookie[] cookiesInRequest = req.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID1", msg = "Invalid cookie name");
}

@test:Config {}
function testGetCookiesWithEmptyValue() {
    http:Request req = new;
    http:Cookie cookie1 = new ("SID1", "", path = "/sample", domain = "google.com");
    http:Cookie[] cookiesToAdd = [cookie1];
    req.addCookies(cookiesToAdd);
    http:Cookie[] cookiesInRequest = req.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID1", msg = "Invalid cookie name");
    test:assertEquals(cookiesInRequest[0].value, "", msg = "Invalid cookie value");
}

service /requesthello on generalListener {

    resource function get addheader/[string key]/[string value](http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        req.addHeader(key, value);
        string result = check req.getHeader(key);
        http:Response res = new;
        res.setJsonPayload({lang: result});
        check caller->respond(res);
    }

    resource function get '11(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string method = req.method;
        res.setTextPayload(method);
        check caller->respond(res);
    }

    resource function get '12(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string url = req.rawPath;
        res.setTextPayload(url);
        check caller->respond(res);
    }

    resource function get '13(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string url = req.rawPath;
        res.setTextPayload(url);
        check caller->respond(res);
    }

    resource function get getHeader(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string header = check req.getHeader("content-type");
        res.setJsonPayload({value: header});
        check caller->respond(res);
    }

    resource function post getJsonPayload(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var returnResult = req.getJsonPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(check returnResult.lang);
        }
        check caller->respond(res);
    }

    resource function post GetTextPayload(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var returnResult = req.getTextPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setTextPayload(returnResult);
        }
        check caller->respond(res);
    }

    resource function post GetXmlPayload(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var returnResult = req.getXmlPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = (returnResult/*).toString();
            res.setTextPayload(name);
        }
        check caller->respond(res);
    }

    resource function post GetBinaryPayload(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var returnResult = req.getBinaryPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = strings:fromBytes(returnResult);
            if (name is string) {
                res.setTextPayload(name);
            } else {
                res.setTextPayload("Error occurred while byte array to string conversion");
                res.statusCode = 500;
            }
        }
        check caller->respond(res);
    }

    // TODO: Enable after the I/O revamp
    // resource function post GetByteChannel(http:Caller caller, http:Request req) {
    //     http:Response res = new;
    //     var returnResult = req.getByteChannel();
    //     if returnResult is error {
    //         res.setTextPayload("Error occurred");
    //         res.statusCode = 500;
    //     } else {
    //         res.setByteChannel(returnResult);
    //     }
    //     check caller->respond(res);
    // }

    resource function post GetByteStream(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var returnResult = req.getByteStream();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setByteStream(returnResult);
        }
        check caller->respond(res);
    }

    resource function get RemoveHeader(http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");
        req.removeHeader("Content-Type");
        string header = "";
        if (!req.hasHeader("Content-Type")) {
            header = "value is null";
        }
        http:Response res = new;
        res.setJsonPayload({value: header});
        check caller->respond(res);
    }

    resource function get RemoveAllHeaders(http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");
        req.setHeader("Expect", "100-continue");
        req.setHeader("Range", "bytes=500-999");
        req.removeAllHeaders();
        string header = "";
        if (!req.hasHeader("Range")) {
            header = "value is null";
        }
        http:Response res = new;
        res.setJsonPayload({value: header});
        check caller->respond(res);
    }

    resource function get setHeader/[string key]/[string value](http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        req.setHeader(key, "abc");
        req.setHeader(key, value);
        string result = check req.getHeader(key);

        http:Response res = new;
        res.setJsonPayload({value: result});
        check caller->respond(res);
    }

    resource function get SetJsonPayload/[string value](http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        json jsonStr = {lang: value};
        req.setJsonPayload(jsonStr);
        var returnResult = req.getJsonPayload();
        http:Response res = new;
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(returnResult);
        }
        check caller->respond(res);
    }

    resource function get SetStringPayload/[string value](http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        req.setTextPayload(value);
        http:Response res = new;
        var returnResult = req.getTextPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload({lang: returnResult});
        }
        check caller->respond(res);
    }

    resource function get SetXmlPayload(http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        req.setXmlPayload(xmlStr);
        http:Response res = new;
        var returnResult = req.getXmlPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = (returnResult/*).toString();
            res.setJsonPayload({lang: name});
        }
        check caller->respond(res);
    }

    resource function get SetBinaryPayload(http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        string text = "Ballerina";
        byte[] payload = text.toBytes();
        req.setBinaryPayload(payload);
        http:Response res = new;
        var returnResult = req.getBinaryPayload();
        if returnResult is error {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = strings:fromBytes(returnResult);
            if (name is string) {
                res.setJsonPayload({lang: name});
            } else {
                res.setTextPayload("Error occurred while byte array to string conversion");
                res.statusCode = 500;
            }
        }
        check caller->respond(res);
    }

    resource function get addCookies(http:Caller caller, http:Request inReq) returns error? {
        http:Request req = new;
        http:Cookie cookie1 = new ("SID1", "31d4d96e407aad42", path = "/sample", domain = "google.com");
        http:Cookie cookie2 = new ("SID2", "2638747623468bce72", path = "/sample/about", domain = "google.com");
        http:Cookie cookie3 = new ("SID3", "782638747668bce72", path = "/sample", domain = "google.com");
        http:Cookie[] cookiesToAdd = [cookie1, cookie2, cookie3];
        req.addCookies(cookiesToAdd);
        string result = check req.getHeader("Cookie");
        http:Response res = new;
        res.setJsonPayload({cookieHeader: result});
        check caller->respond(res);
    }

    resource function get getCookies(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:Cookie cookie1 = new ("SID1", "31d4d96e407aad42", path = "/sample", domain = "google.com");
        http:Cookie[] cookiesToAdd = [cookie1];
        req.addCookies(cookiesToAdd);
        http:Cookie[] cookiesInRequest = req.getCookies();
        res.setTextPayload(cookiesInRequest[0].name);
        check caller->respond(res);
    }
}

final http:Client requestClient = check new ("http://localhost:" + generalPort.toString(), httpVersion = http:HTTP_1_1);

// Test addHeader function within a service
@test:Config {}
function testServiceAddHeader() {
    string key = "lang";
    string value = "ballerina";
    string path = "/requesthello/addheader/" + key + "/" + value;
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {lang: "ballerina"});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetHeader function within a service
@test:Config {}
function testServiceGetHeader() {
    string path = "/requesthello/getHeader";
    string contentType = "application/x-www-form-urlencoded";
    http:Response|error response = requestClient->get(path, {"content-type": contentType});
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value: contentType});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetJsonPayload function within a service
@test:Config {}
function testServiceGetJsonPayload() {
    string value = "ballerina";
    string path = "/requesthello/getJsonPayload";
    json payload = {lang: value};
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        test:assertEquals(response.getJsonPayload(), value, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetTextPayload function within a service
@test:Config {}
function testServiceGetTextPayload() {
    string value = "ballerina";
    string path = "/requesthello/GetTextPayload";
    string contentType = "text/plain";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setTextPayload(value);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), value);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetXmlPayload function within a service
@test:Config {}
function testServiceGetXmlPayload() {
    string path = "/requesthello/GetXmlPayload";
    xml xmlItem = xml `<name>ballerina</name>`;
    http:Request req = new;
    req.setHeader("content-type", "application/xml");
    req.setXmlPayload(xmlItem);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "ballerina");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testGetMethodWithInService() {
    string path = "/requesthello/11";
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "GET");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testGetRequestURLWithInService() {
    string path = "/requesthello/12";
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), path);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// TODO: Enable after the I/O revamp
// Test GetByteChannel function within a service. Send a json content as a request and then get a byte channel from
// the Request and set that ByteChannel as the response content"
@test:Config {enable: false}
function testServiceGetByteChannel() {
    string value = "ballerina";
    string path = "/requesthello/GetByteChannel";
    json payload = {lang: value};
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), payload);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetByteStream function within a service. Send a json content as a request and then get a byte Stream from
// the Request and set that ByteStream as the response content"
@test:Config {}
function testServiceGetByteStream() {
    string value = "ballerina";
    string path = "/requesthello/GetByteStream";
    json payload = {lang: value};
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), payload);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test RemoveAllHeaders function within a service
@test:Config {}
function testServiceRemoveAllHeaders() {
    string path = "/requesthello/RemoveAllHeaders";
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value: "value is null"});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetHeader function within a service
@test:Config {}
function testServiceSetHeader() {
    string key = "lang";
    string value = "ballerina";
    string path = "/requesthello/setHeader/" + key + "/" + value;
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value: value});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetHeader function within a service
@test:Config {}
function testServiceSetJsonPayload() {
    string value = "ballerina";
    string path = "/requesthello/SetJsonPayload/" + value;
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {"lang": value});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetStringPayload function within a service
@test:Config {}
function testServiceSetStringPayload() {
    string value = "ballerina";
    string path = "/requesthello/SetJsonPayload/" + value;
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "{\"lang\":\"ballerina\"}");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetXmlPayload function within a service
@test:Config {}
function testServiceSetXmlPayload() {
    string value = "Ballerina";
    string path = "/requesthello/SetXmlPayload/";
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {"lang": value});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test setBinaryPayload() function within a service
@test:Config {}
function testServiceSetBinaryPayload() {
    string value = "Ballerina";
    string path = "/requesthello/SetBinaryPayload/";
    http:Response|error response = requestClient->get(path);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {"lang": value});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test getBinaryPayload() function within a service
@test:Config {}
public function testServiceGetBinaryPayload() {
    string textVal = "Ballerina";
    byte[] payload = textVal.toBytes();
    string path = "/requesthello/GetBinaryPayload";
    http:Request req = new;
    req.setBinaryPayload(payload);
    http:Response|error response = requestClient->post(path, req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Ballerina");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
