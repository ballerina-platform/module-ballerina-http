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

import ballerina/log;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

listener http:Listener reuseRequestListenerEP = new(reuseRequestTestPort);
http:Client reuseRequestClient = check new("http://localhost:" + reuseRequestTestPort.toString());

http:Client clientEP1 = check new("http://localhost:" + reuseRequestTestPort.toString() + "/testService_2");

service /reuseObj on reuseRequestListenerEP {

    resource function get request_without_entity(http:Caller caller, http:Request clientRequest) {
        http:Request clientReq = new;
        string firstVal = "";
        string secondVal = "";

        var firstResponse = clientEP1 -> get("", clientReq);
        if (firstResponse is http:Response) {
            var result = <@untainted> firstResponse.getTextPayload();
            if (result is string) {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else if (firstResponse is error) {
            firstVal = firstResponse.message();
        }

        var secondResponse = clientEP1 -> get("", clientReq);
        if (secondResponse is http:Response) {
            var result = <@untainted> secondResponse.getTextPayload();
            if (result is string) {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else if (secondResponse is error) {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(<@untainted> firstVal + <@untainted> secondVal);
        checkpanic caller->respond(<@untainted> testResponse);
    }

    resource function get request_with_empty_entity(http:Caller caller, http:Request clientRequest) {
        http:Request clientReq = new;
        mime:Entity entity = new;
        clientReq.setEntity(entity);

        string firstVal = "";
        string secondVal = "";

        var firstResponse = clientEP1 -> get("", clientReq);
        if (firstResponse is http:Response) {
            var result = <@untainted> firstResponse.getTextPayload();
            if (result is string) {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else if (firstResponse is error) {
            firstVal = firstResponse.message();
        }

        var secondResponse = clientEP1 -> get("", clientReq);
        if (secondResponse is http:Response) {
            var result = <@untainted> secondResponse.getTextPayload();
            if (result is string) {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else if (secondResponse is error) {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(<@untainted> firstVal + <@untainted> secondVal);
        checkpanic caller->respond(<@untainted> testResponse);
    }

    resource function get two_request_same_entity(http:Caller caller, http:Request clientRequest) {
        http:Request clientReq = new;
        clientReq.setHeader("test1", "value1");
        http:Request newRequest = new;
        string firstVal = "";
        string secondVal = "";
        http:Response testResponse = new;

        var entity = clientReq.getEntity();
        if (entity is mime:Entity) {
            newRequest.setEntity(entity);
            var firstResponse = clientEP1 -> get("", clientReq);
            if (firstResponse is http:Response) {
                newRequest.setHeader("test2", "value2");
                var secondResponse = clientEP1 -> get("", newRequest);
                if (secondResponse is http:Response) {
                    var result1 = <@untainted> firstResponse.getTextPayload();
                    if (result1 is string) {
                        firstVal = result1;
                    } else {
                        firstVal = result1.message();
                    }

                    var result2 = <@untainted> secondResponse.getTextPayload();
                    if (result2 is string) {
                        secondVal = result2;
                    } else {
                        secondVal = result2.message();
                    }
                } else if (secondResponse is error) {
                    log:printError(secondResponse.message(), err = secondResponse);
                }
            } else if (firstResponse is error) {
                log:printError(firstResponse.message(), err = firstResponse);
            }
        } else {
            log:printError(entity.message(), err = entity);
        }
        testResponse.setTextPayload(firstVal + secondVal);
        checkpanic caller->respond(testResponse);
    }

    resource function get request_with_datasource(http:Caller caller, http:Request clientRequest) {
        http:Request clientReq = new;
        clientReq.setTextPayload("String datasource");

        string firstVal = "";
        string secondVal = "";
        var firstResponse = clientEP1 -> post("/datasource", clientReq);
        if (firstResponse is http:Response) {
            var result = <@untainted> firstResponse.getTextPayload();
            if (result is string) {
                firstVal = result;
            } else {
                firstVal = result.message();
            }
        } else if (firstResponse is error) {
            firstVal = firstResponse.message();
        }

        var secondResponse = clientEP1 -> post("/datasource", clientReq);
        if (secondResponse is http:Response) {
            var result = <@untainted> secondResponse.getTextPayload();
            if (result is string) {
                secondVal = result;
            } else {
                secondVal = result.message();
            }
        } else if (secondResponse is error) {
            secondVal = secondResponse.message();
        }
        http:Response testResponse = new;
        testResponse.setPayload(<@untainted> firstVal + <@untainted> secondVal);
        checkpanic caller->respond(<@untainted> testResponse);
    }

    // TODO: Enable with new byteStream API
    // resource function post request_with_bytechannel(http:Caller caller, http:Request clientRequest) {
    //     http:Request clientReq = new;
    //     var byteChannel = clientRequest.getByteChannel();
    //     if (byteChannel is io:ReadableByteChannel) {
    //         clientReq.setByteChannel(byteChannel, "text/plain");
    //         var firstResponse = clientEP1 -> post("/consumeChannel", clientReq);
    //         if (firstResponse is http:Response) {
    //             var secondResponse = clientEP1 -> post("/consumeChannel", clientReq);
    //             http:Response testResponse = new;
    //             string firstVal = "";
    //             string secondVal = "";
    //             if (secondResponse is http:Response) {
    //                 var result1 = secondResponse.getTextPayload();
    //                 if  (result1 is string) {
    //                     secondVal = result1;
    //                 } else {
    //                     secondVal = "Error in parsing payload";
    //                 }
    //             } else if (secondResponse is error) {
    //                 secondVal = secondResponse.message();
    //             }

    //             var result2 = firstResponse.getTextPayload();
    //             if (result2 is string) {
    //                 firstVal = result2;
    //             } else {
    //                 firstVal = result2.message();
    //             }

    //             testResponse.setTextPayload(<@untainted> firstVal + <@untainted> secondVal);
    //             checkpanic caller->respond(testResponse);
    //         } else if (firstResponse is error) {
    //             log:printError(firstResponse.message(), err = firstResponse);
    //         }
    //     } else {
    //         log:printError(byteChannel.message(), err = byteChannel);
    //     }
    // }
}

service /testService_2 on reuseRequestListenerEP {

    resource function get .(http:Caller caller, http:Request clientRequest) {
        http:Response response = new;
        response.setTextPayload("Hello from GET!");
        checkpanic caller->respond(response);
    }

    resource function post datasource(http:Caller caller, http:Request clientRequest) {
        http:Response response = new;
        response.setTextPayload("Hello from POST!");
        checkpanic caller->respond(response);
    }

    resource function post consumeChannel(http:Caller caller, http:Request clientRequest) {
        http:Response response = new;
        var stringPayload = clientRequest.getTextPayload();
        if (stringPayload is string) {
            response.setPayload(<@untainted> stringPayload);
        } else  {
            response.setPayload(<@untainted> stringPayload.message());
        }
        checkpanic caller->respond(response);
    }
}

@test:Config {}
function reuseRequestWithoutEntity() {
    var response = reuseRequestClient->get("/reuseObj/request_without_entity");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function reuseRequestWithEmptyEntity() {
    var response = reuseRequestClient->get("/reuseObj/request_with_empty_entity");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function twoRequestsSameEntity() {
    var response = reuseRequestClient->get("/reuseObj/two_request_same_entity");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from GET!Hello from GET!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function sameRequestWithADatasource() {
    var response = reuseRequestClient->get("/reuseObj/request_with_datasource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from POST!Hello from POST!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// TODO: Enable with new byteStream API
@test:Config {enable:false}
function sameRequestWithByteChannel() {
    var response = reuseRequestClient->post("/reuseObj/request_with_bytechannel", "Hello from POST!");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello from POST!No payload");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}


