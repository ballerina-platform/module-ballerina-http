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

import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener testEP = new(requestTest2);

@http:ServiceConfig { 
    basePath: "/foo" 
}
service MyService on testEP {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/bar"
    }
    resource function myResource(http:Caller caller, http:Request req) {
        var stringValue = req.getTextPayload();
        if (stringValue is string) {
            string s = stringValue;
        } else {
            panic <error>stringValue;
        }
        json payload;
        var jsonValue = req.getJsonPayload();
        if (jsonValue is json) {
            payload = jsonValue;
        } else {
            panic <error>jsonValue;
        }
        http:Response res = new;
        res.setPayload(<@untainted json> payload.foo);
        var err = caller->respond(res);
        if (err is error) {
            io:println("Error sending response");
        }
    }
}

http:Client requestClient2 = new("http://localhost:" + requestTest2.toString());

@test:Config {}
public function testAccessingPayloadAsTextAndJSON()  {
    string payload = "{ \"foo\" : \"bar\"}";
    string path = "/foo/bar";
    http:Request req = new;
    req.setTextPayload(payload);
    var response = requestClient2->post(path, req);
    if (response is http:Response) {
        assertJsonPayload(response.getTextPayload(), "bar");
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
