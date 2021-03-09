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

import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener utTestEP = new(uriTemplateTest1);
listener http:Listener utTestEPWithNoServicesAttached = new(uriTemplateTest2);

http:Client utClient1 = check new("http://localhost:" + uriTemplateTest1.toString());
http:Client utClient2 = check new("http://localhost:" + uriTemplateTest2.toString());

service /ecommerceservice on utTestEP {

    resource function get products/[string productId]/[string regId](http:Caller caller, http:Request req) {
        string orderId = checkpanic req.getHeader("X-ORDER-ID");
        io:println("Order ID " + orderId);
        io:println("Product ID " + productId);
        io:println("Reg ID " + regId);
        json responseJson = {"X-ORDER-ID":orderId, "ProductID":productId, "RegID":regId};
        io:println(responseJson.toString());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function get products2/[string productId]/[string regId]/item(http:Caller caller) {
        json responseJson;
        io:println("Product ID " + productId);
        io:println("Reg ID " + regId);
        responseJson = {"Template":"T2", "ProductID":productId, "RegID":regId};
        io:println(responseJson.toString());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function get products3/[string productId]/[string regId]/[string... extra](http:Caller caller) {
        json responseJson;
        io:println("Product ID " + productId);
        io:println("Reg ID " + regId);
        responseJson = {"Template":"T3", "ProductID":productId, "RegID":regId};
        io:println(responseJson.toString());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function get products/[string productId] (http:Caller caller, http:Request req) {
        json responseJson;
        map<string[]> qParams = req.getQueryParams();
        string[]? rID = qParams["regID"];
        string returnID = rID is string[] ? rID[0] : "";
        io:println("Product ID " + productId);
        io:println("Reg ID " + returnID);
        responseJson = {"Template":"T4", "ProductID":productId, "RegID":returnID};
        io:println(responseJson.toString());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function get products(http:Caller caller, http:Request req) {
        json responseJson;
        map<string[]> params = req.getQueryParams();
        string[]? prdID = params["prodID"];
        string[]? rID= params["regID"];
        string pId = prdID is string[] ? prdID[0] : "";
        string rgId = rID is string[] ? rID[0] : "";
        io:println ("Product ID " + pId);
        io:println ("Reg ID " + rgId);
        responseJson = {"Template":"T6", "ProductID":pId, "RegID":rgId};
        io:println (responseJson.toString ());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function get products5/[string productId]/reg(http:Caller caller, http:Request req) {
        json responseJson;
        map<string[]> params = req.getQueryParams();
        string[]? rID = params["regID"];
        string rgId = rID  is string[] ? rID[0] : "";
        io:println("Product ID " + productId);
        io:println("Reg ID " + rgId);
        responseJson = {"Template":"T5", "ProductID":productId, "RegID":rgId};
        io:println(responseJson.toString());

        http:Response res = new;
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }

    resource function 'default echo1(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo11":"echo11"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service /options on utTestEP {

    resource function post test(http:Caller caller) {
        http:Response res = new;
        checkpanic caller->respond(res);
    }

    resource function options hi(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"wso2"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function get test(http:Caller caller) {
        http:Response res = new;
        checkpanic caller->respond(res);

    }

    resource function get getme(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"get"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function post post(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"post"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function put put/add(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"put"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function delete put/[string abc](http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"delete"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service /noResource on utTestEP {
}

service /hello on utTestEP {

    resource function get test(http:Caller caller) {
        http:Response res = new;
        json responseJson = {"echo":"sanitized"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service /ech\[o on utTestEP {

    resource function get ech\[o/[string foo] (http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo113": foo};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }
}

service /ech\[o14 on utTestEP {

    resource function get ech\[o14/[string foo](http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo114": foo};
        res.setJsonPayload(<@untainted json> responseJson);
        checkpanic caller->respond(res);
    }
}

//Test accessing the variables parsed with URL. /products/{productId}/{regId}
@test:Config{ dataProvider:validUrl }
function testValidUrlTemplateDispatching(string path) {
    http:Request req = new;
    string xOrderIdHeadeName = "X-ORDER-ID";
    string xOrderIdHeadeValue = "ORD12345";
    req.setHeader(xOrderIdHeadeName, xOrderIdHeadeValue);
    var response = utClient1->get(path, req);
    if (response is http:Response) {
        //Expected Json message : {"X-ORDER-ID":"ORD12345","ProductID":"PID123","RegID":"RID123"}
        assertJsonValue(response.getJsonPayload(), xOrderIdHeadeName, xOrderIdHeadeValue);
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID123");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID123");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function validUrl() returns (string[][]) {
    return [
        ["/ecommerceservice/products/PID123/RID123"], 
        ["/ecommerceservice/products/PID123/RID123/"]
    ];
}

//Test resource dispatchers with invalid URL. /products/{productId}/{regId}
@test:Config{ dataProvider:inValidUrl }
function testInValidUrlTemplateDispatching(string path) {
    http:Request req = new;
    string xOrderIdHeadeName = "X-ORDER-ID";
    string xOrderIdHeadeValue = "ORD12345";
    req.setHeader(xOrderIdHeadeName, xOrderIdHeadeValue);
    var response = utClient1->get(path, req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "no matching resource found for path");
    } else {
        test:assertFail(msg = "Found unexpected output type" + response.message());
    }
}

function inValidUrl() returns (string[][]) {
    return [
        ["/ecommerceservice/prod/PID123/RID123"], 
        ["/ecommerceservice/products/PID123/RID123/ID"],
        ["/ecommerceservice/products/PID123/RID123/ID?param=value"],
        ["/ecommerceservice/products/PID123/RID123/ID?param1=value1&param2=value2"]
    ];
}

//Test accessing the variables parsed with URL. /products/{productId}
@test:Config{ dataProvider:validUrlWithQueryParam }
function testValidUrlTemplateWithQueryParamDispatching(string path) {
    var response = utClient1->get(path);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T4");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID123");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID123");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function validUrlWithQueryParam() returns (string[][]) {
    return [
        ["/ecommerceservice/products/PID123?regID=RID123"]
    ];
}

//Test accessing the variables parsed with URL. /products2/{productId}/{regId}/item
@test:Config{}
function testValidUrlTemplate2Dispatching() {
    var response = utClient1->get("/ecommerceservice/products2/PID125/RID125/item");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T2");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID125");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID125");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test accessing the variables parsed with URL. /products3/{productId}/{regId}/*
@test:Config{}
function testValidUrlTemplate3Dispatching() {
    var response = utClient1->get("/ecommerceservice/products3/PID125/RID125/xyz?para1=value1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T3");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID125");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID125");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test accessing the variables parsed with URL. /products5/{productId}/reg
@test:Config{}
function testValidUrlTemplate5Dispatching() {
    var response = utClient1->get("/ecommerceservice/products5/PID125/reg?regID=RID125&para1=value1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T5");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID125");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID125");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /products
@test:Config{}
function testUrlTemplateWithMultipleQueryParamDispatching() {
    var response = utClient1->get("/ecommerceservice/products?prodID=PID123&regID=RID123");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T6");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID123");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID123");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /products?productId=[string productId]&regID={regID}
@test:Config{}
function testUrlTemplateWithMultipleQueryParamWithURIEncodeCharacterDispatching() {
    var response = utClient1->get("/ecommerceservice/products?prodID=PID%20123&regID=RID%20123");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Template", "T6");
        assertJsonValue(response.getJsonPayload(), "ProductID", "PID 123");
        assertJsonValue(response.getJsonPayload(), "RegID", "RID 123");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test empty string resource path
@test:Config{}
function testEmptyStringResourcepath() {
    var response = utClient1->get("/ecommerceservice/echo1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo11", "echo11");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS method
@test:Config{}
function testOPTIONSMethods() {
    var response = utClient1->options("/options/hi");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request with GET method
@test:Config{}
function testOPTIONSWithGETMethods() {
    var response = utClient1->options("/options/getme", "hi");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "GET, OPTIONS", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request with POST method
@test:Config{}
function testOPTIONSWithPOSTMethods() {
    var response = utClient1->options("/options/post", "hi");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "POST, OPTIONS", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request with PUT method
@test:Config{}
function testOPTIONSWithPUTMethods() {
    var response = utClient1->options("/options/put/add");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "PUT, OPTIONS", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request with PATH params
@test:Config{}
function testOPTIONSWithPathParams() {
    var response = utClient1->options("/options/put/xyz");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "DELETE, OPTIONS", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request multiple resources
@test:Config{}
function testOPTIONSWithMultiResources() {
    var response = utClient1->options("/options/test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "POST, GET, OPTIONS", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request to Root
@test:Config{}
function testOPTIONSAtRootPath() {
    var response = utClient1->options("/options");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic response.getHeader("Allow"), "POST, OPTIONS, GET, PUT, DELETE", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request wrong Root
@test:Config{}
function testOPTIONSAtWrongRootPath() {
    var response = utClient1->options("/optionss");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching service found for path : /optionss");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request when no resources available
@test:Config{}
function testOPTIONSWhenNoResourcesAvailable() {
    var response = utClient1->options("/noResource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching resource found for path : /noResource , method : OPTIONS");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with OPTIONS request with wildcard
@test:Config{}
function testOPTIONSWithWildCards() {
    var response = utClient1->options("/options/un");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching resource found for path : /options/un , method : OPTIONS");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with basePath ending with forward slash
@test:Config{}
function testBasePathEndingWithSlash() {
    var response = utClient1->get("/hello/test");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "sanitized");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config{}
function testSpecialCharacterURI() {
    var response = utClient1->get("/ech%5Bo/ech%5Bo/b%5Bar");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo113", "b[ar");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config{}
function testSpecialCharacterEscapedURI() {
    var response = utClient1->get("/ech%5Bo14/ech%5Bo14/b%5Bar14");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo114", "b[ar14");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test a listener with no service registered
@test:Config{ dataProvider:SomeUrlsWithCorrectHost }
function testListenerWithNoServiceRegistered(string path) {
    var response = utClient2->get(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "no service has registered for listener :");
    } else {
        test:assertFail(msg = "Found unexpected output type" + response.message());
    }
}

function SomeUrlsWithCorrectHost() returns (string[][]) {
    return [
        [""], 
        ["/"],
        ["/products"]
    ];
}
