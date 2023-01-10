// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client http2Client = check new ("http://localhost:9122", http2Settings = {http2PriorKnowledge: true});

service /backEndService on new http:Listener(9122) {

    resource function get http2ReplyText(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello");
    }

    // TODO: Enable after the I/O revamp
    // resource function post http2SendByteChannel(http:Caller caller, http:Request req) {
    //     var byteChannel = req.getByteChannel();
    //     if byteChannel is io:ReadableByteChannel {
    //         check caller->respond(byteChannel);
    //     } else {
    //         check caller->respond(byteChannel.message());
    //     }
    // }

    resource function post http2SendByteStream(http:Caller caller, http:Request req) returns error? {
        var byteStream = req.getByteStream();
        if byteStream is stream<byte[], io:Error?> {
            check caller->respond(byteStream);
        } else {
            check caller->respond(byteStream.message());
        }
    }

    resource function post http2PostReply(http:Caller caller, http:Request req) returns error? {
        if req.hasHeader("content-type") {
            var mediaType = mime:getMediaType(req.getContentType());
            if mediaType is mime:MediaType {
                string baseType = mediaType.getBaseType();
                if mime:TEXT_PLAIN == baseType {
                    var textValue = req.getTextPayload();
                    if textValue is string {
                        check caller->respond(textValue);
                    } else {
                        check caller->respond(textValue.message());
                    }
                } else if mime:APPLICATION_XML == baseType {
                    var xmlValue = req.getXmlPayload();
                    if xmlValue is xml {
                        check caller->respond(xmlValue);
                    } else {
                        check caller->respond(xmlValue.message());
                    }
                } else if mime:APPLICATION_JSON == baseType {
                    var jsonValue = req.getJsonPayload();
                    if jsonValue is json {
                        check caller->respond(jsonValue);
                    } else {
                        check caller->respond(jsonValue.message());
                    }
                } else if mime:APPLICATION_OCTET_STREAM == baseType {
                    var blobValue = req.getBinaryPayload();
                    if blobValue is byte[] {
                        check caller->respond(blobValue);
                    } else {
                        check caller->respond(blobValue.message());
                    }
                }
            } else {
                check caller->respond("Error in parsing media type");
            }
        } else {
            check caller->respond();
        }
    }
}

