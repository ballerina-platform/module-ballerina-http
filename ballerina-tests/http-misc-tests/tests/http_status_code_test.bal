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
import ballerina/http_test_common as common;

listener http:Listener httpStatusCodeListenerEP = new (httpStatusCodeTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpStatusCodeClient = check new ("http://localhost:" + httpStatusCodeTestPort.toString(), httpVersion = http:HTTP_1_1);

service /differentStatusCodes on httpStatusCodeListenerEP {

    resource function get okWithBody() returns http:Ok {
        return {body: "OK Response"};
    }

    resource function get okWithoutBody() returns http:Ok {
        return http:OK;
    }

    resource function get createdWithBody() returns http:Created {
        return {headers: {"Location": "/newResourceURI"}, body: "Created Response"};
    }

    resource function get createdWithoutBody() returns http:Created {
        return {headers: {"Location": "/newResourceURI"}};
    }

    resource function get createdWithEmptyURI() returns http:Created {
        return {headers: {"Location": ""}};
    }

    resource function get acceptedWithBody() returns http:Accepted {
        return {body: {msg: "accepted response"}};
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

    resource function get statusProcessing/[boolean constReq]() returns http:Processing {
        if constReq {
            return http:PROCESSING;
        }
        return {body: "It's Processing"};
    }

    resource function get statusEarlyHints/[boolean constReq]() returns http:EarlyHints {
        if constReq {
            return http:EARLY_HINTS;
        }
        return {body: "It's EarlyHints"};
    }

    resource function get statusMultiStatus/[boolean constReq]() returns http:MultiStatus {
        if constReq {
            return http:MULTI_STATUS;
        }
        return {body: "It's MultiStatus"};
    }

    resource function get statusAlreadyReported/[boolean constReq]() returns http:AlreadyReported {
        if constReq {
            return http:ALREADY_REPORTED;
        }
        return {body: "It's AlreadyReported"};
    }

    resource function get statusIMUsed/[boolean constReq]() returns http:IMUsed {
        if constReq {
            return http:IM_USED;
        }
        return {body: "It's IMUsed"};
    }

    resource function get statusMisdirectedRequest/[boolean constReq]() returns http:MisdirectedRequest {
        if constReq {
            return http:MISDIRECTED_REQUEST;
        }
        return {body: "It's MisdirectedRequest"};
    }

    resource function get statusUnprocessableEntity/[boolean constReq]() returns http:UnprocessableEntity {
        if constReq {
            return http:UNPROCESSABLE_ENTITY;
        }
        return {body: "It's UnprocessableEntity"};
    }

    resource function get statusLocked/[boolean constReq]() returns http:Locked {
        if constReq {
            return http:LOCKED;
        }
        return {body: "It's Locked"};
    }

    resource function get statusFailedDependency/[boolean constReq]() returns http:FailedDependency {
        if constReq {
            return http:FAILED_DEPENDENCY;
        }
        return {body: "It's FailedDependency"};
    }

    resource function get statusTooEarly/[boolean constReq]() returns http:TooEarly {
        if constReq {
            return http:TOO_EARLY;
        }
        return {body: "It's TooEarly"};
    }

    resource function get statusPreconditionRequired/[boolean constReq]() returns http:PreconditionRequired {
        if constReq {
            return http:PREDICTION_REQUIRED;
        }
        return {body: "It's PreconditionRequired"};
    }

    resource function get statusUnavailableDueToLegalReasons/[boolean constReq]() returns http:UnavailableDueToLegalReasons {
        if constReq {
            return http:UNAVAILABLE_DUE_TO_LEGAL_REASONS;
        }
        return {body: "It's UnavailableDueToLegalReasons"};
    }

    resource function get statusVariantAlsoNegotiates/[boolean constReq]() returns http:VariantAlsoNegotiates {
        if constReq {
            return http:VARIANT_ALSO_NEGOTIATES;
        }
        return {body: "It's VariantAlsoNegotiates"};
    }

    resource function get statusInsufficientStorage/[boolean constReq]() returns http:InsufficientStorage {
        if constReq {
            return http:INSUFFICIENT_STORAGE;
        }
        return {body: "It's InsufficientStorage"};
    }

    resource function get statusLoopDetected/[boolean constReq]() returns http:LoopDetected {
        if constReq {
            return http:LOOP_DETECTED;
        }
        return {body: "It's LoopDetected"};
    }

    resource function get statusNotExtended/[boolean constReq]() returns http:NotExtended {
        if constReq {
            return http:NOT_EXTENDED;
        }
        return {body: "It's NotExtended"};
    }

    resource function get NetworkAuthenticationRequired/[boolean constReq]() returns http:NetworkAuthenticationRequired {
        if constReq {
            return http:NETWORK_AUTHENTICATION_REQUIRED;
        }
        return {body: "Authorization Required"};
    }

    resource function get default/[int statusCode]() returns http:DefaultStatusCodeResponse {
        if statusCode == 204 {
            return {status: new (204)};
        }
        return {
            body: "Default Response",
            status: new (statusCode)
        };
    }
}

//Test ballerina ok() function with entity body
@test:Config {}
function testOKWithBody() returns error? {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/okWithBody");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "OK Response");
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_LENGTH), "0");
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertHeaderValue(check response.getHeader(common:LOCATION), "/newResourceURI");
        common:assertTextPayload(response.getTextPayload(), "Created Response");
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
        common:assertHeaderValue(check response.getHeader(common:LOCATION), "/newResourceURI");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_LENGTH), "0");
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
        test:assertTrue(response.hasHeader(common:LOCATION));
        common:assertHeaderValue(check response.getHeader(common:CONTENT_LENGTH), "0");
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {msg: "accepted response"});
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_LENGTH), "0");
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_XML);
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
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_XML);
        test:assertEquals(<xml & readonly>response.detail().body, xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
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
        test:assertTrue(response.detail().headers[common:CONTENT_TYPE] is ());
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_XML);
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
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_XML);
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
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_XML);
        test:assertEquals(<xml & readonly>response.detail().body, xml `<test>Internal Server Error Occurred</test>`, msg = "Mismatched xml payload");
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
        test:assertTrue(response.detail().headers[common:CONTENT_TYPE] is ());
        test:assertTrue(response.detail().body is (), msg = "Mismatched payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

@test:Config {}
function testStatusProcessing() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusProcessing/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 102, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Processing", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusProcessing/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 102, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Processing", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusEarlyHints() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusEarlyHints/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 103, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Early Hints", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusEarlyHints/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 103, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Early Hints", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusMultiStatus() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusMultiStatus/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 207, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Multi-Status", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's MultiStatus");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusMultiStatus/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 207, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Multi-Status", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusAlreadyReported() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusAlreadyReported/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 208, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Success (208)", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's AlreadyReported");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusAlreadyReported/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 208, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Success (208)", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusIMUsed() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusIMUsed/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 226, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Success (226)", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's IMUsed");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusIMUsed/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 226, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Success (226)", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusMisdirectedRequest() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusMisdirectedRequest/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 421, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Misdirected Request", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's MisdirectedRequest");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusMisdirectedRequest/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 421, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Misdirected Request", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusUnprocessableEntity() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusUnprocessableEntity/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 422, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Unprocessable Entity", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's UnprocessableEntity");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusUnprocessableEntity/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 422, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Unprocessable Entity", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusLocked() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusLocked/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 423, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Locked", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's Locked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusLocked/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 423, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Locked", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusFailedDependency() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusFailedDependency/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 424, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Failed Dependency", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's FailedDependency");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusFailedDependency/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 424, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Failed Dependency", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusTooEarly() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusTooEarly/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 425, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Unordered Collection", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's TooEarly");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusTooEarly/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 425, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Unordered Collection", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusPreconditionRequired() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusPreconditionRequired/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 428, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Precondition Required", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's PreconditionRequired");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusPreconditionRequired/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 428, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Precondition Required", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusUnavailableDueToLegalReasons() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusUnavailableDueToLegalReasons/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 451, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Client Error (451)", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's UnavailableDueToLegalReasons");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusUnavailableDueToLegalReasons/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 451, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Client Error (451)", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusVariantAlsoNegotiates() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusVariantAlsoNegotiates/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 506, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Variant Also Negotiates", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's VariantAlsoNegotiates");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusVariantAlsoNegotiates/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 506, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Variant Also Negotiates", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusInsufficientStorage() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusInsufficientStorage/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 507, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Insufficient Storage", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's InsufficientStorage");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusInsufficientStorage/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 507, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Insufficient Storage", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusLoopDetected() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusLoopDetected/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 508, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Server Error (508)", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's LoopDetected");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusLoopDetected/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 508, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Server Error (508)", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStatusNotExtended() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/statusNotExtended/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 510, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Not Extended", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "It's NotExtended");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/statusNotExtended/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 510, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Not Extended", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNetworkAuthenticationRequired() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/NetworkAuthenticationRequired/false");
    if response is http:Response {
        test:assertEquals(response.statusCode, 511, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Network Authentication Required", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Authorization Required");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/NetworkAuthenticationRequired/true");
    if response is http:Response {
        test:assertEquals(response.statusCode, 511, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Network Authentication Required", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDefaultStatusCodeResponse() {
    http:Response|error response = httpStatusCodeClient->get("/differentStatusCodes/default/204");
    if response is http:Response {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "No Content", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/default/201");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Created", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Default Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/default/404");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Not Found", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Default Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/default/500");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Internal Server Error", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Default Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpStatusCodeClient->get("/differentStatusCodes/default/600");
    if response is http:Response {
        test:assertEquals(response.statusCode, 600, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "Unknown Status (600)", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Default Response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
