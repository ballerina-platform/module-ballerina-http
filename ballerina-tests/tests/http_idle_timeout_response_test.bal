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

// import ballerina/log;
import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;


listener http:Listener idleTimeoutListenerEP = new(idleTimeoutTestPort, httpVersion = http:HTTP_1_1, timeout = 1, server = "Mysql");
final http:Client idleTimeoutClient = check new("http://localhost:" + idleTimeoutTestPort.toString(), httpVersion = http:HTTP_1_1);

service /idleTimeout on idleTimeoutListenerEP {

    resource function post timeout408(http:Caller caller, http:Request req) {
        var result = req.getTextPayload();
        if result is string {
            // log:printInfo(result);
        } else  {
            // log:printError("Error reading request", 'error = result);
        }
        var responseError = caller->respond("some");
        if responseError is error {
            // log:printError("Error sending response", 'error = responseError);
        }
    }

    resource function get timeout500(http:Caller caller, http:Request req) {
        runtime:sleep(3);
        var responseError = caller->respond("some");
        if responseError is error {
            // log:printError("Error sending response", 'error = responseError);
        }
    }
}

//Test header server name if 408 response is returned when the server times out. In this case a sleep is introduced in the server.
@test:Config {}
function test408Response() {
    http:Response|error response = idleTimeoutClient->get("/idleTimeout/timeout500");
    if response is http:Response {
        test:assertEquals(response.statusCode, 408, msg = "Found unexpected output");
        test:assertEquals(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
