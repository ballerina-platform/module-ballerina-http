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

import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/test;

http:Client h2Client = check new("http://localhost:9127", {
    httpVersion: "2.0",
    http2Settings: {
        http2PriorKnowledge: true
    },
    timeout: 300
});

service /helloWorld on new http:Listener(9127, {httpVersion: "2.0"}) {

    resource function post abnormalResource(http:Caller caller, http:Request request) {
        error? result = caller->continue();
        handleRespError(result);
        http:Response res = new;
        var payload = request.getTextPayload();
        if (payload is string) {
            res.statusCode = 200;
            res.setPayload(<@untainted string>payload);
            var result1 = caller->respond(res);
            handleRespError(result1);
        } else {
            res.statusCode = 500;
            res.setPayload(<@untainted> payload.message());
            var result1 = caller->respond(res);
            handleRespError(result1);
        }
    }
}

service /continueService on new http:Listener(9128, {httpVersion: "2.0"}) {

    resource function get initial(http:Caller caller, http:Request req) {
        io:println("test100ContinueResource");
        http:Response|error response = h2Client->post("/helloWorld/abnormalResource", "100 continue response should be ignored by this client");
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted>response);
        } else {
            checkpanic caller->respond("Error sending client request");
        }
    }
}

function handleRespError(error? result) {
    if (result is error) {
        log:printError(result.message(), 'error = result);
    }
}

@test:Config {}
public function testUnexpected100ContinueResponse() {
    http:Client clientEP = checkpanic new("http://localhost:9128");
    http:Response|error resp = clientEP->get("/continueService/initial");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "100 continue response should be ignored by this client");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
