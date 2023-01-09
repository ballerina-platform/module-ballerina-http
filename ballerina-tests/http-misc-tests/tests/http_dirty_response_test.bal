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
import ballerina/lang.runtime;
import ballerina/http_test_common as common;

listener http:Listener dirtyResponseListener = new (dirtyResponseTestPort, httpVersion = http:HTTP_1_1);
final http:Client dirtyResponseTestClient = check new ("http://localhost:" + dirtyResponseTestPort.toString(), httpVersion = http:HTTP_1_1);

http:Response dirtyResponse = getSingletonResponse();
isolated string dirtyErrorLog = "";

service /hello on dirtyResponseListener {

    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseError = ();
        lock {
            responseError = caller->respond(dirtyResponse);
        }
        if responseError is error {
            lock {
                dirtyErrorLog = responseError.message();
                io:println(dirtyErrorLog);
            }
        }
    }
}

function getSingletonResponse() returns http:Response {
    http:Response res = new;
    return res;
}

@test:Config {}
function testDirtyResponse() returns error? {
    http:Response|error response = dirtyResponseTestClient->get("/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = dirtyResponseTestClient->get("/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Couldn't complete the respond operation as the response has" +
                        " been already used.");
        runtime:sleep(5);
        lock {
            test:assertEquals(dirtyErrorLog, "Couldn't complete the respond operation as the response has" +
                        " been already used.");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
