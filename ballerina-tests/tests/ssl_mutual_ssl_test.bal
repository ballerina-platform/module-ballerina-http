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

http:ListenerConfiguration mutualSslServiceConf = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        mutualSsl: {
            verifyClient: http:REQUIRE,
            cert: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            }
        },
        protocol: {
            name: "TLS",
            versions: ["TLSv1.2"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"],
        handshakeTimeout: 20,
        sessionTimeout: 30
    }
};

listener http:Listener echo15 = new(9116, mutualSslServiceConf);

service /helloWorld15 on echo15 {
    
    resource function get .(http:Caller caller, http:Request req) returns error? {
        string expectedCert = "MIIDdzCCAl+gAwIBAgIEfP3e8zANBgkqhkiG9w0BAQsFADBkMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExF"
                        + "jAUBgNVBAcTDU1vdW50YWluIFZpZXcxDTALBgNVBAoTBFdTTzIxDTALBgNVBAsTBFdTTzIxEjAQBgNVBAMTCWxvY2Fsa"
                        + "G9zdDAeFw0xNzEwMjQwNTQ3NThaFw0zNzEwMTkwNTQ3NThaMGQxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA"
                        + "1UEBxMNTW91bnRhaW4gVmlldzENMAsGA1UEChMEV1NPMjENMAsGA1UECxMEV1NPMjESMBAGA1UEAxMJbG9jYWxob3N0M"
                        + "IIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgVyi6fViVLiZKEnw59xzNi1lcYh6z9dZnug+F9gKqFIgmdcPe"
                        + "+qtS7gZc1jYTjWMCbx13sFLkZqNHeDUadpmtKo3TDduOl1sqM6cz3yXb6L34k/leh50mzIPNmaaXxd3vOQoK4OpkgO1n"
                        + "32mh6+tkp3sbHmfYqDQrkVK1tmYNtPJffSCLT+CuIhnJUJco7N0unax+ySZN67/AX++sJpqAhAIZJzrRi6ueN3RFCIxY"
                        + "DXSMvxrEmOdn4gOC0o1Ar9u5Bp9N52sqqGbN1x6jNKi3bfUj122Hu5e+Y9KOmfbchhQil2P81cIi30VKgyDn5DeWEuDo"
                        + "Yredk4+6qAZrxMw+wIDAQABozEwLzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0OBBYEFNmtrQ36j6tUGhKrfW9qWWE7KFzMM"
                        + "A0GCSqGSIb3DQEBCwUAA4IBAQAv3yOwgbtOu76eJMl1BCcgTFgaMUBZoUjK9Un6HGjKEgYz/YWSZFlY/qH5rT01DWQev"
                        + "UZB626d5ZNdzSBZRlpsxbf9IE/ursNHwHx9ua6fB7yHUCzC1ZMp1lvBHABi7wcA+5nbV6zQ7HDmBXFhJfbgH1iVmA1Kc"
                        + "vDeBPSJ/scRGasZ5q2W3IenDNrfPIUhD74tFiCiqNJO91qD/LO+++3XeZzfPh8NRKkiPX7dB8WJ3YNBuQAvgRWTISpSS"
                        + "XLmqMb+7MPQVgecsepZdk8CwkRLxh3RKPJMjigmCgyvkSaoDMKAYC3iYjfUTiJ57UeqoSl0IaOFJ0wfZRFh+UytlDZa";
        http:Response res = new;
        if req.mutualSslHandshake["status"] == "passed" {
            string? cert = req.mutualSslHandshake["base64EncodedCert"];
            if cert is string {
                if cert == expectedCert {
                    res.setTextPayload("hello world");
                } else {
                    res.setTextPayload("Expected cert not found");
                }
            } else {
                res.setTextPayload("Cert not found");
            }
        }
        check caller->respond(res);
    }
}

listener http:Listener echoDummy15 = new(9117, httpVersion = http:HTTP_1_1);

service /echoDummyService15 on echoDummy15 {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello world");
        check caller->respond(res);
    }
}

http:ClientConfiguration mutualSslClientConf1 = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        cert: {
            path: "tests/certsandkeys/ballerinaTruststore.p12",
            password: "ballerina"
        },
        protocol: {
            name: http:SSL,
            versions: ["TLSv1.2"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"],
        handshakeTimeout: 20,
        sessionTimeout: 30
    }
};

@test:Config {}
public function testMutualSsl1() returns error? {
    http:Client httpClient = check new("https://localhost:9116", mutualSslClientConf1);
    http:Response|error resp = httpClient->get("/helloWorld15/");
    if resp is http:Response {
        var payload = resp.getTextPayload();
        if payload is string {
            test:assertEquals(payload, "hello world");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

http:ClientConfiguration mutualSslClientConf2 = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        protocol: {
            name: http:SSL,
            versions: ["TLSv1.2"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"],
        handshakeTimeout: 20,
        sessionTimeout: 30
    }
};

@test:Config {}
public function testMutualSsl2() returns error? {
    http:Client httpClient = check new("https://localhost:9116", mutualSslClientConf2);
    http:Response|error resp = httpClient->get("/helloWorld15/");
    string expectedErrMsg = "SSL connection failed:unable to find valid certification path to requested target localhost/127.0.0.1:9116";
    if resp is error {
        test:assertEquals(resp.message(), expectedErrMsg);
    } else {
        test:assertFail(msg = "Expected mutual SSL error not found");
    }
}

http:ClientConfiguration mutualSslClientConf3 = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        enable: false,
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        },
        protocol: {
            name: http:SSL,
            versions: ["TLSv1.2"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"],
        handshakeTimeout: 20,
        sessionTimeout: 30
    }
};

@test:Config {}
public function testMutualSsl3() returns error? {
    http:Client httpClient = check new("https://localhost:9116", mutualSslClientConf3);
    http:Response|error resp = httpClient->get("/helloWorld15/");
    if resp is http:Response {
        var payload = resp.getTextPayload();
        if payload is string {
            test:assertEquals(payload, "hello world");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
