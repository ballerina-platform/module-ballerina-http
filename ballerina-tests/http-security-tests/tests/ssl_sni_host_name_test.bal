// Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org).
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

listener http:Listener http2SniListener = new (http2SniListenerPort, http2SslServiceConf);

http:ListenerConfiguration http1SniServiceConf = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener http1SniListener = new (http1SniListenerPort, http1SniServiceConf);

service /http2SniService on http2SniListener {
    resource function get .() returns string {
        return "Sni works with HTTP_2!";
    }
}

service /http1SniService on http1SniListener {
    resource function get .() returns string {
        return "Sni works with HTTP_1.1!";
    }
}

http:ClientConfiguration http2SniClientConf = {
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        },
        serverName: "localhost"
    }
};

http:ClientConfiguration http1SniClientConf = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        },
        serverName: "localhost"
    }
};

http:ClientConfiguration http1SniClientConf2 = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        },
        serverName: "xxxx"
    }
};

@test:Config {}
public function testHttp2WithSni() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9207", http2SniClientConf);
    string resp = check clientEP->get("/http2SniService/");
    common:assertTextPayload(resp, "Sni works with HTTP_2!");
}

@test:Config {}
public function testHttp1WithSni() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9208", http1SniClientConf);
    string resp = check clientEP->get("/http1SniService/");
    common:assertTextPayload(resp, "Sni works with HTTP_1.1!");
}

@test:Config {}
public function testSniFailure() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9208", http1SniClientConf2);
    string|error resp = clientEP->get("/http1SniService/");
    if resp is error {
        test:assertEquals(resp.message(), "SSL connection failed:No subject alternative names present /127.0.0.1:9208");
    } else {
        test:assertFail("Test `testSniFailure` is expecting an error. But received a success response");
    }
}

@test:Config {}
public function testSniWhenUsingDefaultCerts() returns error? {
    http:Client httpClient = check new("https://www.google.com", http2SniClientConf3);
    string|error resp = httpClient->get("/");
    // This response is success because even though we send a wrong server name, google.com sends the default cert which
    // is valid and trusted by the client.
    if resp is error {
        test:assertFail("Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSniFailureWhenUsingDefaultCerts() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9208", http2SniClientConf3);
    string|error resp = clientEP->get("/http1SniService/");
    if resp is error {
        common:assertTrueTextPayload(resp.message(), "SSL connection failed:javax.net.ssl.SSLHandshakeException:");
    } else {
        test:assertFail("Test `testSniFailureWhenUsingDefaultCerts` is expecting an error. But received a success response");
    }
}
