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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/test;
import ballerina/http;
import ballerina/lang.runtime;
import ballerina/http_test_common as common;

int http2DirtyResponseTestPort = common:getHttp2Port(dirtyResponseTestPort);

listener http:Listener http2DirtyResponseListener = new (http2DirtyResponseTestPort);
final http:Client http2DirtyResponseTestClient = check new ("http://localhost:" + http2DirtyResponseTestPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

http:Response http2DirtyResponse = getSingletonResponse();
isolated string http2DirtyErrorLog = "";

service /hello on http2DirtyResponseListener {

    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseError = ();
        lock {
            responseError = caller->respond(http2DirtyResponse);
        }
        if responseError is error {
            lock {
                http2DirtyErrorLog = responseError.message();
                io:println(http2DirtyErrorLog);
            }
        }
    }
}

@test:Config {}
function tesHttp2tDirtyResponse() returns error? {
    http:Response|error response = http2DirtyResponseTestClient->get("/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = http2DirtyResponseTestClient->get("/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Couldn't complete the respond operation as the response has" +
                        " been already used.");
        runtime:sleep(5);
        lock {
            test:assertEquals(http2DirtyErrorLog, "Couldn't complete the respond operation as the response has" +
                        " been already used.");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
