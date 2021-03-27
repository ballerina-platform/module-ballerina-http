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

@test:Config {}
function testContentType() {
    http:Request req = new;
    string contentType = "application/x-custom-type+json";
    checkpanic req.setContentType(contentType);
    test:assertEquals(req.getContentType(), contentType, msg = "Mismatched content type");
}

@test:Config {}
function testGetContentLength() {
    http:Request req = new;
    string payload = "ballerina";
    req.setHeader(CONTENT_LENGTH, payload.length().toString());
    test:assertEquals(checkpanic req.getHeader(CONTENT_LENGTH), payload.length().toString(), msg = "Mismatched content length");
}

@test:Config {}
function testAddHeader() {
    http:Request req = new;
    string key = "header1";
    string value = "abc, xyz";
    req.setHeader(key, "1stHeader");
    req.addHeader(key, value);
    string[] headers = checkpanic req.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Mismatched header value");
    test:assertEquals(headers[1], "abc, xyz", msg = "Mismatched header value");
}

@test:Config {}
function testSetHeader() {
    http:Request req = new;
    string key = "lang";
    string value = "ballerina; a=6";
    req.setHeader(key, "abc");
    req.setHeader(key, value);
    test:assertEquals(checkpanic req.getHeader(key), value, msg = "Mismatched header value");
}

