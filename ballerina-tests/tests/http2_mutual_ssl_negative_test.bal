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

http:ListenerConfiguration http2MutualSslNegativeServiceConf = {
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
            name: http:TLS,
            versions: ["TLSv1.2","TLSv1.1"]
        },
        ciphers:["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
    },
    httpVersion: "2.0"
};

listener http:Listener http2MutualSslNegativeListener = new(9205, http2MutualSslNegativeServiceConf);

service /http2Service on http2MutualSslNegativeListener {

    resource function get .() returns string {
        return "Hello, World!";
    }
}

http:ClientConfiguration http2MutualSslNegativeClientConf1 = {
    secureSocket: {
        enable: false
    },
    httpVersion: "2.0"
};

@test:Config {}
public function testHttp2MutualSslNegativeTest1() returns error? {
    // Without keys - negative test
    http:Client httpClient = check new("https://localhost:9205", http2MutualSslNegativeClientConf1);
    http:Response|error resp = httpClient->get("/http2Service/");
    string expectedErrMsg = "SSL connection failed:javax.net.ssl.SSLHandshakeException: error:10000410:SSL routines:OPENSSL_internal:SSLV3_ALERT_HANDSHAKE_FAILURE null";
    if (resp is error) {
        test:assertEquals(resp.message(), expectedErrMsg);
    } else {
        test:assertFail(msg = "Expected mutual SSL error not found");
    }
}
