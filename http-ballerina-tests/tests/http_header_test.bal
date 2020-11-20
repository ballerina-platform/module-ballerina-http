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

listener http:Listener httpHeaderListenerEP1 = new(httpHeaderTestPort1);
listener http:Listener httpHeaderListenerEP2 = new(httpHeaderTestPort2);
http:Client httpHeaderClient = new("http://localhost:" + httpHeaderTestPort1.toString());

http:Client stockqEP = new("http://localhost:" + httpHeaderTestPort2.toString());

@http:ServiceConfig {
    basePath:"/product"
}
service headerService on httpHeaderListenerEP1 {

    resource function value(http:Caller caller, http:Request req) {
        req.setHeader("core", "aaa");
        req.addHeader("core", "bbb");

        var result = stockqEP->get("/sample/stocks", <@untainted> req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function id(http:Caller caller, http:Request req) {
        http:Response clntResponse = new;
        var clientResponse = stockqEP->forward("/sample/customers", req);
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

    resource function nonEntityBodyGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/sample/entitySizeChecker");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function entityBodyGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/sample/entitySizeChecker", "hello");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function entityGet(http:Caller caller, http:Request req) {
        http:Request request = new;
        request.setHeader("X_test", "One header");
        var result = stockqEP->get("/sample/entitySizeChecker", request);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function entityForward(http:Caller caller, http:Request req) {
        var result = stockqEP->forward("/sample/entitySizeChecker", req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function entityExecute(http:Caller caller, http:Request req) {
        var result = stockqEP->execute("GET", "/sample/entitySizeChecker", "hello ballerina");
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function noEntityExecute(http:Caller caller, http:Request req) {
        var result = stockqEP->execute("GET", "/sample/entitySizeChecker", ());
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }

    resource function passthruGet(http:Caller caller, http:Request req) {
        var result = stockqEP->get("/sample/entitySizeChecker", <@untainted> req);
        if (result is http:Response) {
            checkpanic caller->respond(<@untainted> result);
        } else if (result is error) {
            checkpanic caller->respond(<@untainted> result.message());
        }
    }
}

@http:ServiceConfig {
    basePath:"/sample"
}
service quoteService1 on httpHeaderListenerEP2 {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/stocks"
    }
    resource function company(http:Caller caller, http:Request req) {
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

    @http:ResourceConfig {
        methods:["GET"],
        path:"/customers"
    }
    resource function product(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("person", "kkk");
        res.addHeader("person", "jjj");
        checkpanic caller->respond(res);
    }

    resource function entitySizeChecker(http:Caller caller, http:Request req) {
        if (req.hasHeader("content-length")) {
            checkpanic caller->respond("Content-length header available");
        } else {
            checkpanic caller->respond("No Content size related header present");
        }
    }
}

//Test outbound request headers availability at backend with URL. /product/value
@test:Config {}
function testOutboundRequestHeaders() {
    var response = httpHeaderClient->get("/product/value");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {header1:"aaa", header2:"bbb"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test inbound response headers availability with URL. /product/id
@test:Config {}
function testInboundResponseHeaders() {
    var response = httpHeaderClient->get("/product/id");
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
    var response = httpHeaderClient->get("/product/nonEntityBodyGet");
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
    var response = httpHeaderClient->get("/product/entityBodyGet");
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
    var response = httpHeaderClient->get("/product/entityGet");
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
    var response = httpHeaderClient->get("/product/entityForward");
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
    var response = httpHeaderClient->get("/product/entityExecute");
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
    var response = httpHeaderClient->get("/product/noEntityExecute");
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
    var response = httpHeaderClient->post("/product/passthruGet", "HelloWorld");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Content-length header available");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

