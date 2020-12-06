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
import ballerina/log;
import ballerina/test;

http:ListenerConfiguration helloWorldEPConfig = {
    secureSocket: {
        keyStore: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    },
    httpVersion: "2.0"
};

listener http:Listener sslServerEp = new (9114, config = helloWorldEPConfig);

@http:ServiceConfig {
    basePath: "/hello"
}

service sslServer on sslServerEp {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        var result = caller->respond("Hello World!");
        if (result is error) {
            log:printError("Failed to respond", result);
        }
    }
}

http:ClientConfiguration sslDisabledConfig = {
    secureSocket: {
        disable: true
    },
    httpVersion: "2.0"
};

@test:Config {}
public function disableSslTest() {
    http:Client clientEP = new("https://localhost:9114", sslDisabledConfig);
    var resp = clientEP->get("/hello/");
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "Hello World!");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
