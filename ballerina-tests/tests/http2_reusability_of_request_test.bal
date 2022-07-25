// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/io;
// import ballerina/log;
import ballerina/mime;
import ballerina/test;

int http2ReuseRequestTestPort = getHttp2Port(reuseRequestTestPort);

listener http:Listener http2ReuseRequestListenerEP = new(http2ReuseRequestTestPort);
final http:Client http2ReuseRequestClient = check new("http://localhost:" + http2ReuseRequestTestPort.toString(), 
    http2Settings = { http2PriorKnowledge: true });

final http:Client http2ClientEP1 = check new("http://localhost:" + http2ReuseRequestTestPort.toString() + "/testService_2", 
    http2Settings = { http2PriorKnowledge: true });

service /reuseObj on http2ReuseRequestListenerEP {

    resource function get request_without_entity(http:Caller caller, http:Request clientRequest) returns error? {
        string firstVal = "";
        string secondVal = "";

        http:Response|error firstResponse = http2ClientEP1 -> get("");
        if firstResponse is http:Response {
            var result = firstResponse.getTextPayload();
            if result is string {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else {
            firstVal = firstResponse.message();
        }

        http:Response|error secondResponse = http2ClientEP1 -> get("");
        if secondResponse is http:Response {
            var result = secondResponse.getTextPayload();
            if result is string {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(firstVal + secondVal);
        check caller->respond(testResponse);
    }

    resource function get request_with_empty_entity(http:Caller caller, http:Request clientRequest) returns error? {
        http:Request clientReq = new;
        mime:Entity entity = new;
        clientReq.setEntity(entity);

        string firstVal = "";
        string secondVal = "";

        http:Response|error firstResponse = http2ClientEP1 -> execute("GET", "", clientReq);
        if firstResponse is http:Response {
            var result = firstResponse.getTextPayload();
            if result is string {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else {
            firstVal = firstResponse.message();
        }

        http:Response|error secondResponse = http2ClientEP1 -> execute("GET", "", clientReq);
        if secondResponse is http:Response {
            var result = secondResponse.getTextPayload();
            if result is string {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(firstVal + secondVal);
        check caller->respond(testResponse);
    }

    resource function get two_request_same_entity(http:Caller caller, http:Request clientRequest) returns error? {
        http:Request clientReq = new;
        clientReq.setHeader("test1", "value1");
        http:Request newRequest = new;
        string firstVal = "";
        string secondVal = "";
        http:Response testResponse = new;

        var entity = clientReq.getEntity();
        if entity is mime:Entity {
            newRequest.setEntity(entity);
            http:Response|error firstResponse = http2ClientEP1 -> execute("GET", "", clientReq);
            if firstResponse is http:Response {
                newRequest.setHeader("test2", "value2");
                http:Response|error secondResponse = http2ClientEP1 -> execute("GET", "", newRequest);
                if secondResponse is http:Response {
                    var result1 = firstResponse.getTextPayload();
                    if result1 is string {
                        firstVal = result1;
                    } else {
                        firstVal = result1.message();
                    }

                    var result2 = secondResponse.getTextPayload();
                    if result2 is string {
                        secondVal = result2;
                    } else {
                        secondVal = result2.message();
                    }
                } else {
                    // log:printError(secondResponse.message(), 'error = secondResponse);
                }
            } else {
                // log:printError(firstResponse.message(), 'error = firstResponse);
            }
        } else {
            // log:printError(entity.message(), 'error = entity);
        }
        testResponse.setTextPayload(firstVal + secondVal);
        check caller->respond(testResponse);
    }

    resource function get request_with_datasource(http:Caller caller, http:Request clientRequest) returns error? {
        http:Request clientReq = new;
        clientReq.setTextPayload("String datasource");

        string firstVal = "";
        string secondVal = "";
        http:Response|error firstResponse = http2ClientEP1 -> post("/datasource", clientReq);
        if firstResponse is http:Response {
            var result = firstResponse.getTextPayload();
            if result is string {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else {
            firstVal = firstResponse.message();
        }

        http:Response|error secondResponse = http2ClientEP1 -> post("/datasource", clientReq);
        if secondResponse is http:Response {
            var result = secondResponse.getTextPayload();
            if result is string {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(firstVal + secondVal);
        check caller->respond(testResponse);
    }

    resource function post request_with_byteStream(http:Caller caller, http:Request clientRequest) returns error? {
        http:Request clientReq = new;
        var byteStream = clientRequest.getByteStream();
        if byteStream is stream<byte[], io:Error?> {
            clientReq.setByteStream(byteStream, "text/plain");
            http:Response|error firstResponse = http2ClientEP1 -> post("/consumeChannel", clientReq);
            if firstResponse is http:Response {
                http:Response|error secondResponse = http2ClientEP1 -> post("/consumeChannel", clientReq);
                http:Response testResponse = new;
                string firstVal = "";
                string secondVal = "";
                if secondResponse is http:Response {
                    var result1 = secondResponse.getTextPayload();
                    if  (result1 is string) {
                        secondVal = result1;
                    } else {
                        secondVal = "Error in parsing payload";
                    }
                } else {
                    secondVal = secondResponse.message();
                }

                var result2 = firstResponse.getTextPayload();
                if result2 is string {
                    firstVal = result2;
                } else {
                    firstVal = result2.message();
                }

                testResponse.setTextPayload(firstVal + secondVal);
                check caller->respond(testResponse);
            } else {
                // log:printError(firstResponse.message(), 'error = firstResponse);
            }
        } else {
            // log:printError(byteStream.message(), 'error = byteStream);
        }
    }
}

service /testService_2 on http2ReuseRequestListenerEP {

    resource function get .(http:Caller caller, http:Request clientRequest) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello from GET!");
        check caller->respond(response);
    }

    resource function post datasource(http:Caller caller, http:Request clientRequest) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello from POST!");
        check caller->respond(response);
    }

    resource function post consumeChannel(http:Caller caller, http:Request clientRequest) returns error? {
        http:Response response = new;
        var stringPayload = clientRequest.getTextPayload();
        if stringPayload is string {
            response.setPayload(stringPayload);
        } else  {
            response.setPayload(stringPayload.message());
        }
        check caller->respond(response);
    }
}

@test:Config {}
function testHttp2ReuseRequestWithoutEntity() returns error? {
    http:Response|error response = http2ReuseRequestClient->get("/reuseObj/request_without_entity");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2ReuseRequestWithEmptyEntity() returns error? {
    http:Response|error response = http2ReuseRequestClient->get("/reuseObj/request_with_empty_entity");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2TwoRequestsSameEntity() returns error? {
    http:Response|error response = http2ReuseRequestClient->get("/reuseObj/two_request_same_entity");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2SameRequestWithADatasource() returns error? {
    http:Response|error response = http2ReuseRequestClient->get("/reuseObj/request_with_datasource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from POST!Hello from POST!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// TODO: Enable after the I/O revamp
@test:Config {enable:false}
function testHttp2SameRequestWithByteChannel() returns error? {
    http:Response|error response = http2ReuseRequestClient->post("/reuseObj/request_with_bytechannel", "Hello from POST!");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from POST!No content");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2SameRequestWithByteStream() returns error? {
    http:Response|error response = http2ReuseRequestClient->post("/reuseObj/request_with_byteStream", "Hello from POST!");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from POST!No content");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
