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
import ballerina/lang.'string as strings;
import ballerina/test;

http:ListenerConfiguration sslProtocolServiceConfig = {
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
         },
         protocol: {
             name: http:TLS,
             versions: ["TLSv1.1"]
         }
    }
};

listener http:Listener sslProtocolListener = new(9249, config = sslProtocolServiceConfig);

service /protocol on sslProtocolListener {
    
    resource function get protocolResource(http:Caller caller, http:Request req) {
        var result = caller->respond("Hello World!");
        if (result is error) {
           log:printError("Failed to respond", err = result);
        }
    }
}

http:ClientConfiguration sslProtocolClientConfig = {
    secureSocket: {
        cert: {
            path: "tests/certsandkeys/ballerinaTruststore.p12",
            password: "ballerina"
        },
        protocol: {
            name: http:TLS,
            versions: ["TLSv1.2"]
        }
    }
};

@test:Config {}
public function testSslProtocol() {
    http:Client clientEP = checkpanic new("https://localhost:9249", sslProtocolClientConfig);
    http:Request req = new;
    var resp = clientEP->get("/protocol/protocolResource");
    if (resp is http:Response) {
        test:assertFail(msg = "Found unexpected output: Expected an error" );
    } else {
        test:assertTrue(strings:includes(resp.message(), "SSL connection failed"));
    }
}
