// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// under the License.package http2;

import ballerina/http;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener serviceEndpointWithSSL = new (9105, {
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

service /helloWorldWithoutSSL on generalHTTP2Listener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Version: " + req.httpVersion);
    }
}

service /helloWorldWithSSL on serviceEndpointWithSSL {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Version: " + req.httpVersion);
    }
}

@test:Config {}
public function testFallback() returns error? {
    http:Client clientEP = check new ("http://localhost:9100", httpVersion = http:HTTP_1_1);
    http:Response|error resp = clientEP->get("/helloWorldWithoutSSL");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Version: 1.1");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testFallbackWithSSL() returns error? {
    http:Client clientEP = check new ("https://localhost:9105",
        httpVersion = http:HTTP_1_1,
        secureSocket = {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    http:Response|error resp = clientEP->get("/helloWorldWithSSL");
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "Version: 1.1");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
