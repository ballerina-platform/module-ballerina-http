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

listener http:Listener httpStatusCodeListenerEP = new(httpStatusCodeTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpStatusCodeClient = check new("http://localhost:" + httpStatusCodeTestPort.toString(), httpVersion = http:HTTP_1_1);

service /differentStatusCodes on httpStatusCodeListenerEP {

    resource function get okWithBody() returns http:Ok {
       return {body: "OK Response"};
    }

    resource function get okWithoutBody() returns http:Ok {
        return http:OK;
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
        return http:ACCEPTED;
    }

    resource function get noContentWithoutBody() returns http:NoContent {
        return http:NO_CONTENT; //Does not have body, media type field
    }

    resource function get badRequestWithBody() returns http:BadRequest {
        return {body: xml `<test>Bad Request</test>`};
    }

    resource function get badRequestWithoutBody() returns http:BadRequest {
        return http:BAD_REQUEST;
    }

    resource function get notFoundWithBody() returns http:NotFound {
        return {body: xml `<test>artifacts not found</test>`};
    }

    resource function get notFoundWithoutBody() returns http:NotFound {
        return http:NOT_FOUND;
    }

    resource function get serverErrWithBody() returns http:InternalServerError {
        return {body: xml `<test>Internal Server Error Occurred</test>`};
    }

    resource function get serverErrWithoutBody() returns http:InternalServerError {
        return http:INTERNAL_SERVER_ERROR;
    }

    resource function get networkAuthorizationRequired/[boolean constReq]() returns http:NetworkAuthorizationRequired {
        if constReq {
            return http:NETWORK_AUTHORIZATION_REQUIRED;
        }
       return {body: "Authorization Required"};
    }
}

Test ballerina ok() function with entity body
@test:Config {}
function testOKWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/okWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "OK Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina ok() function without entity body
@test:Config {}
function testOKWithoutBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/okWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with entity body
@test:Config {}
function testCreatedWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/createdWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(check response.getHeader(LOCATION), "/newResourceURI");
        assertTextPayload(response.getTextPayload(), "Created Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function without entity body
@test:Config {}
function testCreatedWithoutBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/createdWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(LOCATION), "/newResourceURI");
        assertHeaderValue(check response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina created() function with an empty URI
@test:Config {}
function testCreatedWithEmptyURI() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/createdWithEmptyURI");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertTrue(response.hasHeader(LOCATION));
        assertHeaderValue(check response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function with entity body
@test:Config {}
function testAcceptedWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/acceptedWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {msg:"accepted response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina accepted() function without entity body
@test:Config {}
function testAcceptedWithoutBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/acceptedWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina noContent() function without entity body
@test:Config {}
function testNoContentWithoutBody() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/noContentWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina noContent() function without entity body
@test:Config {}
function testNoContentWithDataBinding() {
    string|error response = httpStatusCodeClient->get("/differentStatusCodes/noContentWithoutBody");
    if (response is error) {
        test:assertEquals(response.message(), "No content", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: string");
    }
}

//Test ballerina noContent() function without entity body and nil-able type
@test:Config {}
function testNoContentWithDataBindingWithNilableType() returns error? {
    string? response = check httpStatusCodeClient->get("/differentStatusCodes/noContentWithoutBody");
    if (response is string) {
        test:assertFail(msg = "Found unexpected output type: string");
    }
    return;
}

//Test ballerina badRequest() function with entity body
@test:Config {}
function testBadRequestWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function with entity body
@test:Config {}
function testDataBindingBadRequestWithBody() {
    json|error response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithBody");
    if (response is http:ClientRequestError) {
        test:assertEquals(response.detail().statusCode, 400, msg = "Found unexpected output");
        assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], APPLICATION_XML);
        test:assertEquals(<xml & readonly> response.detail().body, xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

//Test ballerina badRequest() function without entity body
@test:Config {}
function testBadRequestWithoutBody() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina badRequest() function without entity body
@test:Config {}
function testDataBindingBadRequestWithoutBody() {
    string|error response = httpStatusCodeClient->get("/differentStatusCodes/badRequestWithoutBody");
    if (response is http:ClientRequestError) {
        test:assertEquals(response.detail().statusCode, 400, msg = "Found unexpected output");
        test:assertTrue(response.detail().headers[CONTENT_TYPE] is ());
        test:assertTrue(response.detail().body is (), msg = "Mismatched payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: string");
    }
}

//Test ballerina notFound() function with entity body
@test:Config {}
function testNotFoundWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/notFoundWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>artifacts not found</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina testNotFoundWithoutBody() function without entity body
@test:Config {}
function testNotFoundWithoutBody() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/notFoundWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function with entity body
@test:Config {}
function testInternalServerErrWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Internal Server Error Occurred</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test ballerina internalServerError() function with entity body
@test:Config {}
function testDataBindingInternalServerErrWithBody() {
    xml|error response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithBody");
    if (response is http:RemoteServerError) {
        test:assertEquals(response.detail().statusCode, 500, msg = "Found unexpected output");
        assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], APPLICATION_XML);
        test:assertEquals(<xml & readonly> response.detail().body, xml `<test>Internal Server Error Occurred</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: xml");
    }
}

//Test ballerina internalServerError() function without entity body
@test:Config {}
function testInternalServerErrWithoutBody() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithoutBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}


//Test ballerina internalServerError() function without entity body
@test:Config {}
function testDataBindingInternalServerErrWithoutBody() {
    json|error response = httpStatusCodeClient->get("/differentStatusCodes/serverErrWithoutBody");
    if (response is http:RemoteServerError) {
        test:assertEquals(response.detail().statusCode, 500, msg = "Found unexpected output");
        test:assertTrue(response.detail().headers[CONTENT_TYPE] is ());
        test:assertTrue(response.detail().body is (), msg = "Mismatched payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

@test:Config {}
function testNetworkAuthorizationRequired() {
    http:Response|error response = httpStatusCodeClient->get
    ("/differentStatusCodes/networkAuthorizationRequired/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 511, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Network Authentication Required", msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Network Authentication Required", msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Authorization Required");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/networkAuthorizationRequired/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 511, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Network Authentication Required", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
