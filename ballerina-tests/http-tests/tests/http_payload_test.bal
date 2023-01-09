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

listener http:Listener httpPayloadListenerEP1 = new (httpPayloadTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener httpPayloadListenerEP2 = new (httpPayloadTestPort2, httpVersion = http:HTTP_1_1);
final http:Client httpPayloadClient = check new ("http://localhost:" + httpPayloadTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client clientEP19 = check new ("http://localhost:" + httpPayloadTestPort2.toString(), httpVersion = http:HTTP_1_1);

service /testService16 on httpPayloadListenerEP1 {

    resource function get .(http:Caller caller, http:Request request) returns error? {
        http:Response|error res = clientEP19->get("/payloadTest");
        if res is http:Response {
            //First get the payload as a byte array, then take it as an xml
            var binaryPayload = res.getBinaryPayload();
            if binaryPayload is byte[] {
                var payload = res.getXmlPayload();
                if payload is xml {
                    //xml descendants = payload.selectDescendants("title");
                    check caller->respond((payload/**/<title>/*).toString());
                } else {
                    check caller->respond(payload.message());
                }
            } else {
                check caller->respond(binaryPayload.message());
            }
        } else {
            check caller->respond(res.message());
        }
    }

    resource function 'default getPayloadForParseError(http:Caller caller, http:Request request) returns error? {
        http:Response|error res = clientEP19->get("/payloadTest/getString");
        if res is http:Response {
            var payload = res.getXmlPayload();
            if payload is xml {
                //xml descendants = payload.selectDescendants("title");
                check caller->respond((payload/**/<title>/*).toString());
            } else {
                if payload is http:GenericClientError {
                    var cause = payload.cause();
                    if cause is mime:ParserError {
                        check caller->respond(cause.message());
                    }
                }
            }
        }
    }
}

service /payloadTest on httpPayloadListenerEP2 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
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
        check caller->respond(xmlPayload);
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        string stringPayload = "";
        int i = 0;
        while (i < 1000) {
            stringPayload = stringPayload + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            i = i + 1;
        }
        check caller->respond(stringPayload);
    }
}

//Test whether the xml payload gets parsed properly, after the said payload has been retrieved as a byte array.
@test:Config {}
function testXmlPayload() returns error? {
    http:Response|error response = httpPayloadClient->get("/testService16/");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "W3Schools Home PageRSS Tutorial");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test getXmlPayload() for inbound response with parser errors.
//FullMessageListener is notified via transport thread and thrown exception should be caught at ballerina space
@test:Config {}
function testGetXmlPayloadReturnParserError() returns error? {
    http:Response|error response = httpPayloadClient->get("/testService16/getPayloadForParseError");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTrueTextPayload(response.getTextPayload(),
                "Error occurred while extracting xml data from entity: error(\"failed to create xml");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
