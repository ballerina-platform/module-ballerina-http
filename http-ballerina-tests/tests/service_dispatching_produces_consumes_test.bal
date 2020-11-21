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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/mime;
import ballerina/test;
import ballerina/http;

listener http:Listener pcEP = new(producesConsumesTest);
http:Client pcClient = new("http://localhost:" + producesConsumesTest.toString());

service echo66 on pcEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/test1",
        consumes: ["application/xml"]
    }
    resource function echo1(http:Caller caller, http:Request req) {
        checkpanic caller->respond({ msg: "wso2" });
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/test2",
        produces: ["text/xml", "application/xml "]
    }
    resource function echo2(http:Caller caller, http:Request req) {
        checkpanic caller->respond({ msg: "wso22" });
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/test3",
        consumes: ["application/xhtml+xml", "text/plain", "text/json"],
        produces: ["text/css", "application/json"]
    }
    resource function echo3(http:Caller caller, http:Request req) {
        checkpanic caller->respond({ msg: "wso222" });
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/test4",
        consumes: ["appliCation/XML"],
        produces: ["Application/JsON"]
    }
    resource function echo4(http:Caller caller, http:Request req) {
        checkpanic caller->respond({ msg: "wso222" });
    }
}

service echo67 on pcEP {
    resource function echo1(http:Caller caller, http:Request req) {
        checkpanic caller->respond({ echo33: "echo1" });
    }
}

//Test Consumes annotation with URL. /echo66/test1
@test:Config {}
function testConsumesAnnotation() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader(mime:CONTENT_TYPE, "application/xml; charset=ISO-8859-4");
    var response = pcClient->post("/echo66/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test incorrect Consumes annotation with URL. /echo66/test1 
@test:Config {}
function testIncorrectConsumesAnnotation() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader(mime:CONTENT_TYPE, "compileResult/json");
    var response = pcClient->post("/echo66/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 415, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test bogus Consumes annotation with URL. /echo66/test1
@test:Config {}
function testBogusConsumesAnnotation() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader(mime:CONTENT_TYPE, ",:vhjv");
    var response = pcClient->post("/echo66/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 415, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Produces annotation with URL. /echo66/test2
@test:Config {}
function testProducesAnnotation() {
    http:Request req = new;
    req.setHeader(mime:CONTENT_TYPE, "text/xml;q=0.3, multipart/*;Level=1;q=0.7");
    var response = pcClient->get("/echo66/test2", message = req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso22");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Produces with no Accept header with URL. /echo66/test2
@test:Config {}
function testProducesAnnotationWithNoHeaders() {
    var response = pcClient->get("/echo66/test2");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso22");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Produces with wildcard header with URL. /echo66/test2
@test:Config {}
function testProducesAnnotationWithWildCard() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader("Accept", "*/*, text/html;Level=1;q=0.7");
    var response = pcClient->get("/echo66/test2", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso22");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Produces with sub type wildcard header with URL. /echo66/test2
@test:Config {}
function testProducesAnnotationWithSubTypeWildCard() {
    http:Request req = new;
    req.setHeader("Accept", "text/*;q=0.3, text/html;Level=1;q=0.7");
    var response = pcClient->get("/echo66/test2", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso22");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test incorrect Produces annotation with URL. /echo66/test2
@test:Config {}
function testIncorrectProducesAnnotation() {
    http:Request req = new;
    req.setHeader("Accept", "multipart/*;q=0.3, text/html;Level=1;q=0.7");
    var response = pcClient->get("/echo66/test2", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 406, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test bogus Produces annotation with URL. /echo66/test2
@test:Config {}
function testBogusProducesAnnotation() {
    http:Request req = new;
    req.setHeader("Accept", ":,;,v567br");
    var response = pcClient->get("/echo66/test2", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 406, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Produces and Consumes with URL. /echo66/test3
@test:Config {}
function testProducesConsumeAnnotation() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader(mime:CONTENT_TYPE, "text/plain; charset=ISO-8859-4");
    req.setHeader("Accept", "text/*;q=0.3, text/html;Level=1;q=0.7");
    var response = pcClient->post("/echo66/test3", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso222");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Incorrect Produces and Consumes with URL. /echo66/test3
@test:Config {}
function testIncorrectProducesConsumeAnnotation() {
    http:Request req = new;
    req.setTextPayload("Test");
    req.setHeader(mime:CONTENT_TYPE, "text/plain ; charset=ISO-8859-4");
    req.setHeader("Accept", "compileResult/xml, text/html");
    var response = pcClient->post("/echo66/test3", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 406, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test without Pro-Con annotation with URL. /echo67/echo1
@test:Config {}
function testWithoutProducesConsumeAnnotation() {
    http:Request req = new;
    req.setHeader(mime:CONTENT_TYPE, "text/plain; charset=ISO-8859-4");
    req.setHeader("Accept", "text/*;q=0.3, text/html;Level=1;q=0.7");
    var response = pcClient->get("/echo67/echo1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo33", "echo1");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test case insensitivity of produces and consumes annotation values
@test:Config {}
function testCaseInSensitivityOfProduceAndConsume() {
    http:Request req = new;
    xml content = xml `<test>TestVal</test>`;
    req.setXmlPayload(content);
    req.setHeader(mime:CONTENT_TYPE, "application/xml; charset=ISO-8859-4");
    req.setHeader("Accept", "application/json");
    var response = pcClient->post("/echo66/test4", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "msg", "wso222");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
