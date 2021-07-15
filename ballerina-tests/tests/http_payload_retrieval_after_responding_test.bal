// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener payloadRetrievalListener = new(payloadRetrievalAfterRespondingTestPort);
http:Client payloadRetrievalBackendClient = check new("http://localhost:" + payloadRetrievalAfterRespondingTestPort.toString());
http:Client payloadRetrievalTestClient = check new("http://localhost:" + payloadRetrievalAfterRespondingTestPort.toString());

json? requestJsonPaylod = ();
xml? requestXmlPayload = ();
string? requestTextPayload = ();
byte[]? requestBinaryPayload = ();

service /passthrough on payloadRetrievalListener {
    resource function 'default . () returns string|error {
        json jsonStr = {a: "a", b: "b"};
        json jsonPayload = check payloadRetrievalBackendClient->post("/backend/getJson", jsonStr);

        xml xmlStr = xml `<name>Ballerina</name>`;
        xml xmlPayload = check payloadRetrievalBackendClient->post("/backend/getXml", xmlStr);

        string stringPayload = check payloadRetrievalBackendClient->post("/backend/getString", "want string");
        byte[] binaryPaylod = check payloadRetrievalBackendClient->post("/backend/getByteArray", "BinaryPayload is textVal".toBytes());

        return "Request Processed successfully";
    }
}

service /backend on payloadRetrievalListener {
    resource function 'default getJson(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        check caller->respond(response);
        requestJsonPaylod = check req.getJsonPayload();
    }

    resource function 'default getXml(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        check caller->respond(response);
        requestXmlPayload = check req.getXmlPayload(); 
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        check caller->respond(response);
        requestTextPayload = check req.getTextPayload();
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        check caller->respond(response);
        requestBinaryPayload = check req.getBinaryPayload();
    }
}

@test:Config {
    groups: ["payloadRetrieveAfterRespond"]
}
function testPayloadRetrievalAfterRespondTest() returns error? {
    http:Response|error response = payloadRetrievalTestClient->get("/passthrough");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Request Processed successfully");
        test:assertTrue(requestJsonPaylod is json);
        test:assertTrue(requestXmlPayload is xml);
        test:assertTrue(requestTextPayload is string);
        test:assertTrue(requestBinaryPayload is byte[]);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
