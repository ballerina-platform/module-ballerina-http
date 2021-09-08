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
import ballerina/lang.runtime as runtime;

listener http:Listener payloadRetrievalListener = new(payloadRetrievalAfterRespondingTestPort);
http:Client payloadRetrievalBackendClient = check new("http://localhost:" + payloadRetrievalAfterRespondingTestPort.toString());
http:Client payloadRetrievalTestClient = check new("http://localhost:" + payloadRetrievalAfterRespondingTestPort.toString());

error? requestJsonPayloadError = ();
error? requestXmlPayloadError = ();
error? requestTextPayloadError = ();
error? requestBinaryPayloadError = ();

service /passthrough on payloadRetrievalListener {
    resource function 'default . () returns string|error {
        json jsonStr = {a: "a", b: "b"};
        json jsonPayload = check payloadRetrievalBackendClient->post("/backend/getJson", jsonStr);

        xml xmlStr = xml `<name>Ballerina</name>`;
        xml xmlPayload = check payloadRetrievalBackendClient->post("/backend/getXml", xmlStr);

        string stringPayload = check payloadRetrievalBackendClient->post("/backend/getString", "want string");
        byte[] binaryPayload = check payloadRetrievalBackendClient->post("/backend/getByteArray", "BinaryPayload is textVal".toBytes());

        return "Request Processed successfully";
    }
}

service /backend on payloadRetrievalListener {
    resource function 'default getJson(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        check caller->respond(response);
        json|error result = req.getJsonPayload();
        if result is error {
            requestJsonPayloadError = result;
        }
    }

    resource function 'default getXml(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        check caller->respond(response);
        xml|error result = req.getXmlPayload();
        if result is error {
            requestXmlPayloadError = result;
        }
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        check caller->respond(response);
        string|error result = req.getTextPayload();
        if result is error {
            requestTextPayloadError = result;
        }
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        check caller->respond(response);
        byte[]|error result = req.getBinaryPayload();
        if result is error {
            requestBinaryPayloadError = result;
        }
    }
}

@test:Config {
    groups: ["payloadRetrieveAfterRespond"]
}
function testPayloadRetrievalAfterRespondTest() returns error? {
    http:Response|error response = payloadRetrievalTestClient->get("/passthrough");
    string errorMessage = "Error occurred while extracting data from entity: Content is already released";
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Request Processed successfully");
        runtime:sleep(5);
        assertErrorMessage(requestJsonPayloadError, "Error occurred while retrieving the json payload from the request");
        assertErrorCauseMessage(requestJsonPayloadError, errorMessage);
        assertErrorMessage(requestXmlPayloadError, "Error occurred while retrieving the xml payload from the request");
        assertErrorCauseMessage(requestXmlPayloadError, errorMessage);
        assertErrorMessage(requestTextPayloadError, "Error occurred while retrieving the text payload from the request");
        assertErrorCauseMessage(requestTextPayloadError, errorMessage);
        assertErrorMessage(requestBinaryPayloadError, "Error occurred while retrieving the binary payload from the request");
        assertErrorCauseMessage(requestBinaryPayloadError, errorMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
