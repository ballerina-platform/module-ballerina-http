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

import ballerina/test;
import ballerina/http;

listener http:Listener httpUrlListenerEP1 = new(httpUrlTestPort1);
listener http:Listener httpUrlListenerEP2 = new(httpUrlTestPort2);
http:Client httpUrlClient = new("http://localhost:" + httpUrlTestPort1.toString());

http:Client urlClient = new ("http://localhost:" + httpUrlTestPort2.toString() + "//url", { cache: { enabled: false }});

@http:ServiceConfig {
    basePath: "/url//test"
}
service urlBackend on httpUrlListenerEP2 {

    @http:ResourceConfig {
        path: "//"
    }
    resource function replyText(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello");
    }
}

@http:ServiceConfig {
    basePath: "//url"
}
service urlClientTest on httpUrlListenerEP1  {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "//"
    }
    resource function hello(http:Caller caller, http:Request request) {
        string value = "";
        var response = urlClient->get("//test");
        if (response is http:Response) {
            var result = response.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }
        checkpanic caller->respond(<@untainted> value);
    }
}

//Test for handling double slashes
@test:Config {}
function testUrlDoubleSlash() {
    var response = httpUrlClient->get("/url");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
