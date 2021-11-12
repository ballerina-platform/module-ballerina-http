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
import ballerina/log;
import ballerina/lang.runtime as runtime;

listener http:Listener payloadAccessAfterRespondListener = new(payloadAccessAfterRespondingTestPort);
final http:Client payloadAccessAfterRespondBackendClient = check new("http://localhost:" + payloadAccessAfterRespondingTestPort.toString());
final http:Client payloadAccessAfterRespondTestClient = check new("http://localhost:" + payloadAccessAfterRespondingTestPort.toString());

isolated error? requestJsonPayloadError = ();
isolated error? requestXmlPayloadError = ();
isolated error? requestTextPayloadError = ();
isolated error? requestBinaryPayloadError = ();

service /passthrough on payloadAccessAfterRespondListener {
    resource function 'default . () returns string|error {
        json jsonStr = {a: "a", b: "b"};
        json|error jsonPayload = payloadAccessAfterRespondBackendClient->post("/backend/getJson", jsonStr);
        if jsonPayload is error {
            log:printError("Error reading payload", 'error = jsonPayload);
        }

        xml xmlStr = xml `<name>Ballerina</name>`;
        xml|error xmlPayload = payloadAccessAfterRespondBackendClient->post("/backend/getXml", xmlStr);
        if xmlPayload is error {
            log:printError("Error reading payload", 'error = xmlPayload);
        }

        string|error stringPayload = payloadAccessAfterRespondBackendClient->post("/backend/getString", "want string");
        if stringPayload is error {
            log:printError("Error reading payload", 'error = stringPayload);
        }
        byte[]|error binaryPayload = payloadAccessAfterRespondBackendClient->post("/backend/getByteArray",
            "BinaryPayload is textVal".toBytes());
        if binaryPayload is error {
            log:printError("Error reading payload", 'error = binaryPayload);
        }

        return "Request Processed successfully";
    }
}

service /backend on payloadAccessAfterRespondListener {
    resource function 'default getJson(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        check caller->respond(response);
        json|error result = req.getJsonPayload();
        if result is error {
            lock {
                requestJsonPayloadError = result;
            }
        }
        return;
    }

    resource function 'default getXml(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        check caller->respond(response);
        xml|error result = req.getXmlPayload();
        if result is error {
            lock {
                requestXmlPayloadError = result;
            }
        }
        return;
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        check caller->respond(response);
        string|error result = req.getTextPayload();
        if result is error {
            error err = result;
            lock {
                requestTextPayloadError = err;
            }
        }
        return;
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        check caller->respond(response);
        byte[]|error result = req.getBinaryPayload();
        if result is error {
            error err = result;
            lock {
                requestBinaryPayloadError = err;
            }
        }
        return;
    }
}

@test:Config {
    groups: ["payloadAccessAfterRespond"]
}
function testPayloadAccessAfterRespondTest() returns error? {
    http:Response|error response = payloadAccessAfterRespondTestClient->get("/passthrough");
    string errorMessage = "Entity body content is already released";
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Request Processed successfully");
        runtime:sleep(5);
        lock {
            assertErrorMessage(requestJsonPayloadError, "Error occurred while retrieving the json payload from the request");
        }
        lock {
            assertErrorCauseMessage(requestJsonPayloadError, errorMessage);
        }
        lock {
            assertErrorMessage(requestXmlPayloadError, "Error occurred while retrieving the xml payload from the request");
        }
        lock {
            assertErrorCauseMessage(requestXmlPayloadError, errorMessage);
        }
        lock {
            assertErrorMessage(requestTextPayloadError, "Error occurred while retrieving the text payload from the request");
        }
        lock {
            assertErrorCauseMessage(requestTextPayloadError, errorMessage);
        }
        lock {
            assertErrorMessage(requestBinaryPayloadError, "Error occurred while retrieving the binary payload from the request");
        }
        lock {
            assertErrorCauseMessage(requestBinaryPayloadError, errorMessage);
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}
