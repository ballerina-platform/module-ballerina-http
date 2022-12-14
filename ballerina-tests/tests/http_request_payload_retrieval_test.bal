// Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/test;


service /payloadRetrieval on new http:Listener(requestPayloadRetrievalTestPort) {
    resource function post . (http:Request req) returns int|error {
        byte[] binaryPayload = check req.getBinaryPayload();
        return binaryPayload.length();
    }
}

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testStringToBinaryPayloadRetrieval() returns error? {
    http:Request req = new;
    string payload = "This is a sample message";
    req.setTextPayload(payload);
    byte[] binaryPayload = check req.getBinaryPayload();
    test:assertEquals(payload.toBytes().length(), binaryPayload.length());
}

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testXmlToBinaryPayloadRetrieval() returns error? {
    http:Request req = new;
    xml payload = xml `<StorageServiceProperties><HourMetrics><Version>1.0</Version><Enabled>false</Enabled><RetentionPolicy><Enabled>false</Enabled></RetentionPolicy></HourMetrics></StorageServiceProperties>`;
    req.setXmlPayload(payload);
    byte[] binaryPayload = check req.getBinaryPayload();
    test:assertEquals(payload.toString().toBytes().length(), binaryPayload.length());
}

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testJsonToBinaryPayloadRetrieval() returns error? {
    http:Request req = new;
    json payload = {
        "message": "This is a sample message"
    };
    req.setJsonPayload(payload);
    byte[] binaryPayload = check req.getBinaryPayload();
    test:assertEquals(payload.toString().toBytes().length(), binaryPayload.length());
}

final http:Client payloadRetrievalClient = check new(string `http://localhost:${requestPayloadRetrievalTestPort.toString()}/payloadRetrieval`);

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testStringToBinaryPayloadRetrievalWithService() returns error? {
    http:Request req = new;
    string payload = "This is a sample message";
    req.setTextPayload(payload);
    int payloadLength = check payloadRetrievalClient->post("/", req);
    test:assertEquals(payload.toBytes().length(), payloadLength);
}

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testXmlToBinaryPayloadRetrievalWithService() returns error? {
    http:Request req = new;
    xml payload = xml `<StorageServiceProperties><HourMetrics><Version>1.0</Version><Enabled>false</Enabled><RetentionPolicy><Enabled>false</Enabled></RetentionPolicy></HourMetrics></StorageServiceProperties>`;
    req.setXmlPayload(payload);
    int payloadLength = check payloadRetrievalClient->post("/", req);
    test:assertEquals(payload.toString().toBytes().length(), payloadLength);
}

@test:Config {
    groups: ["binaryPayloadRetrieval"]
}
function testJsonToBinaryPayloadRetrievalWithService() returns error? {
    http:Request req = new;
    json payload = {
        "message": "This is a sample message"
    };
    req.setJsonPayload(payload);
    int payloadLength = check payloadRetrievalClient->post("/", req);
    test:assertEquals(payload.toString().toBytes().length(), payloadLength);
}
