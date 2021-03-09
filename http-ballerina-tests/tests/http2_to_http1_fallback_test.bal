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

listener http:Listener serviceEndpointWithoutSSL = new(9101, { httpVersion: "2.0" });

listener http:Listener serviceEndpointWithSSL = new(9105, {
    httpVersion: "2.0",
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
});

service /helloWorldWithoutSSL on serviceEndpointWithoutSSL {

    resource function get .(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Version: " + <@untainted> req.httpVersion);
    }
}

service /helloWorldWithSSL on serviceEndpointWithSSL {

    resource function get .(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Version: " + <@untainted> req.httpVersion);
    }
}

@test:Config {}
public function testFallback() {
    http:Client clientEP = checkpanic new("http://localhost:9101");
    var resp = clientEP->get("/helloWorldWithoutSSL");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Version: 1.1");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFallbackWithSSL() {
    http:Client clientEP = checkpanic new("https://localhost:9105", {
        secureSocket: {
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            }
        }
    });
    var resp = clientEP->get("/helloWorldWithSSL");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Version: 1.1");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
