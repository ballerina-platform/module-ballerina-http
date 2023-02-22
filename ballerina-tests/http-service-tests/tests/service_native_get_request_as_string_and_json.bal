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
import ballerina/http_test_common as common;

service /MyService on generalListener {

    resource function post myResource(http:Caller caller, http:Request req) returns error? {
        _ = check req.getTextPayload();
        json payload = check req.getJsonPayload();
        http:Response res = new;
        res.setPayload(check payload.foo);
        return caller->respond(res);
    }
}

final http:Client requestClient2 = check new ("http://localhost:" + generalPort.toString(), httpVersion = http:HTTP_1_1);

@test:Config {}
public function testAccessingPayloadAsTextAndJSON() {
    string payload = "{ \"foo\" : \"bar\"}";
    string path = "/MyService/myResource";
    http:Request req = new;
    req.setTextPayload(payload);
    http:Response|error response = requestClient2->post(path, req);
    if response is http:Response {
        common:assertJsonPayload(response.getTextPayload(), "bar");
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
