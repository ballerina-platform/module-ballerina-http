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

final http:Client http2UrlEncodedResponsesTestClient = check new ("http://localhost:" + http2GeneralPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

service /urlEncodedResponses on generalHTTP2Listener {
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
public function testHttp2UrlEncodedAcceptedResponse() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/accepted");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testHttp2UrlEncodedAcceptedResponseWithInlineAcceptedBody() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/acceptedWithInlinePayload");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testHttp2UrlEncodedWithDirectReturn() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/directReturn");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, acceptedResponseBody);
}

@test:Config {}
public function testHttp2UrlEncodedClientErrorResponse() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/clientError");
    test:assertEquals(resp.statusCode, 400, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, clientErrorResponseBody);
}

@test:Config {}
public function testHttp2UrlEncodedServerErrorResponse() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/serverError");
    test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
    string payload = check resp.getTextPayload();
    check common:assertUrlEncodedPayload(payload, serverErrorResponseBody);
}

@test:Config {}
public function testHttp2AcceptedWithStringPayload() returns error? {
    http:Response resp = check http2UrlEncodedResponsesTestClient->get("/urlEncodedResponses/acceptedWithStringPayload");
    test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
    test:assertEquals(resp.getContentType(), mime:APPLICATION_FORM_URLENCODED);
    string payload = check resp.getTextPayload();
    common:assertTextPayload(payload, "Request is accepted by the server");
}
