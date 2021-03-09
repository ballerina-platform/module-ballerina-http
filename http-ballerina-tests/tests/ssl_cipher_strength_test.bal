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

import ballerina/http;
import ballerina/test;

http:ListenerConfiguration strongCipherConfig = {
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        mutualSsl: {
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            }
        }
        // Service will start with the strong cipher suites. No need to specify.
    }
};

listener http:Listener strongCipher = new(9226, strongCipherConfig);

service /strongService on strongCipher {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }
}

http:ListenerConfiguration weakCipherConfig = {
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        mutualSsl: {
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            }
        },
        ciphers: ["TLS_RSA_WITH_AES_128_CBC_SHA"]
    }
};

listener http:Listener weakCipher = new(9227, weakCipherConfig);

service /weakService on weakCipher {
    
    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }
}

// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/305
@test:Config {enable:false}
public function testWithStrongClientWithWeakService() {
    http:Client clientEP = checkpanic new("https://localhost:9227", {
        secureSocket: {
            key: {
                path: "tests/certsandkeys/ballerinaKeystore.p12",
                password: "ballerina"
            },
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            },
            ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
        }
    });
    http:Request req = new;
    var resp = clientEP->get("/weakService/");
    if (resp is http:Response) {
        test:assertFail(msg = "Found unexpected output: Expected an error" );
    } else {
        test:assertEquals(resp.message(), "SSL connection failed:Received fatal alert: handshake_failure localhost/127.0.0.1:9227");
    }
}

@test:Config {}
public function testWithStrongClientWithStrongService() {
    http:Client clientEP = checkpanic new("https://localhost:9226", {
        secureSocket: {
            key: {
                path: "tests/certsandkeys/ballerinaKeystore.p12",
                password: "ballerina"
            },
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            },
            ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
        }
    });
    http:Request req = new;
    var resp = clientEP->get("/strongService/");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "hello world", msg = "Found unexpected output");
        } else {
            test:assertFail(msg = "Found unexpected output: " + payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
