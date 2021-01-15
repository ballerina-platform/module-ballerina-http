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

import ballerina/test;
import ballerina/http;

listener http:Listener httpHeaderListenerEP1 = checkpanic new(httpHeaderTestPort1);
listener http:Listener httpHeaderListenerEP2 = checkpanic new(httpHeaderTestPort2);
http:Client httpHeaderClient = checkpanic new("http://localhost:" + httpHeaderTestPort1.toString());

http:Client stockqEP = checkpanic new("http://localhost:" + httpHeaderTestPort2.toString());

service /headerService on httpHeaderListenerEP1 {

    resource function 'default value(http:Caller caller, http:Request req) {
        req.setHeader("core", "aaa");
        req.addHeader("core", "bbb");

        var result = stockqEP->get("/quoteService1/stocks", <@untainted> req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default id(http:Caller caller, http:Request req) {
        http:Response clntResponse = new;
        var clientResponse = stockqEP->forward("/quoteService1/customers", req);
        if (clientResponse is http:Response) {
            json payload = {};
            if (clientResponse.hasHeader("person")) {
                string[] headers = clientResponse.getHeaders("person");
                if (headers.length() == 2) {
                    payload = {header1:headers[0], header2:headers[1]};
                } else {
                    payload = {"response":"expected number of 'person' headers not found"};
                }
            } else {
                payload = {"response":"person header not available"};
            }
            checkpanic caller->respond(payload);
        } else if (clientResponse is error) {
            checkpanic caller->respond(<@untainted> clientResponse.message());
        }
    }

    resource function 'default nonEntityBodyGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/quoteService1/entitySizeChecker");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default entityBodyGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/quoteService1/entitySizeChecker", "hello");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default entityGet(http:Caller caller, http:Request req) {
        http:Request request = new;
        request.setHeader("X_test", "One header");
        var result = stockqEP->get("/quoteService1/entitySizeChecker", request);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default entityForward(http:Caller caller, http:Request req) {
        var result = stockqEP->forward("/quoteService1/entitySizeChecker", req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default entityExecute(http:Caller caller, http:Request req) {
        var result = stockqEP->execute("GET", "/quoteService1/entitySizeChecker", "hello ballerina");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default noEntityExecute(http:Caller caller, http:Request req) {
        var result = stockqEP->execute("GET", "/quoteService1/entitySizeChecker", ());
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function 'default passthruGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/quoteService1/entitySizeChecker", <@untainted> req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }
}

service /quoteService1 on httpHeaderListenerEP2 {

    resource function get stocks(http:Caller caller, http:Request req) {
        json payload = {};
        if (req.hasHeader("core")) {
            string[] headers = req.getHeaders("core");
            if (headers.length() == 2) {
                payload = {header1:headers[0], header2:headers[1]};
            } else {
                payload = {"response":"expected number of 'core' headers not found"};
            }
        } else {
            payload = {"response":"core header not available"};
        }
        http:Response res = new;
        res.setJsonPayload(<@untainted> payload);
        checkpanic caller->respond(res);
    }

    resource function get customers(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("person", "kkk");
        res.addHeader("person", "jjj");
        checkpanic caller->respond(res);
    }

    resource function 'default entitySizeChecker(http:Caller caller, http:Request req) {
        if (req.hasHeader("content-length")) {
            checkpanic caller->respond("Content-length header available");
        } else {
            checkpanic caller->respond("No Content size related header present");
        }
    }
}

//Test outbound request headers availability at backend with URL. /headerService/value
@test:Config {}
function testOutboundRequestHeaders() {
    var response = httpHeaderClient->get("/headerService/value");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {header1:"aaa", header2:"bbb"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test inbound response headers availability with URL. /headerService/id
@test:Config {}
function testInboundResponseHeaders() {
    var response = httpHeaderClient->get("/headerService/id");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {header1:"kkk", header2:"jjj"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when nil is sent
@test:Config {}
function testOutboundNonEntityBodyGetRequestHeaders() {
    var response = httpHeaderClient->get("/headerService/nonEntityBodyGet");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when request sent without body
@test:Config {}
function testOutboundEntityBodyGetRequestHeaders() {
    var response = httpHeaderClient->get("/headerService/entityBodyGet");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when forwarding a GET request
@test:Config {}
function testOutboundEntityGetRequestHeaders() {
    var response = httpHeaderClient->get("/headerService/entityGet");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when forwarding a POST request
@test:Config {}
function testOutboundForwardNoEntityBodyRequestHeaders() {
    var response = httpHeaderClient->get("/headerService/entityForward");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header availability when using EXECUTE action
@test:Config {}
function testHeadersWithExecuteAction() {
    var response = httpHeaderClient->get("/headerService/entityExecute");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test outbound request content-length header when using EXECUTE action without body
@test:Config {}
function testHeadersWithExecuteActionWithoutBody() {
    var response = httpHeaderClient->get("/headerService/noEntityExecute");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "No Content size related header present");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test converting Post payload to GET outbound call in passthrough
@test:Config {}
function testPassthruWithBody() {
    var response = httpHeaderClient->post("/headerService/passthruGet", "HelloWorld");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

