// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

final http:Client typedHeadersTestClient = check new ("http://localhost:" + generalPort.toString(), httpVersion = http:HTTP_1_1);

type StringHeaders record {|
    string requestId;
    string[] requestTypes?;
|};

type IntHeaders record {|
    int requestId;
    int[] requestTypes?;
|};

type BooleanHeaders record {|
    boolean isSuccess;
    boolean[] requestFlow?;
|};

type AdvancedHeader record {|
    int requestId;
    boolean isSuccess;
    string[] requestTypes?;
|};

public type RequestAccepted record {|
    *http:Accepted;
    StringHeaders|IntHeaders|BooleanHeaders|AdvancedHeader headers;
    string body;
|};

service /typedHeaders on generalListener {
    resource function get stringHeaders() returns RequestAccepted {
        return {
            headers: {
                requestId: "123",
                requestTypes: [
                    "HTTP/GET"
                ]
            },
            body: "Request is accepted by the server"
        };
    }

    resource function get intHeaders() returns RequestAccepted {
        return {
            headers: {
                requestId: 123,
                requestTypes: [
                    1,
                    2,
                    3
                ]
            },
            body: "Request is accepted by the server"
        };
    }

    resource function get booleanHeaders() returns RequestAccepted {
        return {
            headers: {
                isSuccess: true,
                requestFlow: [
                    true,
                    false,
                    true,
                    true
                ]
            },
            body: "Request is accepted by the server"
        };
    }

    resource function get advancedHeaders() returns RequestAccepted {
        return {
            headers: {
                requestId: 123,
                isSuccess: true,
                requestTypes: [
                    "HTTP/GET",
                    "Headers/Advanced"
                ]
            },
            body: "Request is accepted by the server"
        };
    }
}

@test:Config {}
public function testStringTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/typedHeaders/stringHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader("requestId"), "123");
    test:assertEquals(check resp.getHeaders("requestTypes"), ["HTTP/GET"]);
    common:assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testIntTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/typedHeaders/intHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader("requestId"), "123");
    test:assertEquals(check resp.getHeaders("requestTypes"), ["1", "2", "3"]);
    common:assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testBooleanTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/typedHeaders/booleanHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader("isSuccess"), "true");
    test:assertEquals(check resp.getHeaders("requestFlow"), ["true", "false", "true", "true"]);
    common:assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testAdvancedHeaderTypes() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/typedHeaders/advancedHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader("requestId"), "123");
    test:assertEquals(check resp.getHeader("isSuccess"), "true");
    test:assertEquals(check resp.getHeaders("requestTypes"), ["HTTP/GET", "Headers/Advanced"]);
    common:assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}
