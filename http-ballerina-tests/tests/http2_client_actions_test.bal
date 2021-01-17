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
import ballerina/mime;
import ballerina/test;

http:Client http2Client = new("http://localhost:9122", { httpVersion: "2.0",
                                http2Settings: { http2PriorKnowledge: true } });

service /backEndService on new http:Listener(9122, { httpVersion: "2.0" }) {

    resource function get http2ReplyText(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello");
    }

    resource function post http2SendByteChannel(http:Caller caller, http:Request req) {
        var byteChannel = req.getByteChannel();
        if (byteChannel is io:ReadableByteChannel) {
            checkpanic caller->respond(<@untainted> byteChannel);
        } else {
            checkpanic caller->respond(<@untainted> byteChannel.message());
        }
    }

    resource function post http2PostReply(http:Caller caller, http:Request req) {
        if (req.hasHeader("content-type")) {
            var mediaType = mime:getMediaType(req.getContentType());
            if (mediaType is mime:MediaType) {
                string baseType = mediaType.getBaseType();
                if (mime:TEXT_PLAIN == baseType) {
                    var textValue = req.getTextPayload();
                    if (textValue is string) {
                        checkpanic caller->respond(<@untainted> textValue);
                    } else {
                        checkpanic caller->respond(<@untainted string> textValue.message());
                    }
                } else if (mime:APPLICATION_XML == baseType) {
                    var xmlValue = req.getXmlPayload();
                    if (xmlValue is xml) {
                        checkpanic caller->respond(<@untainted> xmlValue);
                    } else {
                        checkpanic caller->respond(<@untainted string> xmlValue.message());
                    }
                } else if (mime:APPLICATION_JSON == baseType) {
                    var jsonValue = req.getJsonPayload();
                    if (jsonValue is json) {
                        checkpanic caller->respond(<@untainted> jsonValue);
                    } else {
                        checkpanic caller->respond(<@untainted string> jsonValue.message());
                    }
                } else if (mime:APPLICATION_OCTET_STREAM == baseType) {
                    var blobValue = req.getBinaryPayload();
                    if (blobValue is byte[]) {
                        checkpanic caller->respond(<@untainted> blobValue);
                    } else {
                        checkpanic caller->respond(<@untainted string> blobValue.message());
                    }
                }
            } else {
                checkpanic caller->respond("Error in parsing media type");
            }
        } else {
            checkpanic caller->respond();
        }
    }
}

service /testHttp2Service on new http:Listener(9123, { httpVersion: "2.0" }) {

    resource function get clientGet(http:Caller caller, http:Request req) {
        string value = "";
        //No Payload
        var response1 = http2Client->get("/backEndService/http2ReplyText");
        if (response1 is http:Response) {
            var result = response1.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }

        //No Payload
        var response2 = http2Client->get("/backEndService/http2ReplyText", ());
        if (response2 is http:Response) {
            var result = response2.getTextPayload();
            if (result is string) {
                value = value + result;
            } else {
                value = value + result.message();
            }
        }

        http:Request httpReq = new;
        //Request as message
        var response3 = http2Client->get("/backEndService/http2ReplyText", httpReq);
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
        var clientResponse = http2Client->post("/backEndService/http2PostReply", ());
        if (clientResponse is http:Response) {
            var returnValue = clientResponse.getTextPayload();
            if (returnValue is string) {
                value = returnValue;
            } else {
                value = returnValue.message();
            }
        } else if (clientResponse is error) {
            value = <string>clientResponse.message();
        }

        checkpanic caller->respond(<@untainted> value);
    }

    resource function get clientPostWithBody(http:Caller caller, http:Request req) {
        string value = "";
        var textResponse = http2Client->post("/backEndService/http2PostReply", "Sample Text");
        if (textResponse is http:Response) {
            var result = textResponse.getTextPayload();
            if (result is string) {
                value = result;
            } else  {
                value = result.message();
            }
        }

        var xmlResponse = http2Client->post("/backEndService/http2PostReply", xml `<yy>Sample Xml</yy>`);
        if (xmlResponse is http:Response) {
            var result = xmlResponse.getXmlPayload();
            if (result is xml) {
                value = value + (result/*).toString();
            } else {
                value = value + result.message();
            }
        }

        var jsonResponse = http2Client->post("/backEndService/http2PostReply", { name: "apple", color: "red" });
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

    resource function get testHttp2PostWithBinaryData(http:Caller caller, http:Request req) {
        string value = "";
        string textVal = "Sample Text";
        byte[] binaryValue = textVal.toBytes();
        var textResponse = http2Client->post("/backEndService/http2PostReply", binaryValue);
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

    resource function post testHttp2PostWithByteChannel(http:Caller caller, http:Request req) {
        string value = "";
        var byteChannel = req.getByteChannel();
        if (byteChannel is io:ReadableByteChannel) {
            var res = http2Client->post("/backEndService/http2SendByteChannel", <@untainted> byteChannel);
            if (res is http:Response) {
                var result = res.getTextPayload();
                if (result is string) {
                    value = result;
                } else {
                    value = result.message();
                }
            } else if (res is error) {
                value = res.message();
            }
        } else {
            value = byteChannel.message();
        }
        checkpanic caller->respond(<@untainted> value);
    }
}

@test:Config {}
public function testHttp2GetAction() {
    http:Client clientEP = new("http://localhost:9123");
    var resp = clientEP->get("/testHttp2Service/clientGet");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "HelloHelloHello");
        assertHeaderValue(checkpanic resp.getHeader("content-type"), "text/plain");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PostAction() {
    http:Client clientEP = new("http://localhost:9123");
    var resp = clientEP->get("/testHttp2Service/clientPostWithoutBody");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "No payload");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PostActionWithBody() {
    http:Client clientEP = new("http://localhost:9123");
    var resp = clientEP->get("/testHttp2Service/clientPostWithBody");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Sample TextSample Xml{\"name\":\"apple\", \"color\":\"red\"}");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithBlob() {
    http:Client clientEP = new("http://localhost:9123");
    var resp = clientEP->get("/testHttp2Service/testHttp2PostWithBinaryData");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PostWithByteChannel() {
    http:Client clientEP = new("http://localhost:9123");
    var resp = clientEP->post("/testHttp2Service/testHttp2PostWithByteChannel", "Sample Text");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Sample Text");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