service /testHttp2Service on new http:Listener(9123) {

    resource function get clientGet(http:Caller caller, http:Request req) returns error? {
        string value = "";
        //No Payload
        http:Response|error response1 = http2Client->get("/backEndService/http2ReplyText");
        if response1 is http:Response {
            var result = response1.getTextPayload();
            if result is string {
                value = result;
            } else {
                value = result.message();
            }
        }

        //No Payload
        http:Response|error response2 = http2Client->get("/backEndService/http2ReplyText", ());
        if response2 is http:Response {
            var result = response2.getTextPayload();
            if result is string {
                value = value + result;
            } else {
                value = value + result.message();
            }
        }

        //With headers
        http:Response|error response3 = http2Client->get("/backEndService/http2ReplyText", {"x-type": "hello"});
        if response3 is http:Response {
            var result = response3.getTextPayload();
            if result is string {
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
        http:Response|error clientResponse = http2Client->post("/backEndService/http2PostReply", ());
        if clientResponse is http:Response {
            var returnValue = clientResponse.getTextPayload();
            if returnValue is string {
                value = returnValue;
            } else {
                value = returnValue.message();
            }
        } else {
            value = <string>clientResponse.message();
        }

        check caller->respond(value);
    }

    resource function get clientPostWithBody(http:Caller caller, http:Request req) returns error? {
        string value = "";
        http:Response|error textResponse = http2Client->post("/backEndService/http2PostReply", "Sample Text");
        if textResponse is http:Response {
            var result = textResponse.getTextPayload();
            if result is string {
                value = result;
            } else {
                value = result.message();
            }
        }

        http:Response|error xmlResponse = http2Client->post("/backEndService/http2PostReply", xml `<yy>Sample Xml</yy>`);
        if xmlResponse is http:Response {
            var result = xmlResponse.getXmlPayload();
            if result is xml {
                value = value + (result/*).toString();
            } else {
                value = value + result.message();
            }
        }

        http:Response|error jsonResponse = http2Client->post("/backEndService/http2PostReply", {name: "apple", color: "red"});
        if jsonResponse is http:Response {
            var result = jsonResponse.getJsonPayload();
            if result is json {
                value = value + result.toJsonString();
            } else {
                value = value + result.message();
            }
        }
        check caller->respond(value);
    }

    resource function get testHttp2PostWithBinaryData(http:Caller caller, http:Request req) returns error? {
        string value = "";
        string textVal = "Sample Text";
        byte[] binaryValue = textVal.toBytes();
        http:Response|error textResponse = http2Client->post("/backEndService/http2PostReply", binaryValue);
        if textResponse is http:Response {
            var result = textResponse.getTextPayload();
            if result is string {
                value = result;
            } else {
                value = result.message();
            }
        }
        check caller->respond(value);
    }

    // TODO: Enable after the I/O revamp
    // resource function post testHttp2PostWithByteChannel(http:Caller caller, http:Request req) {
    //     string value = "";
    //     var byteChannel = req.getByteChannel();
    //     if byteChannel is io:ReadableByteChannel {
    //         http:Response|error res = http2Client->post("/backEndService/http2SendByteChannel", <@untainted> byteChannel);
    //         if res is http:Response {
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
    //     check caller->respond(<@untainted> value);
    // }

    resource function post testHttp2PostWithTextToStream(http:Caller caller, http:Request req) returns error? {
        string value = "";
        var text = req.getTextPayload();
        if (text is string) {
            http:Response|error res = http2Client->post("/backEndService/http2SendByteStream", text);
            if (res is http:Response) {
                stream<byte[], io:Error?>|http:ClientError str = res.getByteStream();
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

    resource function post testHttp2PostWithByteStream(http:Caller caller, http:Request req) returns error? {
        string value = "";
        stream<byte[], io:Error?>|http:ClientError byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            http:Response|error res = http2Client->post("/backEndService/http2SendByteStream", byteStream);
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

    resource function post testHttp2PostWithByteStreamToText(http:Caller caller, http:Request req) returns error? {
        string value = "";
        stream<byte[], io:Error?>|http:ClientError byteStream = req.getByteStream();
        if (byteStream is stream<byte[], io:Error?>) {
            http:Response|error res = http2Client->post("/backEndService/http2SendByteStream", byteStream);
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
}

@test:Config {}
public function testHttp2GetAction() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->get("/testHttp2Service/clientGet");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "HelloHelloHello");
        common:assertHeaderValue(check resp.getHeader("content-type"), "text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostAction() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->get("/testHttp2Service/clientPostWithoutBody");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "No content");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostActionWithBody() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->get("/testHttp2Service/clientPostWithBody");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample TextSample Xml{\"name\":\"apple\", \"color\":\"red\"}");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithBlob() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->get("/testHttp2Service/testHttp2PostWithBinaryData");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

// TODO: Enable after the I/O revamp
@test:Config {enable: false}
public function testHttp2PostWithByteChannel() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->post("/testHttp2Service/testHttp2PostWithByteChannel", "Sample Text");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithTextToStream() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->post("/testHttp2Service/testHttp2PostWithTextToStream", "Sample Text");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithByteStream() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->post("/testHttp2Service/testHttp2PostWithByteStream", "Sample Text");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithByteStreamToTextPayloadOfClient() returns error? {
    http:Client clientEP = check new ("http://localhost:9123");
    http:Response|error resp = clientEP->post("/testHttp2Service/testHttp2PostWithByteStreamToText", "Sample Text");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
