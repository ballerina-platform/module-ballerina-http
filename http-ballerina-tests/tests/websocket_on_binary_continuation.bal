// Copyright (c) 2020 WSO2 Inc. (//www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/runtime;
import ballerina/test;
import ballerina/io;
import ballerina/http;

byte[] content = [];
byte[] binaryContent = [];
@http:WebSocketServiceConfig {
    path: "/onBinaryContinuation"
}
service onBinaryContinuation on new http:Listener(21007) {
    resource function onBinary(http:WebSocketCaller caller, byte[] data, boolean finalFrame) {
        if (finalFrame) {
            appendToArray(<@untainted> data, content);
            var returnVal = caller->pushBinary(content);
            if (returnVal is http:WebSocketError) {
                panic <error> returnVal;
            }
        } else {
            appendToArray(<@untainted> data, content);
        }
    }
}

function appendToArray(byte[] src, byte[] dest) {
    int i = 0;
    int l = src.length();
    while (i < l) {
        dest[dest.length()] = src[i];
        i = i + 1;
    }
}

service continuationService = @http:WebSocketServiceConfig {} service {

    resource function onBinary(http:WebSocketClient caller, byte[] data, boolean finalFrame) {
        binaryContent = <@untainted>data;
    }
};

// Tests binary continuation frame
@test:Config {}
public function testBinaryContinuation() {
    string msg = "<note><to>Tove</to></note>";
    string[] values = ["<note>", "<to>", "Tove", "</to>"];
    http:WebSocketClient wsClient = new ("ws://localhost:21007/onBinaryContinuation",
        {callbackService: continuationService});
    foreach string value in values {
        checkpanic wsClient->pushBinary(value.toBytes(), false);
    }
    checkpanic wsClient->pushBinary("</note>".toBytes(), true);
    runtime:sleep(500);
    string|error value = 'string:fromBytes(binaryContent);
    test:assertEquals(value.toString(), msg, msg = "Data mismatched");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
