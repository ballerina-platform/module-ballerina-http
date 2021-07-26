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

import ballerina/http;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;

listener http:Listener httpClientActionListenerEP1 = new(httpClientActionTestPort1);
listener http:Listener httpClientActionListenerEP2 = new(httpClientActionTestPort2);
http:Client httpClientActionClient = check new("http://localhost:" + httpClientActionTestPort2.toString() + "/httpClientActionTestService");

http:Client clientEP2 = check new("http://localhost:" + httpClientActionTestPort1.toString(), { cache: { enabled: false }});


service /httpClientActionBE on httpClientActionListenerEP1 {

    resource function get greeting(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello");
    }

    // TODO: Enable after the I/O revamp
    // resource function post byteChannel(http:Caller caller, http:Request req) {
    //     var byteChannel = req.getByteChannel();
    //     if (byteChannel is io:ReadableByteChannel) {
    //         checkpanic caller->respond(<@untainted> byteChannel);
    //     } else {
    //         checkpanic caller->respond(<@untainted> byteChannel.message());
    //     }
    // }

    resource function post byteStream(http:Caller caller, http:Request req) {
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            checkpanic caller->respond(<@untainted> byteStream);
        } else {
            checkpanic caller->respond(<@untainted> byteStream.message());
        }
    }

    resource function post directPayload(http:Caller caller, http:Request req) {
        if (req.hasHeader("content-type")) {
            var mediaType = mime:getMediaType(req.getContentType());
            if (mediaType is mime:MediaType) {
                string baseType = mediaType.getBaseType();
                if (mime:TEXT_PLAIN == baseType) {
                    var textValue = req.getTextPayload();
                    if (textValue is string) {
                        checkpanic caller->respond(<@untainted> textValue);
                    } else {
                        checkpanic caller->respond(<@untainted> textValue.message());
                    }
                } else if (mime:APPLICATION_XML == baseType) {
                    var xmlValue = req.getXmlPayload();
                    if (xmlValue is xml) {
                        checkpanic caller->respond(<@untainted> xmlValue);
                    } else {
                        checkpanic caller->respond(<@untainted> xmlValue.message());
                    }
                } else if (mime:APPLICATION_JSON == baseType) {
                    var jsonValue = req.getJsonPayload();
                    if (jsonValue is json) {
                        checkpanic caller->respond(<@untainted> jsonValue);
                    } else {
                        checkpanic caller->respond(<@untainted> jsonValue.message());
                    }
                } else if (mime:APPLICATION_OCTET_STREAM == baseType) {
                    var blobValue = req.getBinaryPayload();
                    if (blobValue is byte[]) {
                        checkpanic caller->respond(<@untainted> blobValue);
                    } else {
                        checkpanic caller->respond(<@untainted> blobValue.message());
                    }
                } else if (mime:MULTIPART_FORM_DATA == baseType) {
                    var bodyParts = req.getBodyParts();
                    if (bodyParts is mime:Entity[]) {
                        checkpanic caller->respond(<@untainted> bodyParts);
                    } else {
                        checkpanic caller->respond(<@untainted> bodyParts.message());
                    }
                }
            } else {
                checkpanic caller->respond("Error in parsing media type");
            }
        } else {
            checkpanic caller->respond();
        }
    }

    resource function 'default _bulk(http:Caller caller, http:Request request) {
        checkpanic caller->respond(checkpanic <@untainted> request.getTextPayload());
    }

    // withWhitespacedExpression
    resource function 'default [string id](http:Caller caller, http:Request request) {
        
        error? res = caller->respond(<@untainted> id);
    }

    // withWhitespacedLiteral
    resource function 'default a/b\ c/d(http:Caller caller, http:Request request) {
        error? res = caller->respond("dispatched to white_spaced literal");
    }
}

