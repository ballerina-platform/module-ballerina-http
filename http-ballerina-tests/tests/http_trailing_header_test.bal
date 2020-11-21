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

listener http:Listener trailingHeaderListenerEP1 = new(trailingHeaderTestPort1);
listener http:Listener trailingHeaderListenerEP2 = new(trailingHeaderTestPort2);
http:Client trailingHeaderClient = new("http://localhost:" + trailingHeaderTestPort1.toString());

http:Client clientEp = new ("http://localhost:" + trailingHeaderTestPort2.toString());

service initiator on trailingHeaderListenerEP1 {
    @http:ResourceConfig {
        path: "{svc}/{rsc}"
    }
    resource function echoResponse(http:Caller caller, http:Request request, string svc, string rsc) {
        var responseFromBackend = clientEp->forward("/" + <@untainted> svc + "/" + <@untainted> rsc, request);
        if (responseFromBackend is http:Response) {
            var textPayload = responseFromBackend.getTextPayload();

            string trailerHeaderValue = "No trailer header";
            if (responseFromBackend.hasHeader("trailer")) {
                trailerHeaderValue = responseFromBackend.getHeader("trailer");
            }
            string firstTrailer = "No trailer header foo";
            if (responseFromBackend.hasHeader("foo", position = "trailing")) {
                firstTrailer = responseFromBackend.getHeader("foo", position = "trailing");
            }
            string secondTrailer = "No trailer header baz";
            if (responseFromBackend.hasHeader("baz", position = "trailing")) {
                secondTrailer = responseFromBackend.getHeader("baz", position = "trailing");
            }

            int headerCount = responseFromBackend.getHeaderNames(position = "trailing").length();

            http:Response newResponse = new;
            newResponse.setJsonPayload({ foo: <@untainted> firstTrailer, baz: <@untainted> secondTrailer, count:
                                        <@untainted> headerCount });
            newResponse.setHeader("response-trailer", trailerHeaderValue);
            var resultSentToClient = caller->respond(<@untainted> newResponse);
        } else {
            var resultSentToClient = caller->respond("No response from backend");
        }
    }
}

@http:ServiceConfig {
    chunking: http:CHUNKING_ALWAYS
}
service chunkingBackend on trailingHeaderListenerEP2 {
    resource function echo(http:Caller caller, http:Request request) {
        http:Response response = new;
        var textPayload = request.getTextPayload();
        string inPayload = textPayload is string ? textPayload : "error in accessing payload";
        response.setTextPayload(<@untainted> inPayload);
        response.setHeader("foo", "Trailer for chunked payload", position = "trailing");
        response.setHeader("baz", "The second trailer", position = "trailing");
        var result = caller->respond(response);
    }

    resource function empty(http:Caller caller, http:Request request) {
        http:Response response = new;
        response.setTextPayload("");
        response.setHeader("foo", "Trailer for empty payload", position = "trailing");
        response.setHeader("baz", "The second trailer for empty payload", position = "trailing");
        var result = caller->respond(response);
    }
}

@http:ServiceConfig {
    chunking: http:CHUNKING_NEVER
}
service nonChunkingBackend on trailingHeaderListenerEP2 {
    resource function echo(http:Caller caller, http:Request request) {
        http:Response response = new;
        var textPayload = request.getTextPayload();
        string inPayload = textPayload is string ? textPayload : "error in accessing payload";
        response.setTextPayload(<@untainted> inPayload);
        response.setHeader("foo", "Trailer for non chunked payload", position = "trailing");
        response.setHeader("baz", "The second trailer", position = "trailing");
        var result = caller->respond(response);
    }
}

@http:ServiceConfig {
    chunking: http:CHUNKING_ALWAYS
}
service passthroughsvc on trailingHeaderListenerEP2 {
    resource function forward(http:Caller caller, http:Request request) {
        var responseFromBackend = clientEp->forward("/chunkingBackend/echo", request);
        if (responseFromBackend is http:Response) {
            var resultSentToClient = caller->respond(<@untainted> responseFromBackend);
        } else {
            var resultSentToClient = caller->respond("No response from backend");
        }
    }

    resource function buildPayload(http:Caller caller, http:Request request) {
        var responseFromBackend = clientEp->forward("/chunkingBackend/echo", request);
        if (responseFromBackend is http:Response) {
            var textPayload = responseFromBackend.getTextPayload();
            responseFromBackend.setHeader("baz", "this trailer will get replaced", position = "trailing");
            responseFromBackend.setHeader("barr", "this is a new trailer", position = "trailing");
            var resultSentToClient = caller->respond(<@untainted> responseFromBackend);
        } else {
            var resultSentToClient = caller->respond("No response from backend");
        }
    }
}

//Test inbound chunked response trailers with a payload lesser than 8K
@test:Config {}
function testSmallPayloadResponseTrailers() {
    var response = trailingHeaderClient->post("/initiator/chunkingBackend/echo", "Small payload");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "foo, baz");
        assertJsonPayload(response.getJsonPayload(), {foo:"Trailer for chunked payload", baz:"The second " +
                "trailer", count:2});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test inbound chunked response trailers with a payload greater than 8K
@test:Config {}
function testLargePayloadResponseTrailers() {
    var response = trailingHeaderClient->post("/initiator/chunkingBackend/echo", LARGE_ENTITY);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "foo, baz");
        assertJsonPayload(response.getJsonPayload(), {foo:"Trailer for chunked payload", baz:"The second " +
                "trailer", count:2});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test inbound chunked response trailers with an empty payload
@test:Config {}
function testEmptyPayloadResponseTrailers() {
    var response = trailingHeaderClient->get("/initiator/chunkingBackend/empty");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "foo, baz");
        assertJsonPayload(response.getJsonPayload(), {foo:"Trailer for empty payload", baz:"The second " +
                "trailer for empty payload", count:2});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Negative test for inbound response trailers with <8K payload
@test:Config {}
function testSmallPayloadForNonChunkedResponse() {
    var response = trailingHeaderClient->post("/initiator/nonChunkingBackend/echo", "Small payload");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "No trailer header");
        assertJsonPayload(response.getJsonPayload(), {foo:"No trailer header foo", baz:"No trailer header baz", count:0});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Negative test for inbound response trailers with a payload greater than 8K
@test:Config {}
function testLargePayloadForNonChunkedResponse() {
    var response = trailingHeaderClient->post("/initiator/nonChunkingBackend/echo", LARGE_ENTITY);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "No trailer header");
        assertJsonPayload(response.getJsonPayload(), {foo:"No trailer header foo", baz:"No trailer header baz", count:0});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test proxy behaviour with trailers and trailer count
@test:Config {}
function testProxiedTrailers() {
    var response = trailingHeaderClient->post("/initiator/passthroughsvc/forward", "Small payload");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "foo, baz");
        assertJsonPayload(response.getJsonPayload(), {foo:"Trailer for chunked payload", baz:"The second " +
                "trailer", count:2});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test pass-through setting trailers after building payload. Behavior is correct as user has built the datasource
@test:Config {}
function testPassThroughButBuildPayload() {
    var response = trailingHeaderClient->post("/initiator/passthroughsvc/buildPayload", "Small payload");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("response-trailer"), "foo, baz, barr");
        assertJsonPayload(response.getJsonPayload(), {foo:"Trailer for chunked payload", baz:"this trailer " +
                "will get replaced", count:3});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}





