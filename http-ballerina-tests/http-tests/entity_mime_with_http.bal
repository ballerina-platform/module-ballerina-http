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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

listener http:Listener mimeEP = new(mimeTest);

@http:ServiceConfig {basePath:"/test"}
service mimeService on mimeEP {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/largepayload"
    }
    resource function getPayloadFromFileChannel(http:Caller caller, http:Request request) {
        http:Response response = new;
        mime:Entity responseEntity = new;

        var result = request.getByteChannel();
        if (result is io:ReadableByteChannel) {
            responseEntity.setByteChannel(result);
        } else {
            io:print("Error in getting byte channel");
        }

        response.setEntity(responseEntity);
        checkpanic caller->respond(response);
    }

    resource function getPayloadFromEntity(http:Caller caller, http:Request request) {
        http:Response res = new;
        var entity = request.getEntity();
        if (entity is mime:Entity) {
            json|error jsonPayload = entity.getJson();
            if (jsonPayload is json) {
                mime:Entity ent = new;
                ent.setJson(<@untainted>{"payload" : jsonPayload, "header" : entity.getHeader("Content-type")});
                res.setEntity(ent);
                checkpanic caller->ok(res);
            } else {
                checkpanic caller->internalServerError("Error while retrieving from entity");
            }
        } else {
            checkpanic caller->internalServerError({ message: "Error while retrieving from request" });
        }
    }
}

@test:Config {}
function testHeaderWithRequest() {
    mime:Entity entity = new;
    entity.setHeader("123Authorization", "123Basicxxxxxx");

    http:Request request = new;
    request.setEntity(entity);
    test:assertEquals(request.getHeader("123Authorization"), "123Basicxxxxxx", msg = "Output mismatched");
}

@test:Config {}
function testPayloadInEntityOfRequest() {
    mime:Entity entity = new;
    entity.setJson({"payload": "PayloadInEntityOfRequest"});

    http:Request request = new;
    request.setEntity(entity);
    var payload = request.getJsonPayload();
    if payload is json {
        test:assertEquals(payload, {"payload": "PayloadInEntityOfRequest"}, msg = "Output mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testPayloadInRequest() {
    http:Request request = new;
    request.setJsonPayload({"payload": "PayloadInTheRequest"});

    var entity = request.getEntity();
    if (entity is mime:Entity) {
        var payload = entity.getJson();
        if payload is json {
            test:assertEquals(payload, {"payload": "PayloadInTheRequest"}, msg = "Output mismatched");
        } else {
             test:assertFail("Test failed");
        }
    } else {
         test:assertFail("Test failed");
    }
}

@test:Config {}
function testHeaderWithResponse() {
    mime:Entity entity = new;
    entity.setHeader("123Authorization", "123Basicxxxxxx");

    http:Response response = new;
    response.setEntity(entity);
    test:assertEquals(response.getHeader("123Authorization"),  "123Basicxxxxxx", msg = "Output mismatched");
}

@test:Config {}
function testPayloadInEntityOfResponse() {
    mime:Entity entity = new;
    entity.setJson({"payload": "PayloadInEntityOfResponse"});

    http:Response response = new;
    response.setEntity(entity);
    var payload = response.getJsonPayload();
    if payload is json {
        test:assertEquals(payload, {"payload": "PayloadInEntityOfResponse"}, msg = "Output mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testPayloadInResponse() {
    http:Response response = new;
    response.setJsonPayload({"payload": "PayloadInTheResponse"});

    var entity = response.getEntity();
    if (entity is mime:Entity) {
        var payload = entity.getJson();
        if payload is json {
            test:assertEquals(payload, {"payload": "PayloadInTheResponse"}, msg = "Output mismatched");
        } else {
            test:assertFail("Test failed");
        }
    } else {
        test:assertFail("Test failed");
    }
}

http:Client mimeClient = new("http://localhost:" + mimeTest.toString());

// Access entity to read payload and send back
@test:Config {}
function testAccessingPayloadFromEntity() {
    string key = "lang";
    string value = "ballerina";
    string path = "/test/getPayloadFromEntity";
    string jsonString = "{\"" + key + "\":\"" + value + "\"}";
    http:Request req = new;
    req.setTextPayload(jsonString);
    var response = mimeClient->post(path, req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {"payload":{"lang":"ballerina"}, "header":"text/plain"});
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
