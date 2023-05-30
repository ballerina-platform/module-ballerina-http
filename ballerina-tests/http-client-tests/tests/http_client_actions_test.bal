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
import ballerina/http_test_common as common;

listener http:Listener httpClientActionListenerEP1 = new (httpClientActionTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener httpClientActionListenerEP2 = new (httpClientActionTestPort2, httpVersion = http:HTTP_1_1);

final http:Client httpClientActionClient = check new ("http://localhost:" + httpClientActionTestPort2.toString() + "/httpClientActionTestService",
    httpVersion = http:HTTP_1_1);

final http:Client clientEP2 = check new ("http://localhost:" + httpClientActionTestPort1.toString(),
    httpVersion = http:HTTP_1_1, cache = {enabled: false});

service /httpClientActionBE on httpClientActionListenerEP1 {

    resource function get greeting(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello");
    }

    // TODO: Enable after the I/O revamp
    // resource function post byteChannel(http:Caller caller, http:Request req) {
    //     var byteChannel = req.getByteChannel();
    //     if (byteChannel is io:ReadableByteChannel) {
    //         check caller->respond( byteChannel);
    //     } else {
    //         check caller->respond( byteChannel.message());
    //     }
    // }

    resource function post byteStream(http:Caller caller, http:Request req) returns error? {
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            check caller->respond(byteStream);
        } else {
            check caller->respond(byteStream.message());
        }
    }

    resource function post directPayload(http:Caller caller, http:Request req) returns error? {
        if (req.hasHeader("content-type")) {
            var mediaType = mime:getMediaType(req.getContentType());
            if (mediaType is mime:MediaType) {
                string baseType = mediaType.getBaseType();
                if (mime:TEXT_PLAIN == baseType) {
                    var textValue = req.getTextPayload();
                    if (textValue is string) {
                        check caller->respond(textValue);
                    } else {
                        check caller->respond(textValue.message());
                    }
                } else if (mime:APPLICATION_XML == baseType) {
                    var xmlValue = req.getXmlPayload();
                    if (xmlValue is xml) {
                        check caller->respond(xmlValue);
                    } else {
                        check caller->respond(xmlValue.message());
                    }
                } else if (mime:APPLICATION_JSON == baseType) {
                    var jsonValue = req.getJsonPayload();
                    if (jsonValue is json) {
                        check caller->respond(jsonValue);
                    } else {
                        check caller->respond(jsonValue.message());
                    }
                } else if (mime:APPLICATION_OCTET_STREAM == baseType) {
                    var blobValue = req.getBinaryPayload();
                    if (blobValue is byte[]) {
                        check caller->respond(blobValue);
                    } else {
                        check caller->respond(blobValue.message());
                    }
                } else if (mime:MULTIPART_FORM_DATA == baseType) {
                    var bodyParts = req.getBodyParts();
                    if (bodyParts is mime:Entity[]) {
                        check caller->respond(bodyParts);
                    } else {
                        check caller->respond(bodyParts.message());
                    }
                }
            } else {
                check caller->respond("Error in parsing media type");
            }
        } else {
            check caller->respond();
        }
    }

    resource function 'default _bulk(http:Caller caller, http:Request request) returns error? {
        check caller->respond(check request.getTextPayload());
    }

    // withWhitespacedExpression
    resource function 'default [string id](http:Caller caller, http:Request request) returns error? {
        check caller->respond(id);
    }

    // withWhitespacedLiteral
    resource function 'default a/b\ c/d(http:Caller caller, http:Request request) returns error? {
        check caller->respond("dispatched to white_spaced literal");
    }
}

