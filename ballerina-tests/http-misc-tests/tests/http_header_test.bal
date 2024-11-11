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

import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener httpHeaderListenerEP1 = new (httpHeaderTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener httpHeaderListenerEP2 = new (httpHeaderTestPort2, httpVersion = http:HTTP_1_1);

final http:Client httpHeaderClient = check new ("http://localhost:" + httpHeaderTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client stockqEP = check new ("http://localhost:" + httpHeaderTestPort2.toString(), httpVersion = http:HTTP_1_1);

service /headerService on httpHeaderListenerEP1 {

    resource function 'default value(http:Caller caller, http:Request req) returns error? {
        req.setHeader("core", "aaa");
        req.addHeader("core", "bbb");

        http:Response|error result = stockqEP->execute("GET", "/quoteService1/stocks", req);
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default id(http:Caller caller, http:Request req) returns error? {
        http:Response|error clientResponse = stockqEP->forward("/quoteService1/customers", req);
        if clientResponse is http:Response {
            json payload = {};
            if (clientResponse.hasHeader("person")) {
                string[] headers = check clientResponse.getHeaders("person");
                if (headers.length() == 2) {
                    payload = {header1: headers[0], header2: headers[1]};
                } else {
                    payload = {"response": "expected number of 'person' headers not found"};
                }
            } else {
                payload = {"response": "person header not available"};
            }
            check caller->respond(payload);
        } else {
            check caller->respond(clientResponse.message());
        }
    }

    resource function 'default nonEntityBodyGet(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->get("/quoteService1/entitySizeChecker");
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default entityBodyGet(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->post("/quoteService1/entitySizeChecker", "hello");
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default entityGet(http:Caller caller, http:Request req) returns error? {
        http:Request request = new;
        request.setHeader("X_test", "One header");
        http:Response|error result = stockqEP->get("/quoteService1/entitySizeChecker", {"X_test": "One header"});
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default entityForward(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->forward("/quoteService1/entitySizeChecker", req);
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default entityExecute(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->execute("GET", "/quoteService1/entitySizeChecker", "hello ballerina");
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default noEntityExecute(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->execute("GET", "/quoteService1/entitySizeChecker", ());
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }

    resource function 'default passthruGet(http:Caller caller, http:Request req) returns error? {
        http:Response|error result = stockqEP->post("/quoteService1/entitySizeChecker", req);
        if result is http:Response {
            check caller->respond(result);
        } else {
            check caller->respond(result.message());
        }
    }
}

service /quoteService1 on httpHeaderListenerEP2 {

    resource function get stocks(http:Caller caller, http:Request req) returns error? {
        json payload = {};
        if (req.hasHeader("core")) {
            string[] headers = check req.getHeaders("core");
            if (headers.length() == 2) {
                payload = {header1: headers[0], header2: headers[1]};
            } else {
                payload = {"response": "expected number of 'core' headers not found"};
            }
        } else {
            payload = {"response": "core header not available"};
        }
        http:Response res = new;
        res.setJsonPayload(payload);
        check caller->respond(res);
    }

    resource function get customers(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("person", "kkk");
        res.addHeader("person", "jjj");
        check caller->respond(res);
    }

    resource function 'default entitySizeChecker(http:Caller caller, http:Request req) returns error? {
        if (req.hasHeader("content-length")) {
            check caller->respond("Content-length header available");
        } else {
            check caller->respond("No Content size related header present");
        }
    }
}

//Test outbound request headers availability at backend with URL. /headerService/value
@test:Config {}
function testOutboundRequestHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/value");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {header1: "aaa", header2: "bbb"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test inbound response headers availability with URL. /headerService/id
@test:Config {}
function testInboundResponseHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/id");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {header1: "kkk", header2: "jjj"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when nil is sent
@test:Config {}
function testOutboundNonEntityBodyGetRequestHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/nonEntityBodyGet");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when request sent without body
@test:Config {}
function testOutboundEntityBodyGetRequestHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/entityBodyGet");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when forwarding a GET request
@test:Config {}
function testOutboundEntityGetRequestHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/entityGet");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when forwarding a POST request
@test:Config {}
function testOutboundForwardNoEntityBodyRequestHeaders() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/entityForward");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when using EXECUTE action
@test:Config {}
function testHeadersWithExecuteAction() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/entityExecute");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header when using EXECUTE action without body
@test:Config {}
function testHeadersWithExecuteActionWithoutBody() returns error? {
    http:Response|error response = httpHeaderClient->get("/headerService/noEntityExecute");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test converting Post payload to GET outbound call in passthrough
@test:Config {}
function testPassthruWithBody() returns error? {
    http:Response|error response = httpHeaderClient->post("/headerService/passthruGet", "HelloWorld");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAddHeaderWithContentType() returns error? {
    http:Request req = new;
    check req.setContentType(mime:APPLICATION_JSON);
    test:assertEquals(check req.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_JSON]);
    req.addHeader(http:CONTENT_TYPE, mime:APPLICATION_XML);
    test:assertEquals(check req.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_XML]);

    http:Response res = new;
    check res.setContentType(mime:APPLICATION_JSON);
    test:assertEquals(check res.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_JSON]);
    res.addHeader(http:CONTENT_TYPE, mime:APPLICATION_XML);
    test:assertEquals(check res.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_XML]);

    http:PushPromise pushPromise = new;
    pushPromise.addHeader(http:CONTENT_TYPE, mime:APPLICATION_JSON);
    test:assertEquals(pushPromise.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_JSON]);
    pushPromise.addHeader(http:CONTENT_TYPE, mime:APPLICATION_XML);
    test:assertEquals(pushPromise.getHeaders(http:CONTENT_TYPE), [mime:APPLICATION_XML]);
}

type Headers record {|
    @http:Header {name: "X-API-VERSION"}
    string apiVersion;
    @http:Header {name: "X-REQ-ID"}
    int reqId;
    @http:Header {name: "X-IDS"}
    float[] ids;
|};

type HeadersNegative record {|
    @http:Header
    string header1;
    @http:Header {name: ()}
    string header2;
|};

@test:Config {}
function testGetHeadersMethod() {
    Headers headers = {apiVersion: "v1", reqId: 123, ids: [1.0, 2.0, 3.0]};
    map<string|string[]> expectedHeaderMap = {
        "X-API-VERSION": "v1",
        "X-REQ-ID": "123",
        "X-IDS": ["1.0", "2.0", "3.0"]
    };
    test:assertEquals(http:getHeaderMap(headers), expectedHeaderMap, "Header map is not as expected");
}

@test:Config {}
function testGetHeadersMethodNegative() {
    HeadersNegative headers = {header1: "header1", header2: "header2"};
    test:assertEquals(http:getHeaderMap(headers), headers, "Header map is not as expected");
}

type Queries record {|
    @http:Query { name: "XName" }
    string name;
    @http:Query { name: "XAge" }
    int age;
    @http:Query { name: "XIDs" }
    float[] ids;
|};

@test:Config {}
function testGetQueryMapMethod() {
    Queries queries = {name: "John", age: 30, ids: [1.0, 2.0, 3.0]};
    map<anydata> expectedQueryMap = {
        "XName": "John",
        "XAge": 30,
        "XIDs": [1.0, 2.0, 3.0]
    };
    test:assertEquals(http:getQueryMap(queries), expectedQueryMap, "Query map is not as expected");
}