service /httpClientActionTestService on httpClientActionListenerEP2 {

    resource function get clientGet(http:Caller caller, http:Request req) {
        string value = "";
        //No Payload
        var response1 = clientEP2->get("/httpClientActionBE/greeting");
        if (response1 is http:Response) {
            var result = response1.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }

        //No Payload
        var response2 = clientEP2->get("/httpClientActionBE/greeting", ());
        if (response2 is http:Response) {
            var result = response2.getTextPayload();
            if (result is string) {
                value = value + result;
            } else {
                value = value + result.message();
            }
        }

        // Enable once the https://github.com/ballerina-platform/ballerina-lang/issues/28672 is fixed
        // future<error|http:Response> asyncInvocation = start clientEP2->get("/httpClientActionBE/greeting", ());

        //Request as message
        var response3 = clientEP2->get("/httpClientActionBE/greeting");
        if (response3 is http:Response) {
            var result = response3.getTextPayload();
            if (result is string) {
                value = value + result;
            } else {
                value = value + result.message();
            }
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function get clientPostWithoutBody(http:Caller caller, http:Request req) {
        string value = "";
        //No Payload
        var clientResponse = clientEP2->post("/httpClientActionBE/directPayload", ());
        if (clientResponse is http:Response) {
            var returnValue = clientResponse.getTextPayload();
            if (returnValue is string) {
                value = returnValue;
            } else {
                value = returnValue.message();
            }
        } else {
            value = clientResponse.message();
        }

        checkpanic caller->respond(<@untainted> value);
    }

    resource function get clientPostWithBody(http:Caller caller, http:Request req) {
        string value = "";
        var textResponse = clientEP2->post("/httpClientActionBE/directPayload", "Sample Text");
        if (textResponse is http:Response) {
            var result = textResponse.getTextPayload();
            if (result is string) {
                value = result;
            } else  {
                value = result.message();
            }
        }

        var xmlResponse = clientEP2->post("/httpClientActionBE/directPayload", xml `<yy>Sample Xml</yy>`);
        if (xmlResponse is http:Response) {
            var result = xmlResponse.getXmlPayload();
            if (result is xml) {
                value = value + (result/*).toString();
            } else {
                value = value + result.message();
            }
        }

        var jsonResponse = clientEP2->post("/httpClientActionBE/directPayload", { name: "apple", color: "red" });
        if (jsonResponse is http:Response) {
            var result = jsonResponse.getJsonPayload();
            if (result is json) {
                value = value + result.toJsonString();
            } else {
                value = value + result.message();
            }
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function get handleBinary(http:Caller caller, http:Request req) {
        string value = "";
        string textVal = "Sample Text";
        byte[] binaryValue = textVal.toBytes();
        var textResponse = clientEP2->post("/httpClientActionBE/directPayload", binaryValue);
        if (textResponse is http:Response) {
            var result = textResponse.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function get handleStringJson(http:Caller caller, http:Request request) {
      http:Request req = new;
      string payload = "a" + "\n" + "b" + "\n";
      req.setJsonPayload(payload);
      string backendPayload = checkpanic clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
      checkpanic caller->respond(<@untainted> backendPayload);
    }

    resource function get handleTextAndJsonContent(http:Caller caller, http:Request request) {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "application/json");
        string backendPayload = checkpanic clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        checkpanic caller->respond(<@untainted> backendPayload);
    }

    resource function get handleTextAndXmlContent(http:Caller caller, http:Request request) {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "text/xml");
        string backendPayload = checkpanic clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        checkpanic caller->respond(<@untainted> backendPayload);
    }

    resource function get handleTextAndJsonAlternateContent(http:Caller caller, http:Request request) {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "application/json");
        req.setJsonPayload(payload);
        string backendPayload = checkpanic clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        checkpanic caller->respond(<@untainted> backendPayload);
    }

    resource function get handleStringJsonAlternate(http:Caller caller, http:Request request) {
      http:Request req = new;
      string payload = "a" + "\n" + "b" + "\n";
      req.setJsonPayload(payload);
      req.setTextPayload(payload, contentType = "application/json");
      string backendPayload = checkpanic clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
      checkpanic caller->respond(<@untainted> backendPayload);
    }

    // TODO: Enable after the I/O revamp
    // resource function post handleByteChannel(http:Caller caller, http:Request req) {
    //     string value = "";
    //     var byteChannel = req.getByteChannel();
    //     if (byteChannel is io:ReadableByteChannel) {
    //         var res = clientEP2->post("/httpClientActionBE/byteChannel", <@untainted> byteChannel);
    //         if (res is http:Response) {
    //             var result = res.getTextPayload();
    //             if (result is string) {
    //                 value = result;
    //             } else {
    //                 value = result.message();
    //             }
    //         } else {
    //             value = res.message();
    //         }
    //     } else {
    //         value = byteChannel.message();
    //     }
    //     checkpanic caller->respond(<@untainted> value);
    // }

    resource function post handleByteStream(http:Caller caller, http:Request req) {
        string value = "";
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            var res = clientEP2->post("/httpClientActionBE/byteStream", <@untainted> byteStream);
            if (res is http:Response) {
                stream<byte[], io:Error?>|error str = res.getByteStream();
                if (str is stream<byte[], io:Error?>) {
                    record {|byte[] value;|}|io:Error? arr1 = str.next();
                    if (arr1 is record {|byte[] value;|}) {
                        value = checkpanic strings:fromBytes(arr1.value);
                    } else {
                        value = "Found unexpected arr1 output type";
                    }
                } else {
                    value = "Found unexpected str output type" + str.message();
                }
            } else {
                value = res.message();
            }
        } else {
            value = byteStream.message();
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function post handleByteStreamToText(http:Caller caller, http:Request req) {
        string value = "";
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            var res = clientEP2->post("/httpClientActionBE/byteStream", <@untainted> byteStream);
            if (res is http:Response) {
                var result = res.getTextPayload();
                if (result is string) {
                    value = result;
                } else {
                    value = result.message();
                }
            } else {
                value = res.message();
            }
        } else {
            value = byteStream.message();
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function post handleTextToByteStream(http:Caller caller, http:Request req) {
        string value = "";
        var text = req.getTextPayload();
        if (text is string) {
            var res = clientEP2->post("/httpClientActionBE/_bulk", <@untainted> text);
            if (res is http:Response) {
                stream<byte[], io:Error?>|error str = res.getByteStream();
                if (str is stream<byte[], io:Error?>) {
                    record {|byte[] value;|}|io:Error? arr1 = str.next();
                    if (arr1 is record {|byte[] value;|}) {
                        value = checkpanic strings:fromBytes(arr1.value);
                    } else {
                        value = "Found unexpected arr1 output type";
                    }
                } else {
                    value = "Found unexpected str output type" + str.message();
                }
            } else {
                value = res.message();
            }
        } else {
            value = text.message();
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function get handleMultiparts(http:Caller caller, http:Request req) {
        string value = "";
        mime:Entity part1 = new;
        part1.setJson({ "name": "wso2" });
        mime:Entity part2 = new;
        part2.setText("Hello");
        mime:Entity[] bodyParts = [part1, part2];

        var res = clientEP2->post("/httpClientActionBE/directPayload", bodyParts);
        if (res is http:Response) {
            var returnParts = res.getBodyParts();
            if (returnParts is mime:Entity[]) {
                foreach var bodyPart in returnParts {
                    var mediaType = mime:getMediaType(bodyPart.getContentType());
                    if (mediaType is mime:MediaType) {
                        string baseType = mediaType.getBaseType();
                        if (mime:APPLICATION_JSON == baseType) {
                            var payload = bodyPart.getJson();
                            if (payload is json) {
                                value = payload.toJsonString();
                            } else {
                                value = payload.message();
                            }
                        }
                        if (mime:TEXT_PLAIN == baseType) {
                            var textVal = bodyPart.getText();
                            if (textVal is string) {
                                value = value + textVal;
                            } else {
                                value = value + textVal.message();
                            }
                        }
                    } else {
                        value = value + mediaType.message();
                    }
                }
            } else {
                value = returnParts.message();
            }
        } else {
            value = res.message();
        }
        checkpanic caller->respond(<@untainted> value);
    }

    resource function get testPathWithWhitespacesForLiteral(http:Caller caller) returns @tainted error? {
        http:Response response = <http:Response> check clientEP2->get("/httpClientActionBE/a/b c/d ");
        error? res = caller->respond(<@untainted> response);
    }

    resource function get testClientPathWithWhitespacesForExpression(http:Caller caller) returns @tainted error? {
        http:Response response = <http:Response> check clientEP2->get(
            "/httpClientActionBE/dispatched to white_spaced expression ");
        error? res = caller->respond(<@untainted> response);
    }
}

@test:Config {}
function testGetAction() {
    var response = httpClientActionClient->get("/clientGet");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "HelloHelloHello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostAction() {
    var response = httpClientActionClient->get("/clientPostWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "No payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostActionWithBody() {
    var response = httpClientActionClient->get("/clientPostWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample TextSample Xml{\"name\":\"apple\", \"color\":\"red\"}");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithBlob() {
    var response = httpClientActionClient->get("/handleBinary");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// TODO: Enable after the I/O revamp
@test:Config {enable:false}
function testPostWithByteChannel() {
    var response = httpClientActionClient->post("/handleByteChannel", "Sample Text");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithByteStream() {
    var response = httpClientActionClient->post("/handleByteStream", "Sample Text");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithByteStreamToText() {
    var response = httpClientActionClient->post("/handleByteStreamToText", "Sample Text");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithTextToByteStream() {
    var response = httpClientActionClient->post("/handleTextToByteStream", "Sample Text");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithBodyParts() {
    var response = httpClientActionClient->get("/handleMultiparts");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"name\":\"wso2\"}Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests when the call to setJsonPayload is made with a string having a new line
@test:Config {}
function testPostWithStringJson() {
    var response = httpClientActionClient->get("/handleStringJson");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "\"a\\nb\\n\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests when a call to setTextPayload is made with a string having a new line while setting the contentType header to application/json
@test:Config {}
function testPostWithTextAndJsonContent() {
    var response = httpClientActionClient->get("/handleTextAndJsonContent");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Call setTextPayload with text/xml contentType for invalid xml
@test:Config {}
function testPostWithTextAndXmlContent() {
    var response = httpClientActionClient->get("/handleTextAndXmlContent");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests setTextPayload call followed by setJsonPayload call for payload string having new lines
@test:Config {}
function testPostWithTextAndJsonAlternateContent() {
    var response = httpClientActionClient->get("/handleTextAndJsonAlternateContent");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "\"a\\nb\\n\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Call setJsonPayload followed by setTextPayload for payload string with new lines
@test:Config {}
function testPostWithStringJsonAlternate() {
    var response = httpClientActionClient->get("/handleStringJsonAlternate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test client path with whitespaces
@test:Config {}
function testClientPathWithWhitespaces() {
    var response = httpClientActionClient->get("/testPathWithWhitespacesForLiteral");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "dispatched to white_spaced literal");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpClientActionClient->get("/testClientPathWithWhitespacesForExpression");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "dispatched to white_spaced expression");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testClientInitWithMalformedURL() {
    http:Client|error httpEndpoint = new ("invalid URL here");
    if (httpEndpoint is error) {
        test:assertEquals(httpEndpoint.message(), "malformed URL: invalid URL here", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
public function testProxyClientError() {
    http:Client|error clientEP = new("http://localhost:9218",
        { http1Settings: { proxy: { host:"ballerina", port:9219 }}});
    if (clientEP is error) {
        test:assertEquals(clientEP.message(), "Failed to resolve host: ballerina", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}
