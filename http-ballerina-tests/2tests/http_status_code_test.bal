// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener httpStatusCodeListenerEP = new(httpStatusCodeTestPort);
http:Client httpStatusCodeClient = new("http://localhost:" + httpStatusCodeTestPort.toString());

@http:ServiceConfig {
    basePath: "/code"
}
service differentStatusCodes on httpStatusCodeListenerEP {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/okWithBody"
    }
    resource function sendOKWithBody(http:Caller caller, http:Request req) {
       checkpanic caller->ok("OK Response");
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/okWithoutBody"
    }
    resource function sendOKWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->ok();
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/createdWithBody"
    }
    resource function sendCreatedWithBody(http:Caller caller, http:Request req) {
        checkpanic caller->created("/newResourceURI", "Created Response");
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/createdWithoutBody"
    }
    resource function sendCreatedWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->created("/newResourceURI");
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/createdWithEmptyURI"
    }
    resource function sendCreatedWithEmptyURI(http:Caller caller, http:Request req) {
        checkpanic caller->created("");
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/acceptedWithBody"
    }
    resource function sendAcceptedWithBody(http:Caller caller, http:Request req) {
        checkpanic caller->accepted({ msg: "accepted response" });
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/acceptedWithoutBody"
    }
    resource function sendAcceptedWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->accepted();
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/noContentWithBody"
    }
    resource function sendNoContentWithBody(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("x-custom-header", "custom-header-value");
        res.setPayload(xml `<test>No Content</test>`);
        checkpanic caller->noContent(res); //Body will be removed
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/noContentWithoutBody"
    }
    resource function sendNoContentWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->noContent();
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/badRequestWithBody"
    }
    resource function sendBadRequestWithBody(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setPayload(xml `<test>Bad Request</test>`);
        checkpanic caller->badRequest(res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/badRequestWithoutBody"
    }
    resource function sendBadRequestWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->badRequest();
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/notFoundWithBody"
    }
    resource function sendNotFoundWithBody(http:Caller caller, http:Request req) {
        checkpanic caller->notFound(xml `<test>artifacts not found</test>`);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/notFoundWithoutBody"
    }
    resource function sendNotFoundWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->notFound();
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/serverErrWithBody"
    }
    resource function sendServerErrWithBody(http:Caller caller, http:Request req) {
        checkpanic caller->internalServerError(xml `<test>Internal Server Error Occurred</test>`);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/serverErrWithoutBody"
    }
    resource function sendServerErrWithoutBody(http:Caller caller, http:Request req) {
        checkpanic caller->internalServerError();
    }
}

//Test ballerina ok() function with entity body
@test:Config {}
function testOKWithBody() {
    var response = httpStatusCodeClient->get("/code/okWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "OK Response");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina ok() function without entity body
@test:Config {}
function testOKWithoutBody() {
    var response = httpStatusCodeClient->get("/code/okWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "0");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with entity body
@test:Config {}
function testCreatedWithBody() {
    var response = httpStatusCodeClient->get("/code/createdWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(response.getHeader(LOCATION), "/newResourceURI");
        assertTextPayload(response.getTextPayload(), "Created Response");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function without entity body
@test:Config {}
function testCreatedWithoutBody() {
    var response = httpStatusCodeClient->get("/code/createdWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(LOCATION), "/newResourceURI");
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "0");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with an empty URI
@test:Config {}
function testCreatedWithEmptyURI() {
    var response = httpStatusCodeClient->get("/code/createdWithEmptyURI");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertFalse(response.hasHeader(LOCATION));
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "0");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function with entity body
@test:Config {}
function testAcceptedWithBody() {
    var response = httpStatusCodeClient->get("/code/acceptedWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {msg:"accepted response"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function without entity body
@test:Config {}
function testAcceptedWithoutBody() {
    var response = httpStatusCodeClient->get("/code/acceptedWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_LENGTH), "0");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina noContent() function with entity body
@test:Config {}
function testNoContentWithBody() {
    var response = httpStatusCodeClient->get("/code/noContentWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("x-custom-header"), "custom-header-value");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina noContent() function without entity body
@test:Config {}
function testNoContentWithoutBody() {
    var response = httpStatusCodeClient->get("/code/noContentWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function with entity body
@test:Config {}
function testBadRequestWithBody() {
    var response = httpStatusCodeClient->get("/code/badRequestWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function without entity body
@test:Config {}
function testBadRequestWithoutBody() {
    var response = httpStatusCodeClient->get("/code/badRequestWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina notFound() function with entity body
@test:Config {}
function testNotFoundWithBody() {
    var response = httpStatusCodeClient->get("/code/notFoundWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>artifacts not found</test>`, msg = "Mismatched xml payload");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina testNotFoundWithoutBody() function without entity body
@test:Config {}
function testNotFoundWithoutBody() {
    var response = httpStatusCodeClient->get("/code/notFoundWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function with entity body
@test:Config {}
function testInternalServerErrWithBody() {
    var response = httpStatusCodeClient->get("/code/serverErrWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Internal Server Error Occurred</test>`, msg = "Mismatched xml payload");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function without entity body
@test:Config {}
function testInternalServerErrWithoutBody() {
    var response = httpStatusCodeClient->get("/code/serverErrWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}




