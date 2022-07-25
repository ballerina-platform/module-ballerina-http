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

import ballerina/http;
// import ballerina/log;
import ballerina/test;

http:ListenerConfiguration helloWorldEPConfig = {
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

listener http:Listener sslServerEp = new(9114, config = helloWorldEPConfig);

service /hello on sslServerEp {
    resource function get .(http:Caller caller, http:Request req) {
        error? result = caller->respond("Hello World!");
        if result is error {
            // log:printError("Failed to respond", 'error = result);
        }
    }
}

http:ClientConfiguration sslDisabledConfig = {
    secureSocket: {
        enable: false
    }
};

@test:Config {}
public function disableSslTest() returns error? {
    http:Client clientEP = check new("https://localhost:9114", sslDisabledConfig);
    http:Response|error resp = clientEP->get("/hello/");
    if resp is http:Response {
        assertTextPayload(resp.getTextPayload(), "Hello World!");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
