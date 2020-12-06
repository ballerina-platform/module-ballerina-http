// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener acceptEncodingListenerEP = new(acceptEncodingHeaderTestPort, {server: "Mysql"});

http:Client acceptEncodingAutoEP = new("http://localhost:" + acceptEncodingHeaderTestPort.toString() + "/hello", {
    compression:http:COMPRESSION_AUTO
});

http:Client acceptEncodingEnableEP = new("http://localhost:" + acceptEncodingHeaderTestPort.toString() + "/hello", {
    compression:http:COMPRESSION_ALWAYS
});

http:Client acceptEncodingDisableEP = new("http://localhost:" + acceptEncodingHeaderTestPort.toString() + "/hello", {
    compression:http:COMPRESSION_NEVER
});

@http:ServiceConfig {basePath:"/hello"}
service acceptEncodingBackend on acceptEncodingListenerEP {

    # The helloResource only accepts requests made using the specified HTTP methods
    @http:ResourceConfig {
        methods:["POST", "PUT", "GET"],
        path:"/"
    }
    resource function helloResource(http:Caller caller, http:Request req) {
        http:Response res = new;
        json payload = {};
        boolean hasHeader = req.hasHeader(ACCEPT_ENCODING);
        if (hasHeader) {
            payload = {acceptEncoding:req.getHeader(ACCEPT_ENCODING)};
        } else {
            payload = {acceptEncoding:"Accept-Encoding header not present."};
        }
        res.setJsonPayload(<@untainted> payload);
        checkpanic caller->respond(res);
    }
}

//Tests the behaviour when Accept Encoding option is enable.
@test:Config {}
function testAcceptEncodingEnabled() {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    var response = acceptEncodingEnableEP->post("/", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonValue(response.getJsonPayload(), "acceptEncoding", "deflate, gzip");
        assertHeaderValue(response.server, "Mysql");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when Accept Encoding option is disable.
@test:Config {}
function testAcceptEncodingDisabled() {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    var response = acceptEncodingDisableEP->post("/", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonValue(response.getJsonPayload(), "acceptEncoding", "Accept-Encoding header not present.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when Accept Encoding option is auto.
@test:Config {}
function testAcceptEncodingAuto() {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    var response = acceptEncodingAutoEP->post("/", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonValue(response.getJsonPayload(), "acceptEncoding", "Accept-Encoding header not present.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
