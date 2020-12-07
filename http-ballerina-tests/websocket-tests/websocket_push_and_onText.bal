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

string data = "";
string expectedMsg = "{\"name\":\"Riyafa\", \"age\":23}";
type WebSocketPerson record {|
    string name;
    int age;
|};
service onTextString on new http:Listener(21003) {

    resource function onText(http:WebSocketCaller caller, string data, boolean finalFrame) {
        checkpanic caller->pushText(data);
    }
}

service onTextJSON on new http:Listener(21023) {

    resource function onText(http:WebSocketCaller caller, json data) {
        checkpanic caller->pushText(data);
    }
}

service onTextXML on new http:Listener(21024) {

    resource function onText(http:WebSocketCaller caller, xml data) {
        checkpanic caller->pushText(data);
    }
}

service onTextRecord on new http:Listener(21025) {

    resource function onText(http:WebSocketCaller caller, WebSocketPerson data) {
        var personData = data.cloneWithType(json);
        if (personData is error) {
            panic personData;
        } else {
            var returnVal = caller->pushText(personData);
            if (returnVal is http:WebSocketError) {
                panic <error>returnVal;
            }
        }
    }
}

service onTextByteArray on new http:Listener(21026) {

    resource function onText(http:WebSocketCaller caller, byte[] data) {
        var returnVal = caller->pushText(data);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service clientPushCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient wsEp, string text) {
        data = <@untainted>text;
    }
};

// Tests string support for pushText and onText
// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/306
@test:Config {enable:false}
public function testString() {
    http:WebSocketClient wsClient = new ("ws://localhost:21003/onTextString", {callbackService: clientPushCallbackService});
    checkpanic wsClient->pushText("Hi");
    runtime:sleep(500);
    test:assertEquals(data, "Hi", msg = "Failed pushtext");
    checkpanic wsClient->close(statusCode = 1000, reason = "Close the connection");
}

// Tests JSON support for pushText and onText
@test:Config {}
public function testJson() {
    http:WebSocketClient wsClient = new ("ws://localhost:21023/onTextJSON",
        {callbackService: clientPushCallbackService});
    checkpanic wsClient->pushText("{\"name\":\"Riyafa\", \"age\":23}");
    runtime:sleep(500);
    test:assertEquals(data, expectedMsg, msg = "Failed pushtext");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests XML support for pushText and onText
@test:Config {}
public function testXml() {
    http:WebSocketClient wsClient = new ("ws://localhost:21024/onTextXML", {callbackService: clientPushCallbackService});
    string msg = "<note><to>Tove</to></note>";
    var output = wsClient->pushText(msg);
    runtime:sleep(500);
    test:assertEquals(data, msg, msg = "");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests Record support for pushText and onText
@test:Config {}
public function testRecord() {
    http:WebSocketClient wsClient = new ("ws://localhost:21025/onTextRecord",
        {callbackService: clientPushCallbackService});
    var output = wsClient->pushText("{\"name\":\"Riyafa\", \"age\":23}");
    runtime:sleep(500);
    test:assertEquals(data, expectedMsg, msg = "");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests byte array support for pushText and onText
@test:Config {}
public function testByteArray() {
    http:WebSocketClient wsClient = new ("ws://localhost:21026/onTextByteArray",
        {callbackService: clientPushCallbackService});
    string msg = "Hello";
    var output = wsClient->pushText(msg);
    runtime:sleep(500);
    test:assertEquals(data, msg, msg = "");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