@test:Config {}
function testSetJsonPayload() {
    json value = {name:"wso2"};
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
function testSetBinaryPayload()  {
    byte[] value = [5];
    http:Request req = new;
    req.setBinaryPayload(value);
    test:assertEquals(req.getBinaryPayload(), value, msg = "Mismatched binary payload");
}

@test:Config {}
function testSetEntityBody() {
    error? createFileResults = file:create("test.json");
    string value = "{\"name\":\"wso2\"}";
    string filePath = "";
    if (createFileResults is ()) {
        filePath = checkpanic file:getAbsolutePath("test.json");
    }
    io:WritableByteChannel writableFileResult = checkpanic io:openWritableFile("test.json");
    io:WritableCharacterChannel destinationChannel = new (writableFileResult, "UTF-8");
    var writeCharResult = checkpanic destinationChannel.write(value, 0);
    error? close = destinationChannel.close();
    http:Request req = new;
    req.setFileAsPayload(filePath);
    var payload = req.getEntity();
    error? removeResults = file:remove(filePath);
    test:assertTrue(payload is mime:Entity, msg = "Payload mismatched");
}

@test:Config {}
function testSetPayloadAndGetText() {
    http:Request req = new;
    string value = "Hello Ballerina !";
    req.setPayload(value);
    test:assertEquals(req.getTextPayload(), value, msg = "Mismatched string payload");
}

@test:Config {}
function testGetHeader() {
    http:Request req = new;
    string key = "lang";
    string value = "ballerina; a=6";
    req.setHeader(key, value);
    test:assertEquals(checkpanic req.getHeader(key), value, msg = "Mismatched header value");
}

@test:Config {}
function testGetHeaders() {
    http:Request req = new;
    string key = "header1";
    string value = "abc, xyz";
    req.setHeader(key, "1stHeader");
    req.addHeader(key, value);
    string[] headers = checkpanic req.getHeaders(key);
    test:assertEquals(headers[0], "1stHeader", msg = "Mismatched header value");
    test:assertEquals(headers[1], "abc, xyz", msg = "Mismatched header value");
}

@test:Config {}
function testGetJsonPayload() {
    json value = {name:"wso2"};
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
    http:Cookie cookie1 = new("SID1", "31d4d96e407aad42");
    cookie1.domain = "google.com";
    cookie1.path = "/sample";
    http:Cookie cookie2 = new("SID2", "2638747623468bce72");
    cookie2.name = "SID2";
    cookie2.value = "2638747623468bce72";
    cookie2.domain = "google.com";
    cookie2.path = "/sample/about";
    http:Cookie cookie3 = new("SID3", "782638747668bce72");
    cookie3.name = "SID3";
    cookie3.value = "782638747668bce72";
    cookie3.domain = "google.com";
    cookie3.path = "/sample";
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
    http:Cookie cookie1 = new("SID1", "31d4d96e407aad42");
    cookie1.domain = "google.com";
    cookie1.path = "/sample";
    http:Cookie[] cookiesToAdd = [cookie1];
    req.addCookies(cookiesToAdd);
    http:Cookie[] cookiesInRequest = req.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID1", msg = "Invalid cookie name");
}

@test:Config {}
function testGetCookiesWithEmptyValue() {
    http:Request req = new;
    http:Cookie cookie1 = new("SID1", "");
    cookie1.domain = "google.com";
    cookie1.path = "/sample";
    http:Cookie[] cookiesToAdd = [cookie1];
    req.addCookies(cookiesToAdd);
    http:Cookie[] cookiesInRequest = req.getCookies();
    test:assertEquals(cookiesInRequest.length(), 1, msg = "Invalid cookie object");
    test:assertEquals(cookiesInRequest[0].name, "SID1", msg = "Invalid cookie name");
    test:assertEquals(cookiesInRequest[0].value, "", msg = "Invalid cookie value");
}

listener http:Listener requestListner = new(requestTest);

service /requesthello on requestListner {

    resource function get addheader/[string key]/[string value](http:Caller caller, http:Request inReq) {
        http:Request req = new;
        req.addHeader(<@untainted string> key, value);
        string result = <@untainted> checkpanic req.getHeader(<@untainted string> key);
        http:Response res = new;
        res.setJsonPayload({ lang: result });
        checkpanic caller->respond(res);
    }

    resource function get '11(http:Caller caller, http:Request req) {
        http:Response res = new;
        string method = req.method;
        res.setTextPayload(<@untainted string> method);
        checkpanic caller->respond(res);
    }

    resource function get '12(http:Caller caller, http:Request req) {
        http:Response res = new;
        string url = req.rawPath;
        res.setTextPayload(<@untainted string> url);
        checkpanic caller->respond(res);
    }

    resource function get '13(http:Caller caller, http:Request req) {
        http:Response res = new;
        string url = req.rawPath;
        res.setTextPayload(<@untainted string> url);
        checkpanic caller->respond(res);
    }

    resource function get getHeader(http:Caller caller, http:Request req) {
        http:Response res = new;
        string header = <@untainted> checkpanic req.getHeader("content-type");
        res.setJsonPayload({ value: header });
        checkpanic caller->respond(res);
    }

    resource function post getJsonPayload(http:Caller caller, http:Request req) {
        http:Response res = new;
        var returnResult = req.getJsonPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(<@untainted json> checkpanic returnResult.lang);
        }
        checkpanic caller->respond(res);
    }

    resource function post GetTextPayload(http:Caller caller, http:Request req) {
        http:Response res = new;
        var returnResult = req.getTextPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setTextPayload(<@untainted string> returnResult);
        }
        checkpanic caller->respond(res);
    }

    resource function post GetXmlPayload(http:Caller caller, http:Request req) {
        http:Response res = new;
        var returnResult = req.getXmlPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = (returnResult/*).toString();
            res.setTextPayload(<@untainted string> name);
        }
        checkpanic caller->respond(res);
    }

    resource function post GetBinaryPayload(http:Caller caller, http:Request req) {
        http:Response res = new;
        var returnResult = req.getBinaryPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = strings:fromBytes(returnResult);
            if (name is string) {
                res.setTextPayload(<@untainted string> name);
            } else {
                res.setTextPayload("Error occurred while byte array to string conversion");
                res.statusCode = 500;
            }
        }
        checkpanic caller->respond(res);
    }

    // TODO: Enable after the I/O revamp
    // resource function post GetByteChannel(http:Caller caller, http:Request req) {
    //     http:Response res = new;
    //     var returnResult = req.getByteChannel();
    //     if (returnResult is error) {
    //         res.setTextPayload("Error occurred");
    //         res.statusCode = 500;
    //     } else {
    //         res.setByteChannel(returnResult);
    //     }
    //     checkpanic caller->respond(res);
    // }

    resource function post GetByteStream(http:Caller caller, http:Request req) {
        http:Response res = new;
        var returnResult = req.getByteStream();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setByteStream(returnResult);
        }
        checkpanic caller->respond(res);
    }

    resource function get RemoveHeader(http:Caller caller, http:Request inReq) {
        http:Request req = new;
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");
        req.removeHeader("Content-Type");
        string header = "";
        if (!req.hasHeader("Content-Type")) {
            header = "value is null";
        }
        http:Response res = new;
        res.setJsonPayload({ value: header });
        checkpanic caller->respond(res);
    }

    resource function get RemoveAllHeaders(http:Caller caller, http:Request inReq) {
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
        res.setJsonPayload({ value: header });
        checkpanic caller->respond(res);
    }

    resource function get setHeader/[string key]/[string value](http:Caller caller, http:Request inReq) {
        http:Request req = new;
        req.setHeader(<@untainted string> key, "abc");
        req.setHeader(<@untainted string> key, value);
        string result = <@untainted> checkpanic req.getHeader(<@untainted string> key);

        http:Response res = new;
        res.setJsonPayload({ value: result });
        checkpanic caller->respond(res);
    }

    resource function get SetJsonPayload/[string value](http:Caller caller, http:Request inReq) {
        http:Request req = new;
        json jsonStr = { lang: value };
        req.setJsonPayload(<@untainted json> jsonStr);
        var returnResult = req.getJsonPayload();
        http:Response res = new;
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload(<@untainted json> returnResult);
        }
        checkpanic caller->respond(res);
    }

    resource function get SetStringPayload/[string value](http:Caller caller, http:Request inReq) {
        http:Request req = new;
        req.setTextPayload(<@untainted string> value);
        http:Response res = new;
        var returnResult = req.getTextPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            res.setJsonPayload({ lang: <@untainted string> returnResult });
        }
        checkpanic caller->respond(res);
    }

    resource function get SetXmlPayload(http:Caller caller, http:Request inReq) {
        http:Request req = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        req.setXmlPayload(xmlStr);
        http:Response res = new;
        var returnResult = req.getXmlPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = <@untainted string> (returnResult/*).toString();
            res.setJsonPayload({ lang: name });
        }
        checkpanic caller->respond(res);
    }

    resource function get SetBinaryPayload(http:Caller caller, http:Request inReq) {
        http:Request req = new;
        string text = "Ballerina";
        byte[] payload = text.toBytes();
        req.setBinaryPayload(payload);
        http:Response res = new;
        var returnResult = req.getBinaryPayload();
        if (returnResult is error) {
            res.setTextPayload("Error occurred");
            res.statusCode = 500;
        } else {
            var name = strings:fromBytes(returnResult);
            if (name is string) {
                res.setJsonPayload({ lang: <@untainted string> name });
            } else {
                res.setTextPayload("Error occurred while byte array to string conversion");
                res.statusCode = 500;
            }
        }
        checkpanic caller->respond(res);
    }

    resource function get addCookies(http:Caller caller, http:Request inReq) {
        http:Request req = new;
        http:Cookie cookie1 = new("SID1", "31d4d96e407aad42");
        cookie1.domain = "google.com";
        cookie1.path = "/sample";
        http:Cookie cookie2 = new("SID2", "2638747623468bce72");
        cookie2.domain = "google.com";
        cookie2.path = "/sample/about";
        http:Cookie cookie3 = new("SID3", "782638747668bce72");
        cookie3.domain = "google.com";
        cookie3.path = "/sample";
        http:Cookie[] cookiesToAdd = [cookie1, cookie2, cookie3];
        req.addCookies(cookiesToAdd);
        string result = <@untainted> checkpanic req.getHeader("Cookie");
        http:Response res = new;
        res.setJsonPayload({ cookieHeader: result });
        checkpanic caller->respond(res);
    }

    resource function get getCookies(http:Caller caller, http:Request req) {
        http:Response res = new;
        http:Cookie cookie1 = new("SID1", "31d4d96e407aad42");
        cookie1.domain = "google.com";
        cookie1.path = "/sample";
        http:Cookie[] cookiesToAdd = [cookie1];
        req.addCookies(cookiesToAdd);
        http:Cookie[] cookiesInRequest = req.getCookies();
        res.setTextPayload(<@untainted string>  cookiesInRequest[0].name );
        checkpanic caller->respond(res);
    }
}

http:Client requestClient = check new("http://localhost:" + requestTest.toString());

// Test addHeader function within a service
@test:Config {}
function testServiceAddHeader() {
    string key = "lang";
    string value = "ballerina";
    string path = "/requesthello/addheader/" + key + "/" + value;
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {lang:"ballerina"});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetHeader function within a service
@test:Config {}
function testServiceGetHeader() {
    string path = "/requesthello/getHeader";
    string contentType = "application/x-www-form-urlencoded";
    var response = requestClient->get(path, {"content-type":contentType});
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { value: contentType});
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test GetJsonPayload function within a service
@test:Config {}
function testServiceGetJsonPayload() {
    string value = "ballerina";
    string path = "/requesthello/getJsonPayload";
    json payload = {lang: value };
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    var response = requestClient->post(path, req);
    if (response is http:Response) {
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
    var response = requestClient->post(path, req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), value);
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
    var response = requestClient->post(path, req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "ballerina");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testGetMethodWithInService() {
    string path = "/requesthello/11";
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "GET");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

@test:Config {}
function testGetRequestURLWithInService() {
    string path = "/requesthello/12";
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), path);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// TODO: Enable after the I/O revamp
// Test GetByteChannel function within a service. Send a json content as a request and then get a byte channel from
// the Request and set that ByteChannel as the response content"
@test:Config {enable:false}
function testServiceGetByteChannel() {
    string value = "ballerina";
    string path = "/requesthello/GetByteChannel";
    json payload = {lang: value };
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    var response = requestClient->post(path, req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), payload);
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
    json payload = {lang: value };
    string contentType = "application/json";
    http:Request req = new;
    req.setHeader("content-type", contentType);
    req.setJsonPayload(payload);
    var response = requestClient->post(path, req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), payload);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test RemoveAllHeaders function within a service
@test:Config {}
function testServiceRemoveAllHeaders() {
    string path = "/requesthello/RemoveAllHeaders";
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { value: "value is null" });
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
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { value: value });
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetHeader function within a service
@test:Config {}
function testServiceSetJsonPayload() {
    string value = "ballerina";
    string path = "/requesthello/SetJsonPayload/" + value;
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { "lang": value });
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetStringPayload function within a service
@test:Config {}
function testServiceSetStringPayload() {
    string value = "ballerina";
    string path = "/requesthello/SetJsonPayload/" + value;
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "{\"lang\":\"ballerina\"}");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test SetXmlPayload function within a service
@test:Config {}
function testServiceSetXmlPayload() {
    string value = "Ballerina";
    string path = "/requesthello/SetXmlPayload/";
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { "lang": value });
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}

// Test setBinaryPayload() function within a service
@test:Config {}
function testServiceSetBinaryPayload() {
    string value = "Ballerina";
    string path = "/requesthello/SetBinaryPayload/";
    var response = requestClient->get(path);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), { "lang": value });
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
    var response = requestClient->post(path, req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Ballerina");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
