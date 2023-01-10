// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.'string;
import ballerina/http_test_common as common;

service /mimeTest on generalHTTP2Listener {

    // TODO: Enable after the I/O revamp
    // resource function post largepayload(http:Caller caller, http:Request request) {
    //     http:Response response = new;
    //     mime:Entity responseEntity = new;

    //     var result = request.getByteChannel();
    //     if result is io:ReadableByteChannel {
    //         responseEntity.setByteChannel(result);
    //     } else {
    //         io:print("Error in getting byte channel");
    //     }

    //     response.setEntity(responseEntity);
    //     check caller->respond(response);
    // }

    resource function post largepayload(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        mime:Entity responseEntity = new;
        var result = request.getByteStream();
        if result is stream<byte[], io:Error?> {
            responseEntity.setByteStream(result);
        } else {
            io:print("Error in getting byte stream");
        }
        response.setEntity(responseEntity);
        check caller->respond(response);
    }

    resource function 'default getPayloadFromEntity(http:Request request) returns
            http:InternalServerError|http:Response|error {
        http:Response res = new;
        var entity = request.getEntity();
        if entity is mime:Entity {
            json|error jsonPayload = entity.getJson();
            if jsonPayload is json {
                mime:Entity ent = new;
                ent.setJson({"payload": jsonPayload, "header": check entity.getHeader("Content-type")});
                res.setEntity(ent);
                return res;
            } else {
                return {body: "Error while retrieving from entity"};
            }
        } else {
            return {body: "Error while retrieving from request"};
        }
    }
}

final http:Client http2MimeClient = check new ("http://localhost:" + http2GeneralPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

// Access entity to read payload and send back
@test:Config {}
function testHttp2AccessingPayloadFromEntity() returns error? {
    string key = "lang";
    string value = "ballerina";
    string path = "/mimeTest/getPayloadFromEntity";
    string jsonString = "{\"" + key + "\":\"" + value + "\"}";
    http:Request req = new;
    req.setTextPayload(jsonString);
    http:Response response = check http2MimeClient->post(path, req);
    common:assertJsonPayload(response.getJsonPayload(), {"payload": {"lang": "ballerina"}, "header": "text/plain"});
}

@test:Config {}
function testHttp2StreamResponseSerialize() returns error? {
    string key = "lang";
    string value = "ballerina";
    string path = "/mimeTest/largepayload";
    json jsonString = {[key] : value};
    http:Request req = new;
    req.setJsonPayload(jsonString);
    byte[] response = check http2MimeClient->post(path, req);
    string payload = check 'string:fromBytes(response);
    test:assertEquals(payload, jsonString.toString());
}
