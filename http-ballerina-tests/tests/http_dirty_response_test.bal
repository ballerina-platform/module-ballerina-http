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

import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener dirtyResponseListener = new(dirtyResponseTestPort);
http:Client dirtyResponseTestClient = new("http://localhost:" + dirtyResponseTestPort.toString());

http:Response dirtyResponse = getSingletonResponse();
string dirtyErrorLog = "";

@http:ServiceConfig {
    basePath: "hello"
}
service sameResponse on dirtyResponseListener {
    @http:ResourceConfig {
        path: "/"
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        var responseError = caller->respond(dirtyResponse);
        if (responseError is error) {
            dirtyErrorLog = responseError.message();
            io:println(dirtyErrorLog);
        }
    }
}

function getSingletonResponse() returns http:Response {
    http:Response res = new;
    return res;
}

@test:Config {}
function testDirtyResponse() {
    var response = dirtyResponseTestClient->get("/hello");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = dirtyResponseTestClient->get("/hello");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "couldn't complete the respond operation as the response has" +
                        " been already used.");
        test:assertEquals(dirtyErrorLog, "Couldn't complete the respond operation as the response has" +
                        " been already used.");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