service /httpClientActionTestService on httpClientActionListenerEP2 {

    resource function get clientGet(http:Caller caller, http:Request req) returns error? {
        string value = "";
        //No Payload
        http:Response|error response1 = clientEP2->get("/httpClientActionBE/greeting");
        if (response1 is http:Response) {
            var result = response1.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }

        //No Payload
        http:Response|error response2 = clientEP2->get("/httpClientActionBE/greeting", ());
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
        http:Response|error response3 = clientEP2->get("/httpClientActionBE/greeting");
        if (response3 is http:Response) {
            var result = response3.getTextPayload();
            if (result is string) {
                value = value + result;
            } else {
                value = value + result.message();
            }
        }
        check caller->respond(value);
    }

    resource function get clientPostWithoutBody(http:Caller caller, http:Request req) returns error? {
        string value = "";
        //No Payload
        http:Response|error clientResponse = clientEP2->post("/httpClientActionBE/directPayload", ());
        if clientResponse is http:Response {
            var returnValue = clientResponse.getTextPayload();
            if (returnValue is string) {
                value = returnValue;
            } else {
                value = returnValue.message();
            }
        } else {
            value = clientResponse.message();
        }

        check caller->respond(value);
    }

    resource function get clientPostWithBody(http:Caller caller, http:Request req) returns error? {
        string value = "";
        http:Response|error textResponse = clientEP2->post("/httpClientActionBE/directPayload", "Sample Text");
        if (textResponse is http:Response) {
            var result = textResponse.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }

        http:Response|error xmlResponse = clientEP2->post("/httpClientActionBE/directPayload", xml `<yy>Sample Xml</yy>`);
        if (xmlResponse is http:Response) {
            var result = xmlResponse.getXmlPayload();
            if (result is xml) {
                value = value + (result/*).toString();
            } else {
                value = value + result.message();
            }
        }

        http:Response|error jsonResponse = clientEP2->post("/httpClientActionBE/directPayload", {name: "apple", color: "red"});
        if (jsonResponse is http:Response) {
            var result = jsonResponse.getJsonPayload();
            if (result is json) {
                value = value + result.toJsonString();
            } else {
                value = value + result.message();
            }
        }
        check caller->respond(value);
    }

    resource function get handleBinary(http:Caller caller, http:Request req) returns error? {
        string value = "";
        string textVal = "Sample Text";
        byte[] binaryValue = textVal.toBytes();
        http:Response|error textResponse = clientEP2->post("/httpClientActionBE/directPayload", binaryValue);
        if (textResponse is http:Response) {
            var result = textResponse.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }
        check caller->respond(value);
    }

    resource function get handleStringJson(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setJsonPayload(payload);
        string backendPayload = check clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        check caller->respond(backendPayload);
    }

    resource function get handleTextAndJsonContent(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "application/json");
        string backendPayload = check clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        check caller->respond(backendPayload);
    }

    resource function get handleTextAndXmlContent(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "text/xml");
        string backendPayload = check clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        check caller->respond(backendPayload);
    }

    resource function get handleTextAndJsonAlternateContent(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setTextPayload(payload, contentType = "application/json");
        req.setJsonPayload(payload);
        string backendPayload = check clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        check caller->respond(backendPayload);
    }

    resource function get handleStringJsonAlternate(http:Caller caller, http:Request request) returns error? {
        http:Request req = new;
        string payload = "a" + "\n" + "b" + "\n";
        req.setJsonPayload(payload);
        req.setTextPayload(payload, contentType = "application/json");
        string backendPayload = check clientEP2->post("/httpClientActionBE/_bulk", req, targetType = string);
        check caller->respond(backendPayload);
    }

    // TODO: Enable after the I/O revamp
    // resource function post handleByteChannel(http:Caller caller, http:Request req) {
    //     string value = "";
    //     var byteChannel = req.getByteChannel();
    //     if (byteChannel is io:ReadableByteChannel) {
    //         http:Response|error res = clientEP2->post("/httpClientActionBE/byteChannel",  byteChannel);
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
    //     check caller->respond( value);
    // }

    resource function post handleByteStream(http:Caller caller, http:Request req) returns error? {
        string value = "";
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            http:Response|error res = clientEP2->post("/httpClientActionBE/byteStream", byteStream);
            if (res is http:Response) {
                stream<byte[], io:Error?>|error str = res.getByteStream();
                if (str is stream<byte[], io:Error?>) {
                    record {|byte[] value;|}|io:Error? arr1 = str.next();
                    if (arr1 is record {|byte[] value;|}) {
                        value = check strings:fromBytes(arr1.value);
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
        check caller->respond(value);
    }

    resource function post handleByteStreamToText(http:Caller caller, http:Request req) returns error? {
        string value = "";
        var byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            http:Response|error res = clientEP2->post("/httpClientActionBE/byteStream", byteStream);
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
        check caller->respond(value);
    }

    resource function post handleTextToByteStream(http:Caller caller, http:Request req) returns error? {
        string value = "";
        var text = req.getTextPayload();
        if (text is string) {
            http:Response|error res = clientEP2->post("/httpClientActionBE/_bulk", text);
            if (res is http:Response) {
                stream<byte[], io:Error?>|error str = res.getByteStream();
                if (str is stream<byte[], io:Error?>) {
                    record {|byte[] value;|}|io:Error? arr1 = str.next();
                    if (arr1 is record {|byte[] value;|}) {
                        value = check strings:fromBytes(arr1.value);
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
        check caller->respond(value);
    }

    resource function get handleMultiparts(http:Caller caller, http:Request req) returns error? {
        string value = "";
        mime:Entity part1 = new;
        part1.setJson({"name": "wso2"});
        mime:Entity part2 = new;
        part2.setText("Hello");
        mime:Entity[] bodyParts = [part1, part2];

        http:Response|error res = clientEP2->post("/httpClientActionBE/directPayload", bodyParts);
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
        check caller->respond(value);
    }

    resource function get testPathWithWhitespacesForLiteral(http:Caller caller) returns error? {
        http:Response response = check clientEP2->get("/httpClientActionBE/a/b c/d ");
        check caller->respond(response);
    }

    resource function get testClientPathWithWhitespacesForExpression(http:Caller caller) returns error? {
        http:Response response = check clientEP2->get("/httpClientActionBE/dispatched to white_spaced expression ");
        check caller->respond(response);
    }

    resource function get testServiceUnavailable() returns error? {
        http:Client ep = checkpanic new("http://localhost:8080");
        return ep->get("/bar");
    }
}

@test:Config {}
function testGetAction() returns error? {
    http:Response|error response = httpClientActionClient->get("/clientGet");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "HelloHelloHello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostAction() returns error? {
    http:Response|error response = httpClientActionClient->get("/clientPostWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No content");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostActionWithBody() returns error? {
    http:Response|error response = httpClientActionClient->get("/clientPostWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample TextSample Xml{\"name\":\"apple\", \"color\":\"red\"}");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithBlob() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleBinary");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// TODO: Enable after the I/O revamp
@test:Config {enable: false}
function testPostWithByteChannel() returns error? {
    http:Response|error response = httpClientActionClient->post("/handleByteChannel", "Sample Text");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithByteStream() returns error? {
    http:Response|error response = httpClientActionClient->post("/handleByteStream", "Sample Text");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithByteStreamToText() returns error? {
    http:Response|error response = httpClientActionClient->post("/handleByteStreamToText", "Sample Text");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithTextToByteStream() returns error? {
    http:Response|error response = httpClientActionClient->post("/handleTextToByteStream", "Sample Text");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPostWithBodyParts() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleMultiparts");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"name\":\"wso2\"}Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests when the call to setJsonPayload is made with a string having a new line
@test:Config {}
function testPostWithStringJson() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleStringJson");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "\"a\\nb\\n\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests when a call to setTextPayload is made with a string having a new line while setting the contentType header to application/json
@test:Config {}
function testPostWithTextAndJsonContent() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleTextAndJsonContent");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Call setTextPayload with text/xml contentType for invalid xml
@test:Config {}
function testPostWithTextAndXmlContent() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleTextAndXmlContent");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests setTextPayload call followed by setJsonPayload call for payload string having new lines
@test:Config {}
function testPostWithTextAndJsonAlternateContent() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleTextAndJsonAlternateContent");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "\"a\\nb\\n\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Call setJsonPayload followed by setTextPayload for payload string with new lines
@test:Config {}
function testPostWithStringJsonAlternate() returns error? {
    http:Response|error response = httpClientActionClient->get("/handleStringJsonAlternate");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "a\nb\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test client path with whitespaces
@test:Config {}
function testClientPathWithWhitespaces() returns error? {
    http:Response|error response = httpClientActionClient->get("/testPathWithWhitespacesForLiteral");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "dispatched to white_spaced literal");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpClientActionClient->get("/testClientPathWithWhitespacesForExpression");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "dispatched to white_spaced expression");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testClientInitWithMalformedURL() {
    http:Client|error httpEndpoint = new ("httpeds://bar.com/foo", httpVersion = http:HTTP_1_1);
    if (httpEndpoint is error) {
        test:assertEquals(httpEndpoint.message(), "malformed URL: httpeds://bar.com/foo", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
public function testProxyClientError() {
    http:Client|error clientEP = new ("http://localhost:9218",
        httpVersion = http:HTTP_1_1, proxy = {host: "ballerina", port: 9219});
    if (clientEP is error) {
        test:assertEquals(clientEP.message(), "Failed to resolve host: ballerina", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
public function testProxyClientErrorWithDeprecatedConfig() {
    http:Client|error clientEP = new ("http://localhost:9218",
            {httpVersion: "1.1", http1Settings: {proxy: {host: "ballerina", port: 9219}}});
    if (clientEP is error) {
        test:assertEquals(clientEP.message(), "Failed to resolve host: ballerina", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testClientInitWithoutScheme() {
    http:Client|error httpEndpoint = new ("bar.com/foo", httpVersion = http:HTTP_1_1);
    if httpEndpoint is error {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testClientInitWithEmptyUrl() {
    http:Client|error httpEndpoint = new ("", httpVersion = http:HTTP_1_1);
    if (httpEndpoint is error) {
        test:assertEquals(httpEndpoint.message(), "malformed URL: ", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testServiceUnavailable() returns error? {
    http:Response|error response = httpClientActionClient->get("/testServiceUnavailable");
    if response is http:Response {
        test:assertEquals(response.statusCode, 502);
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "Something wrong with the connection: Connection refused: localhost/127.0.0.1:8080",
                    "Bad Gateway", 502, "/httpClientActionTestService/testServiceUnavailable", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
