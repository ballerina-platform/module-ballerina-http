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
import ballerina/test;
import ballerina/http_test_common as common;

http:ListenerConfiguration serviceConf = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener httpsListener = new (9238, serviceConf);

service /httpsService on httpsListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello world");
        check caller->respond(res);
    }
}

http:ClientConfiguration disableSslClientConf1 = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        enable: false
    }
};

@test:Config {}
public function testSslDisabledClient1() returns error? {
    http:Client httpClient = check new ("https://localhost:9238", disableSslClientConf1);
    http:Response|error resp = httpClient->get("/httpsService");
    if resp is http:Response {
        var payload = resp.getTextPayload();
        if payload is string {
            test:assertEquals(payload, "hello world");
        } else {
            test:assertFail(msg = "Found unexpected output: " + payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
