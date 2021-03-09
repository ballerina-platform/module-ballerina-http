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
http:Client httpStatusCodeClient = check new("http://localhost:" + httpStatusCodeTestPort.toString());

service /differentStatusCodes on httpStatusCodeListenerEP {

    resource function get okWithBody() returns http:Ok {
       return {body: "OK Response"};
    }

    resource function get okWithoutBody() returns http:Ok {
        return {};
    }

    resource function get createdWithBody() returns http:Created {
        return {headers:{"Location":"/newResourceURI"}, body: "Created Response"};
    }

    resource function get createdWithoutBody() returns http:Created {
        return {headers:{"Location":"/newResourceURI"}};
    }

    resource function get createdWithEmptyURI() returns http:Created {
        return {headers:{"Location":""}};
    }

    resource function get acceptedWithBody() returns http:Accepted {
        return {body: {msg:"accepted response"}};
    }

    resource function get acceptedWithoutBody() returns http:Accepted {
        return {};
    }

    resource function get noContentWithoutBody() returns http:NoContent {
        return {}; //Does not have body, media type field
    }

    resource function get badRequestWithBody() returns http:BadRequest {
        return {body: xml `<test>Bad Request</test>`};
    }

    resource function get badRequestWithoutBody() returns http:BadRequest {
        return {};
    }

    resource function get notFoundWithBody() returns http:NotFound {
        return {body: xml `<test>artifacts not found</test>`};
    }

    resource function get notFoundWithoutBody() returns http:NotFound {
        return {};
    }

    resource function get serverErrWithBody() returns http:InternalServerError {
        return {body: xml `<test>Internal Server Error Occurred</test>`};
    }

    resource function get serverErrWithoutBody() returns http:InternalServerError {
        return {};
    }
}

//Test ballerina ok() function with entity body
@test:Config {}
function testOKWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/okWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "OK Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina ok() function without entity body
@test:Config {}
function testOKWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/okWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with entity body
@test:Config {}
function testCreatedWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/createdWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader(LOCATION), "/newResourceURI");
        assertTextPayload(response.getTextPayload(), "Created Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function without entity body
@test:Config {}
function testCreatedWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/createdWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(LOCATION), "/newResourceURI");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with an empty URI
@test:Config {}
function testCreatedWithEmptyURI() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/createdWithEmptyURI");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertTrue(response.hasHeader(LOCATION));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function with entity body
@test:Config {}
function testAcceptedWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/acceptedWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {msg:"accepted response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function without entity body
@test:Config {}
function testAcceptedWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/acceptedWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina noContent() function without entity body
@test:Config {}
function testNoContentWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/noContentWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function with entity body
@test:Config {}
function testBadRequestWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function without entity body
@test:Config {}
function testBadRequestWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina notFound() function with entity body
@test:Config {}
function testNotFoundWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/notFoundWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>artifacts not found</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina testNotFoundWithoutBody() function without entity body
@test:Config {}
function testNotFoundWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/notFoundWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function with entity body
@test:Config {}
function testInternalServerErrWithBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Internal Server Error Occurred</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function without entity body
@test:Config {}
function testInternalServerErrWithoutBody() {
    var response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithoutBody");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}




