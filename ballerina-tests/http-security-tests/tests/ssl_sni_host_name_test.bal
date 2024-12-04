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

listener http:Listener http2SniListener = new (9207, http2SslServiceConf);

http:ListenerConfiguration http1SniServiceConf = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener http1SniListener = new (9208, http1SniServiceConf);

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

@test:Config {}
public function testHttp2Sni() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9207", http2SniClientConf);
    string resp = check clientEP->get("/http2SniService/");
    common:assertTextPayload(resp, "Sni works with HTTP_2!");
}

@test:Config {}
public function testHttp1Sni() returns error? {
    http:Client clientEP = check new ("https://127.0.0.1:9208", http1SniClientConf);
    string resp = check clientEP->get("/http1SniService/");
    common:assertTextPayload(resp, "Sni works with HTTP_1.1!");
}
