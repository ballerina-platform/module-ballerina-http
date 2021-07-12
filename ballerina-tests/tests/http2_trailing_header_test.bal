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

import ballerina/http;
import ballerina/test;

listener http:Listener backendEp = new(9119, {httpVersion: "2.0"});
http:Client trailerClientEp = check new("http://localhost:9119", { httpVersion: "2.0", http2Settings: {
    http2PriorKnowledge: true }});

service /trailerInitiator on new http:Listener(9118) {

    resource function 'default [string svc]/[string rsc](http:Caller caller, http:Request request) {
        http:Response|error responseFromBackend = trailerClientEp->forward("/" + svc + "/" + rsc, request);
        if (responseFromBackend is http:Response) {
            string trailerHeaderValue = checkpanic responseFromBackend.getHeader("trailer");
            string|error textPayload = responseFromBackend.getTextPayload();
            string firstTrailer = checkpanic responseFromBackend.getHeader("foo", position = "trailing");
            string secondTrailer = checkpanic responseFromBackend.getHeader("baz", position = "trailing");

            int headerCount = responseFromBackend.getHeaderNames(position = "trailing").length();

            http:Response newResponse = new;
            newResponse.setJsonPayload({ foo: firstTrailer, baz: secondTrailer, count: headerCount });
            newResponse.setHeader("response-trailer", trailerHeaderValue);
            error? resultSentToClient = caller->respond(newResponse);
        } else {
            error? resultSentToClient = caller->respond("No response from backend");
        }
    }
}

service /backend on backendEp {
    resource function 'default echoResponseWithTrailer(http:Caller caller, http:Request request) {
        http:Response response = new;
        var textPayload = request.getTextPayload();
        string inPayload = textPayload is string ? textPayload : "error in accessing payload";
        response.setTextPayload(inPayload);
        response.setHeader("foo", "Trailer for echo payload", position = "trailing");
        response.setHeader("baz", "The second trailer", position = "trailing");
        error? result = caller->respond(response);
    }

    resource function 'default responseEmptyPayloadWithTrailer(http:Caller caller, http:Request request) {
        http:Response response = new;
        response.setTextPayload("");
        response.setHeader("foo", "Trailer for empty payload", position = "trailing");
        response.setHeader("baz", "The second trailer for empty payload", position = "trailing");
        error? result = caller->respond(response);
    }
}

service /passthroughservice on backendEp {
    resource function 'default forward(http:Caller caller, http:Request request) {
        http:Response|error responseFromBackend = trailerClientEp->forward("/backend/echoResponseWithTrailer", request);
        if (responseFromBackend is http:Response) {
            error? resultSentToClient = caller->respond(responseFromBackend);
        } else {
            error? resultSentToClient = caller->respond("No response from backend");
        }
    }

    resource function 'default buildPayload(http:Caller caller, http:Request request) {
        http:Response|error responseFromBackend = trailerClientEp->forward("/backend/echoResponseWithTrailer", request);
        if (responseFromBackend is http:Response) {
            string|error textPayload = responseFromBackend.getTextPayload();
            responseFromBackend.setHeader("baz", "this trailer will get replaced", position = "trailing");
            responseFromBackend.setHeader("barr", "this is a new trailer", position = "trailing");
            error? resultSentToClient = caller->respond(responseFromBackend);
        } else {
            error? resultSentToClient = caller->respond("No response from backend");
        }
    }
}

@test:Config {}
public function testHttp2SmallPayloadResponseTrailers() {
    http:Client clientEP = checkpanic new("http://localhost:9118");
    http:Response|error resp = clientEP->post("/trailerInitiator/backend/echoResponseWithTrailer", "Small payload");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "{\"foo\":\"Trailer for echo payload\", \"baz\":\"The second trailer\", \"count\":2}");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2LargePayloadResponseTrailers() {
    http:Client clientEP = checkpanic new("http://localhost:9118");
    http:Response|error resp = clientEP->post("/trailerInitiator/backend/echoResponseWithTrailer", LARGE_ENTITY);
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "{\"foo\":\"Trailer for echo payload\", \"baz\":\"The second trailer\", \"count\":2}");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2EmptyPayloadResponseTrailers() {
    http:Client clientEP = checkpanic new("http://localhost:9118");
    http:Response|error resp = clientEP->get("/trailerInitiator/backend/responseEmptyPayloadWithTrailer");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "{\"foo\":\"Trailer for empty payload\", \"baz\":\"The second trailer for empty payload\", \"count\":2}");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2ProxiedTrailers() {
    http:Client clientEP = checkpanic new("http://localhost:9118");
    http:Response|error resp = clientEP->post("/trailerInitiator/passthroughservice/forward", "Small payload");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "{\"foo\":\"Trailer for echo payload\", \"baz\":\"The second trailer\", \"count\":2}");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PassThroughButBuildPayload() {
    http:Client clientEP = checkpanic new("http://localhost:9118");
    http:Response|error resp = clientEP->post("/trailerInitiator/passthroughservice/buildPayload", "Small payload");
    if (resp is http:Response) {
        var payload = resp.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "{\"foo\":\"Trailer for echo payload\", \"baz\":\"this trailer will get replaced\", \"count\":3}");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
