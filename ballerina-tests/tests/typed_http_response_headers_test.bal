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

listener http:Listener typedHeadersTestEP = new(typedHeadersTestPort);
final http:Client typedHeadersTestClient = check new("http://localhost:" + typedHeadersTestPort.toString());

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

type RequestAccepted record {|
    *http:Accepted;
    StringHeaders|IntHeaders|BooleanHeaders|AdvancedHeader headers;
    string body;
|};

service /test on typedHeadersTestEP {
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
                    1, 2, 3
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
                    true, false, true, true
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
                    "HTTP/GET", "Headers/Advanced"
                ]
            },
            body: "Request is accepted by the server"
        };
    }
}

@test:Config {}
public function testStringTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/test/stringHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(checkpanic resp.getHeader("requestId"), "123");
    test:assertEquals(checkpanic resp.getHeaders("requestTypes"), ["HTTP/GET"]);
    assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testIntTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/test/intHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(checkpanic resp.getHeader("requestId"), "123");
    test:assertEquals(checkpanic resp.getHeaders("requestTypes"), [ "1", "2", "3" ]);
    assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testBooleanTypedHeaders() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/test/booleanHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(checkpanic resp.getHeader("isSuccess"), "true");
    test:assertEquals(checkpanic resp.getHeaders("requestFlow"), [ "true", "false", "true", "true" ]);
    assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}

@test:Config {}
public function testAdvancedHeaderTypes() returns error? {
    http:Response resp = check typedHeadersTestClient->get("/test/advancedHeaders");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(checkpanic resp.getHeader("requestId"), "123");
    test:assertEquals(checkpanic resp.getHeader("isSuccess"), "true");
    test:assertEquals(checkpanic resp.getHeaders("requestTypes"), [ "HTTP/GET", "Headers/Advanced" ]);
    assertTextPayload(resp.getTextPayload(), "Request is accepted by the server");
}
