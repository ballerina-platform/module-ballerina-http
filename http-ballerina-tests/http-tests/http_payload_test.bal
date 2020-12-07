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

listener http:Listener httpPayloadListenerEP1 = new(httpPayloadTestPort1);
listener http:Listener httpPayloadListenerEP2 = new(httpPayloadTestPort2);
http:Client httpPayloadClient = new("http://localhost:" + httpPayloadTestPort1.toString());

http:Client clientEP19 = new("http://localhost:" + httpPayloadTestPort2.toString());

@http:ServiceConfig {
    basePath: "/test"
}
service testService16 on httpPayloadListenerEP1 {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function getPayload(http:Caller caller, http:Request request) {
        var res = clientEP19->get("/payloadTest");
        if (res is http:Response) {
            //First get the payload as a byte array, then take it as an xml
            var binaryPayload = res.getBinaryPayload();
            if (binaryPayload is byte[]) {
                var payload = res.getXmlPayload();
                if (payload is xml) {
                    //xml descendants = payload.selectDescendants("title");
                    checkpanic caller->respond(<@untainted> (payload/**/<title>/*).toString());
                } else {
                    checkpanic caller->respond(<@untainted> payload.message());
                }
            } else {
                checkpanic caller->respond(<@untainted> binaryPayload.message());
            }
        } else if (res is error) {
            checkpanic caller->respond(<@untainted> res.message());
        }
    }

    resource function getPayloadForParseError(http:Caller caller, http:Request request) {
        var res = clientEP19->get("/payloadTest/getString");
        if (res is http:Response) {
            var payload = res.getXmlPayload();
            if (payload is xml) {
                //xml descendants = payload.selectDescendants("title");
                checkpanic caller->respond(<@untainted> (payload/**/<title>/*).toString());
            } else {
                if (payload is http:GenericClientError) {
                    var cause = payload.cause();
                    if (cause is mime:ParserError) {
                        checkpanic caller->respond(<@untainted> cause.message());
                    }
                }
            }
        }
    }
}

@http:ServiceConfig {
    basePath: "/payloadTest"
}
service testPayload17 on httpPayloadListenerEP2 {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function sendXml(http:Caller caller, http:Request req) {
        xml xmlPayload = xml `<xml version="1.0">
                                <channel>
                                    <title>W3Schools Home Page</title>
                                    <link>https://www.w3schools.com</link>
                                      <description>Free web building tutorials</description>
                                      <item>
                                        <title>RSS Tutorial</title>
                                        <link>https://www.w3schools.com/xml/xml_rss.asp</link>
                                        <description>New RSS tutorial on W3Schools</description>
                                      </item>
                                </channel>
                              </xml>`;
        checkpanic caller->respond(<@untainted> xmlPayload);
    }

    resource function getString(http:Caller caller, http:Request req) {
        string stringPayload = "";
        int i = 0;
        while(i<1000) {
            stringPayload = stringPayload + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            i = i + 1;
        }
        checkpanic caller->respond(<@untainted> stringPayload);
    }
}

//Test whether the xml payload gets parsed properly, after the said payload has been retrieved as a byte array.
@test:Config {}
function testXmlPayload() {
    var response = httpPayloadClient->get("/test/");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "W3Schools Home PageRSS Tutorial");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test getXmlPayload() for inbound response with parser errors.
//FullMessageListener is notified via transport thread and thrown exception should be caught at ballerina space
@test:Config {}
function testGetXmlPayloadReturnParserError() {
    var response = httpPayloadClient->get("/test/getPayloadForParseError");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(),
                "Error occurred while extracting xml data from entity: error(\"failed to create xml");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
