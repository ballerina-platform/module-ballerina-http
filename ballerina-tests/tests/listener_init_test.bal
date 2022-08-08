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
import ballerina/test;

@test:Config {}
public function testEmptyKeystore() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                path: "",
                password: "ballerina"
            }
        }
    );
    if testListener is http:Listener {
        test:assertFail(msg = "Found unexpected output: Expected an keystore file not found error" );
    } else {
        test:assertEquals(testListener.message(), "KeyStore file location must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyKeystorePassword() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                path: "tests/certsandkeys/ballerinaKeystore.p12",
                password: ""
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an keystore password not found error" );
    } else {
        test:assertEquals(testListener.message(), "KeyStore password must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyCertFile() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                certFile: "",
                keyFile: "tests/certsandkeys/private.key"
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an empty cert file error" );
    } else {
        test:assertEquals(testListener.message(), "Certificate file location must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyKeyFile() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                certFile: "tests/certsandkeys/public.crt",
                keyFile: ""
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an key file error" );
    } else {
        test:assertEquals(testListener.message(), "Private key file location must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyTrusStoreFile() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                certFile: "tests/certsandkeys/public.crt",
                keyFile: "tests/certsandkeys/private.key"
            },
            mutualSsl: {
                verifyClient: http:REQUIRE,
                cert: ""
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an empty cert file error" );
    } else {
        test:assertEquals(testListener.message(), "Certificate file location must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyTrusStorePassword() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        secureSocket = {
            key: {
                certFile: "tests/certsandkeys/public.crt",
                keyFile: "tests/certsandkeys/private.key"
            },
            mutualSsl: {
                verifyClient: http:REQUIRE,
                cert: {
                    path: "tests/certsandkeys/ballerinaTruststore.p12",
                    password: ""
                }
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an empty password error" );
    } else {
        test:assertEquals(testListener.message(), "TrustStore password must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyTrustStore() {
    http:Listener|http:Error testListener = new(9249, 
        httpVersion = http:HTTP_1_1,
        host = "",
        secureSocket = {
            key: {
                certFile: "tests/certsandkeys/public.crt",
                keyFile: "tests/certsandkeys/private.key"
            },
            mutualSsl: {
                verifyClient: http:REQUIRE,
                cert: {
                    path: "",
                    password: "ballerina"
                }
            }
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected an empty truststore error" );
    } else {
        test:assertEquals(testListener.message(), "TrustStore file location must be provided for secure connection");
    }
}

@test:Config {}
public function testEmptyHost() {
    http:Listener|http:Error testListener = new(0);
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected a port error" );
    } else {
        test:assertEquals(testListener.message(), "Listener port is not defined!");
    }
}

@test:Config {}
public function testIncorrectIdletimeout() {
    http:Listener|http:Error testListener = new(9244, {timeout: -1});
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected a timeout config error" );
    } else {
        test:assertEquals(testListener.message(), "Idle timeout cannot be negative. If you want to disable the timeout please use value 0");
    }
}

@test:Config {}
public function testIncorrectRequestLimitHeaderSize() {
    http:Listener|http:Error testListener = new(9244, 
        httpVersion = http:HTTP_1_1,
        requestLimits = {
            maxHeaderSize: -1
        }
    );
    if (testListener is http:Listener) {
        test:assertFail(msg = "Found unexpected output: Expected a timeout config error" );
    } else {
        test:assertEquals(testListener.message(), "Invalid configuration found for maxHeaderSize : -1");
    }
}
