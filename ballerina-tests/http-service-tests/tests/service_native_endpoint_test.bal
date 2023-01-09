// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http_test_common as common;

listener http:Listener serviceEndpointTestPortEP = new (serviceEndpointTestPort, httpVersion = http:HTTP_1_1);
final http:Client serviceEndpointClient = check new ("http://localhost:" + serviceEndpointTestPort.toString(), httpVersion = http:HTTP_1_1);

service /serviceEndpointHello on serviceEndpointTestPortEP {

    resource function get protocol(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json connectionJson = {protocol: caller.protocol};
        res.statusCode = 200;
        res.setJsonPayload(connectionJson);
        check caller->respond(res);
    }

    resource function get local(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json connectionJson = {
            local: {
                host: caller.localAddress.host,
                port: caller.localAddress.port,
                address: caller.localAddress.ip
            }
        };
        res.statusCode = 200;
        res.setJsonPayload(connectionJson);
        check caller->respond(res);
    }

    resource function get host(http:Caller caller) returns error? {
        string remoteHostName = caller.getRemoteHostName() ?: "nohost";
        check caller->respond(remoteHostName);
    }
}

//Test the protocol value of ServiceEndpoint struct within a service
@test:Config {}
function testGetProtocolConnectionStruct() {
    http:Response|error response = serviceEndpointClient->get("/serviceEndpointHello/protocol");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertJsonValue(response.getJsonPayload(), "protocol", "http");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test the local struct values of the ServiceEndpoint struct within a service
@test:Config {}
function testLocalStructInConnection() {
    http:Response|error response = serviceEndpointClient->get("/serviceEndpointHello/local");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        var payload = response.getJsonPayload();
        if payload is map<json> {
            map<json> localContent = <map<json>>payload["local"];
            test:assertEquals(localContent["port"], serviceEndpointTestPort, msg = "Found unexpected output");
            test:assertEquals(localContent["address"], "127.0.0.1", msg = "Found unexpected output");
        } else if payload is error {
            test:assertFail(msg = "Found unexpected output type: " + payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetHostName() {
    var response = serviceEndpointClient->get("/serviceEndpointHello/host", targetType = string);
    if (response is string) {
        test:assertTrue(response.length() != 0, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
