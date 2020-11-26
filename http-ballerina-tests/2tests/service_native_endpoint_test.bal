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

listener http:Listener serviceEndpointTestEP = new(serviceEndpointTest);
http:Client serviceEndpointClient = new("http://localhost:" + serviceEndpointTest.toString());

service serviceEndpointHello on serviceEndpointTestEP {

    @http:ResourceConfig {
        path:"/protocol",
        methods:["GET"]
    }
    resource function protocol(http:Caller caller, http:Request req) {
        http:Response res = new;
        json connectionJson = {protocol:caller.protocol};
        res.statusCode = 200;
        res.setJsonPayload(<@untainted json> connectionJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/local",
        methods:["GET"]
    }
    resource function local(http:Caller caller, http:Request req) {
        http:Response res = new;
        json connectionJson = {local:{host:caller.localAddress.host, port:caller.localAddress.port}};
        res.statusCode = 200;
        res.setJsonPayload(<@untainted json> connectionJson);
        checkpanic caller->respond(res);
    }
}

//Test the protocol value of ServiceEndpoint struct within a service
@test:Config {}
function testGetProtocolConnectionStruct() {
    var response = serviceEndpointClient->get("/serviceEndpointHello/protocol");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonValue(response.getJsonPayload(), "protocol", "http");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test the local struct values of the ServiceEndpoint struct within a service
@test:Config {}
function testLocalStructInConnection() {
    var response = serviceEndpointClient->get("/serviceEndpointHello/local");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        var payload = response.getJsonPayload();
        if payload is map<json> {
            map<json> localContent = <map<json>>payload["local"];
            test:assertEquals(localContent["port"], serviceEndpointTest, msg = "Found unexpected output");
        } else if payload is error {
            test:assertFail(msg = "Found unexpected output type: " + payload.message());
        }
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
