// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// import ballerina/log;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener http2SslListener = new (9206, http2SslServiceConf);

service /http2Service on http2SslListener {

    resource function get .(http:Caller caller, http:Request req) {
        error? result = caller->respond("Hello World!");
        if result is error {
            // log:printError("Failed to respond", 'error = result);
        }
    }
}

http:ClientConfiguration http2SslClientConf1 = {
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        },
        sniHostName: "localhost2"
    }
};

@test:Config {}
public function testHttp2Ssl1() returns error? {
    http:Client clientEP = check new ("https://localhost:9206", http2SslClientConf1);
    http:Response|error resp = clientEP->get("/http2Service/");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Hello World!");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
