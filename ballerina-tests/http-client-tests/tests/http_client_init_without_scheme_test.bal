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
import ballerina/http_test_common as common;

listener http:Listener listenerWithoutSecureSocketConfig = new (clientSchemeTestHttpListenerTestPort, httpVersion = http:HTTP_1_1);

listener http:Listener listenerWithSecureSocketConfig = new (clientSchemeTestHttpsListenerTestPort,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        key: {
            certFile: common:CERT_FILE,
            keyFile: common:KEY_FILE
        }
    }
);

service / on listenerWithoutSecureSocketConfig, listenerWithSecureSocketConfig {

    resource function get test1() returns string {
        return "Hello, World!";
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: {
                    issuer: "wso2",
                    audience: "ballerina",
                    signatureConfig: {
                        certFile: common:CERT_FILE
                    }
                }
            }
        ]
    }
    resource function get test2() returns string {
        return "Hello, World!";
    }
}

// scenario 1 - without client configurations

final http:Client clientWithoutScheme = check new ("localhost:" + clientSchemeTestHttpListenerTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client clientWithHttpScheme = check new ("http://localhost:" + clientSchemeTestHttpListenerTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client clientWithHttpsScheme = check new ("https://example.com", httpVersion = http:HTTP_1_1);

// scenario 2 - with client secure socket configurations

final http:Client clientWithoutSchemeWithSecureSocketConfig = check new ("localhost:" + clientSchemeTestHttpsListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        cert: common:CERT_FILE
    }
);

final http:Client clientWithHttpSchemeWithSecureSocketConfig = check new ("http://localhost:" + clientSchemeTestHttpListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        cert: common:CERT_FILE
    }
);

final http:Client clientWithHttpsSchemeWithSecureSocketConfig = check new ("https://localhost:" + clientSchemeTestHttpsListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        cert: common:CERT_FILE
    }
);

// scenario 3 - with client auth configurations

final http:Client clientWithoutSchemeWithAuthConfig = check new ("example.com",
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    }
);

final http:Client clientWithHttpSchemeWithAuthConfig = check new ("http://localhost:" + clientSchemeTestHttpListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    }
);

final http:Client clientWithHttpsSchemeWithAuthConfig = check new ("https://example.com",
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    }
);

// scenario 4 - with client secure socket and client auth configurations

final http:Client clientWithoutSchemeWithAuthAndSecureSocketConfig = check new ("localhost:" + clientSchemeTestHttpsListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    },
    secureSocket = {
        cert: common:CERT_FILE
    }
);

final http:Client clientWithHttpSchemeWithAuthAndSecureSocketConfig = check new ("http://localhost:" + clientSchemeTestHttpListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    },
    secureSocket = {
        cert: common:CERT_FILE
    }
);

final http:Client clientWithHttpsSchemeWithAuthAndSecureSocketConfig = check new ("https://localhost:" + clientSchemeTestHttpsListenerTestPort.toString(),
    httpVersion = http:HTTP_1_1,
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    },
    secureSocket = {
        cert: common:CERT_FILE
    }
);

@test:Config {}
function testHttpClientWithoutScheme() returns error? {
    string response = check clientWithoutScheme->get("/test1");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpScheme() returns error? {
    string response = check clientWithHttpScheme->get("/test1");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpsScheme() returns error? {
    http:Response response = check clientWithHttpsScheme->get("/");
    test:assertEquals(response.statusCode, 200);
}

@test:Config {}
function testHttpClientWithoutSchemeWithSecureSocketConfig() returns error? {
    string response = check clientWithoutSchemeWithSecureSocketConfig->get("/test1");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpSchemeWithSecureSocketConfig() returns error? {
    string response = check clientWithHttpSchemeWithSecureSocketConfig->get("/test1");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpsSchemeWithSecureSocketConfig() returns error? {
    string response = check clientWithHttpsSchemeWithSecureSocketConfig->get("/test1");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithoutSchemeWithAuthConfig() returns error? {
    http:Response response = check clientWithoutSchemeWithAuthConfig->get("/");
    test:assertEquals(response.statusCode, 200);
}

@test:Config {}
function testHttpClientWithHttpSchemeWithAuthConfig() returns error? {
    string response = check clientWithHttpSchemeWithAuthConfig->get("/test2");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpsSchemeWithAuthConfig() returns error? {
    http:Response response = check clientWithHttpsSchemeWithAuthConfig->get("/");
    test:assertEquals(response.statusCode, 200);
}

@test:Config {}
function testHttpClientWithoutSchemeWithAuthAndSecureSocketConfig() returns error? {
    string response = check clientWithoutSchemeWithAuthAndSecureSocketConfig->get("/test2");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpSchemeWithAuthAndSecureSocketConfig() returns error? {
    string response = check clientWithHttpSchemeWithAuthAndSecureSocketConfig->get("/test2");
    test:assertEquals(response, "Hello, World!");
}

@test:Config {}
function testHttpClientWithHttpsSchemeWithAuthAndSecureSocketConfig() returns error? {
    string response = check clientWithHttpsSchemeWithAuthAndSecureSocketConfig->get("/test2");
    test:assertEquals(response, "Hello, World!");
}
