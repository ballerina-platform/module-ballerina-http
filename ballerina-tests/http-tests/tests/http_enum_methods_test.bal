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

final http:Client clientEPTest = check new ("http://localhost:" + httpEnumMethodsTestPort.toString(), httpVersion = http:HTTP_1_1);

service / on new http:Listener(httpEnumMethodsTestPort, httpVersion = http:HTTP_1_1) {

    resource function get test() returns string {
        return "GetTest";
    }

    resource function post test() returns string {
        return "PostTest";
    }

    resource function put test() returns string {
        return "PutTest";
    }

    resource function patch test() returns string {
        return "PatchTest";
    }

    resource function delete test() returns string {
        return "DeleteTest";
    }

    resource function head test() returns string {
        return "HeadTest";
    }

    resource function options test() returns string {
        return "OptionsTest";
    }

}

@test:Config{}
public function testHttpEnumMethods() {
    http:Response|error response = clientEPTest->execute(http:GET, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(response.getTextPayload(), "GetTest");
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:POST, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201);
        test:assertEquals(response.getTextPayload(), "PostTest");
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:PUT, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(response.getTextPayload(), "PutTest");
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:PATCH, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(response.getTextPayload(), "PatchTest");
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:DELETE, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(response.getTextPayload(), "DeleteTest");
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:HEAD, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
    } else {
        test:assertFail("Found unexpected output");
    }

    response = clientEPTest->execute(http:OPTIONS, "/test", "testMsg");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(response.getTextPayload(), "OptionsTest");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config{}
public function testMixedCaseMethods() returns error? {
    string payload = check clientEPTest->execute("get", "/test", "testMsg");
    test:assertEquals(payload, "GetTest");
    payload = check clientEPTest->execute("Get", "/test", "testMsg");
    test:assertEquals(payload, "GetTest");
    payload = check clientEPTest->execute("gEt", "/test", "testMsg");
    test:assertEquals(payload, "GetTest");
}
