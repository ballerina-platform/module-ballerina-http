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
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client urlEncodedResponsesTestClient = check new ("http://localhost:" + generalPort.toString(), httpVersion = http:HTTP_1_1);

public type AcceptedResponse record {|
    *http:Accepted;
    string mediaType = mime:APPLICATION_FORM_URLENCODED;
    map<string> body;
|};

public type ClientErrorResponse record {|
    *http:BadRequest;
    string mediaType = mime:APPLICATION_FORM_URLENCODED;
    map<string> body;
|};

public type ServerErrorResponse record {|
    *http:InternalServerError;
    string mediaType = mime:APPLICATION_FORM_URLENCODED;
    map<string> body;
|};

final map<string> & readonly acceptedResponseBody = {
    "message": "Request is accepted by the server",
    "info": "server.1.1.1.1/data",
    "foo": "bar"
};

final map<string> & readonly clientErrorResponseBody = {
    "message": "Bad Request",
    "key1": "value1",
    "key2": "value2"
};

final map<string> & readonly serverErrorResponseBody = {
    "message": "Internal Server Error",
    "key3": "value3",
    "key4": "value4"
};

service /urlEncodedResponses on generalListener {
    resource function get accepted() returns AcceptedResponse {
        return {
            body: acceptedResponseBody
        };
    }

    resource function get clientError() returns ClientErrorResponse {
        return {
            body: clientErrorResponseBody
        };
    }

    resource function get serverError() returns ServerErrorResponse {
        return {
            body: serverErrorResponseBody
        };
    }

    resource function get acceptedWithStringPayload() returns http:Accepted {
        return {
            mediaType: mime:APPLICATION_FORM_URLENCODED,
            body: "Request is accepted by the server"
        };
    }

    resource function get acceptedWithInlinePayload() returns http:Accepted {
        return {
            mediaType: mime:APPLICATION_FORM_URLENCODED,
            body: {
                "message": "Request is accepted by the server",
                "info": "server.1.1.1.1/data",
                "foo": "bar"
            }
        };
    }

    resource function get directReturn() returns @http:Payload {mediaType: mime:APPLICATION_FORM_URLENCODED} map<string> {
        return {
            "message": "Request is accepted by the server",
            "info": "server.1.1.1.1/data",
            "foo": "bar"
        };
    }
}

@test:Config {}
public function testUrlEncodedAcceptedResponse() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/accepted");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testUrlEncodedAcceptedResponseWithInlineAcceptedBody() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/acceptedWithInlinePayload");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testUrlEncodedWithDirectReturn() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/directReturn");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testUrlEncodedClientErrorResponse() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/clientError");
    test:assertEquals(resp.statusCode, 400, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, clientErrorResponseBody);
}

@test:Config {}
public function testUrlEncodedServerErrorResponse() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/serverError");
    test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, serverErrorResponseBody);
}

@test:Config {}
public function testAcceptedWithStringPayload() returns error? {
    http:Response resp = check urlEncodedResponsesTestClient->get("/urlEncodedResponses/acceptedWithStringPayload");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(resp.getContentType(), mime:APPLICATION_FORM_URLENCODED);
    string payload = check resp.getTextPayload();
    common:assertTextPayload(payload, "Request is accepted by the server");
}
