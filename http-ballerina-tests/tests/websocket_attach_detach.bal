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

import ballerina/runtime;
import ballerina/test;
import ballerina/http;
import ballerina/io;

string msg = "message";

listener http:Listener attachDetachEp = new (21032);
@http:WebSocketServiceConfig {
    path: "/attach/detach"
}
service attachDetach on attachDetachEp {
    resource function onText(http:WebSocketCaller caller, string data, boolean finalFrame) returns error? {
        if (data == "attach") {
            var err = attachDetachEp.__attach(wsNoPath);
            handleError(err, caller);
            err = attachDetachEp.__attach(wsWithPath);
        } else if (data == "detach") {
            var err = attachDetachEp.__detach(wsNoPath);
            handleError(err, caller);
            err = attachDetachEp.__detach(wsWithPath);
        } else if (data == "client_attach") {
            var err = attachDetachEp.__attach(wsClientService);
            handleError(err, caller);
        }
    }
}

service wsWithPath = @http:WebSocketServiceConfig {path: "/hello"} service {
    resource function onText(http:WebSocketCaller conn, string text, boolean finalFrame) returns error? {
        check conn->pushText(text);
    }
};

service wsNoPath = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketCaller conn, string text, boolean finalFrame) returns error? {
        check conn->pushText(text);
    }
};

service wsClientService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient conn, string text, boolean finalFrame) returns error? {
        check conn->pushText(text);
    }
};

function handleError(error? err, http:WebSocketCaller caller) {

    if (err is http:WebSocketError) {
        serverOutput = <@untainted>err.message();
    }
}

service attachService = @http:WebSocketServiceConfig {} service {
    resource function onText(http:WebSocketClient caller, string text) {
        expectedData = <@untainted>text;
    }
    resource function onError(http:WebSocketClient caller, error err) {
        expectedErr = <@untainted>err.toString();
    }

};

// Try attaching a WebSocket Client service
@test:Config {}
public function attachClientService() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("client_attach");
    runtime:sleep(500);
    test:assertEquals(serverOutput, "GenericError: Client service cannot be attached to the Listener");
}

// Detach the service first
@test:Config {}
public function detachFirst() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("detach");
    runtime:sleep(500);
    test:assertEquals(serverOutput, "GenericError: Cannot detach service. Service has not been registered");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests echoed text message from the attached servers
@test:Config {}
public function attachSuccess() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("attach");
    runtime:sleep(500);

    // send to the no path service
    http:WebSocketClient attachClient = new ("ws://localhost:21032", {callbackService: attachService});
    checkpanic attachClient->pushText(msg);
    runtime:sleep(500);
    test:assertEquals(expectedData, msg);

    // send to service with path
    msg = "path message";
    http:WebSocketClient pathClient = new ("ws://localhost:21032/hello", {callbackService: attachService});
    checkpanic attachClient->pushText(msg);
    runtime:sleep(500);
    test:assertEquals(expectedData, msg);
    error? result1 = wsClientEp->close(statusCode = 1000, reason = "Close the connection", timeoutInSeconds = 180);
    if (result1 is http:WebSocketError) {
       io:println("Error occurred when closing connection", result1);
    }
    error? result2 = attachClient->close(statusCode = 1000, reason = "Close the connection");
    if (result2 is http:WebSocketError) {
       io:println("Error occurred when closing connection", result2);
    }
    error? result3 = pathClient->close(statusCode = 1000, reason = "Close the connection");
    if (result3 is http:WebSocketError) {
       io:println("Error occurred when closing connection", result3);
    }
}

// Tests detach
@test:Config {}
public function detachSuccess() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("detach");
    runtime:sleep(500);
    test:assertEquals(serverOutput, "GenericError: Cannot detach service. Service has not been registered");
    http:WebSocketClient attachClient = new ("ws://localhost:21032", {callbackService: attachService});
    runtime:sleep(500);
    test:assertEquals(expectedErr, "error(\"InvalidHandshakeError: Invalid handshake response getStatus: 404 Not Found\")");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Attach twice to the service
@test:Config {}
public function attachTwice() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("attach");
    runtime:sleep(500);
    checkpanic wsClientEp->pushText("attach");
    runtime:sleep(500);
    test:assertEquals(serverOutput, "GenericError: Two services have the same addressable URI");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Detach from the service twice
@test:Config {}
public function detachTwice() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21032/attach/detach");
    checkpanic wsClientEp->pushText("detach");
    runtime:sleep(500);
    checkpanic wsClientEp->pushText("detach");
    runtime:sleep(500);
    test:assertEquals(serverOutput, "GenericError: Cannot detach service. Service has not been registered");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
