// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/http_test_common as common;

function getStatusCodeError(int statusCode) returns http:StatusCodeError {
    match statusCode {
        400 => {
            return error http:BadRequestError("Bad request error");
        }
        401 => {
            return error http:UnauthorizedError("Unauthorized error");
        }
        402 => {
            return error http:PaymentRequiredError("Payment required error");
        }
        403 => {
            return error http:ForbiddenError("Forbidden error");
        }
        404 => {
            return error http:NotFoundError("Not found error");
        }
        405 => {
            return error http:MethodNotAllowedError("Method not allowed error");
        }
        406 => {
            return error http:NotAcceptableError("Not acceptable error");
        }
        407 => {
            return error http:ProxyAuthenticationRequiredError("Proxy authentication required error");
        }
        408 => {
            return error http:RequestTimeoutError("Request timeout error");
        }
        409 => {
            return error http:ConflictError("Conflict error");
        }
        410 => {
            return error http:GoneError("Gone error");
        }
        411 => {
            return error http:LengthRequiredError("Length required error");
        }
        412 => {
            return error http:PreconditionFailedError("Precondition failed error");
        }
        413 => {
            return error http:PayloadTooLargeError("Payload too large error");
        }
        414 => {
            return error http:URITooLongError("URI too long error");
        }
        415 => {
            return error http:UnsupportedMediaTypeError("Unsupported media type error");
        }
        416 => {
            return error http:RangeNotSatisfiableError("Range not satisfiable error");
        }
        417 => {
            return error http:ExpectationFailedError("Expectation failed error");
        }
        421 => {
            return error http:MisdirectedRequestError("Misdirected request error");
        }
        422 => {
            return error http:UnprocessableEntityError("Unprocessable entity error");
        }
        423 => {
            return error http:LockedError("Locked error");
        }
        424 => {
            return error http:FailedDependencyError("Failed dependency error");
        }
        426 => {
            return error http:UpgradeRequiredError("Upgrade required error");
        }
        428 => {
            return error http:PreconditionRequiredError("Precondition required error");
        }
        429 => {
            return error http:TooManyRequestsError("Too many requests error");
        }
        431 => {
            return error http:RequestHeaderFieldsTooLargeError("Request header fields too large error");
        }
        451 => {
            return error http:UnavailableDueToLegalReasonsError("Unavailable for legal reasons error");
        }
        500 => {
            return error http:InternalServerErrorError("Internal server error error");
        }
        501 => {
            return error http:NotImplementedError("Not implemented error");
        }
        502 => {
            return error http:BadGatewayError("Bad gateway error");
        }
        503 => {
            return error http:ServiceUnavailableError("Service unavailable error");
        }
        504 => {
            return error http:GatewayTimeoutError("Gateway timeout error");
        }
        505 => {
            return error http:HTTPVersionNotSupportedError("HTTP version not supported error");
        }
        506 => {
            return error http:VariantAlsoNegotiatesError("Variant also negotiates error");
        }
        507 => {
            return error http:InsufficientStorageError("Insufficient storage error");
        }
        508 => {
            return error http:LoopDetectedError("Loop detected error");
        }
        510 => {
            return error http:NotExtendedError("Not extended error");
        }
        511 => {
            return error http:NetworkAuthenticationRequiredError("Network authentication required error");
        }
        _ => {
            return error http:DefaultStatusCodeError("Default error", statusCode = statusCode);
        }
    }
}

type CustomHeaders record {|
    string header1;
    string[] header2;
|};

service on new http:Listener(statusCodeErrorPort) {

    resource function get statusCodeError(int statusCode) returns http:StatusCodeError {

        return getStatusCodeError(statusCode);
    }

    resource function post statusCodeError(@http:Payload anydata payload, int statusCode,
            @http:Header CustomHeaders headers) returns http:StatusCodeError {

        return error http:DefaultStatusCodeError("Default error", statusCode = statusCode,
            body = payload, headers = headers);
    }
}

final http:Client clientEndpoint = check new ("http://localhost:" + statusCodeErrorPort.toString());

@test:Config {}
function test400StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 400);
    test:assertEquals(response.statusCode, 400);
    common:assertTextPayload(response.getTextPayload(), "Bad request error");
}

@test:Config {}
function test401StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 401);
    test:assertEquals(response.statusCode, 401);
    common:assertTextPayload(response.getTextPayload(), "Unauthorized error");
}

@test:Config {}
function test403StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 403);
    test:assertEquals(response.statusCode, 403);
    common:assertTextPayload(response.getTextPayload(), "Forbidden error");
}

@test:Config {}
function test404StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 404);
    test:assertEquals(response.statusCode, 404);
    common:assertTextPayload(response.getTextPayload(), "Not found error");
}

@test:Config {}
function test405StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 405);
    test:assertEquals(response.statusCode, 405);
    common:assertTextPayload(response.getTextPayload(), "Method not allowed error");
}

@test:Config {}
function test406StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 406);
    test:assertEquals(response.statusCode, 406);
    common:assertTextPayload(response.getTextPayload(), "Not acceptable error");
}

@test:Config {}
function test407StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 407);
    test:assertEquals(response.statusCode, 407);
    common:assertTextPayload(response.getTextPayload(), "Proxy authentication required error");
}

@test:Config {}
function test408StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 408);
    test:assertEquals(response.statusCode, 408);
    common:assertTextPayload(response.getTextPayload(), "Request timeout error");
}

@test:Config {}
function test409StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 409);
    test:assertEquals(response.statusCode, 409);
    common:assertTextPayload(response.getTextPayload(), "Conflict error");
}

@test:Config {}
function test410StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 410);
    test:assertEquals(response.statusCode, 410);
    common:assertTextPayload(response.getTextPayload(), "Gone error");
}

@test:Config {}
function test411StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 411);
    test:assertEquals(response.statusCode, 411);
    common:assertTextPayload(response.getTextPayload(), "Length required error");
}

@test:Config {}
function test412StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 412);
    test:assertEquals(response.statusCode, 412);
    common:assertTextPayload(response.getTextPayload(), "Precondition failed error");
}

@test:Config {}
function test413StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 413);
    test:assertEquals(response.statusCode, 413);
    common:assertTextPayload(response.getTextPayload(), "Payload too large error");
}

@test:Config {}
function test414StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 414);
    test:assertEquals(response.statusCode, 414);
    common:assertTextPayload(response.getTextPayload(), "URI too long error");
}

@test:Config {}
function test415StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 415);
    test:assertEquals(response.statusCode, 415);
    common:assertTextPayload(response.getTextPayload(), "Unsupported media type error");
}

@test:Config {}
function test416StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 416);
    test:assertEquals(response.statusCode, 416);
    common:assertTextPayload(response.getTextPayload(), "Range not satisfiable error");
}

@test:Config {}
function test417StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 417);
    test:assertEquals(response.statusCode, 417);
    common:assertTextPayload(response.getTextPayload(), "Expectation failed error");
}

@test:Config {}
function test421StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 421);
    test:assertEquals(response.statusCode, 421);
    common:assertTextPayload(response.getTextPayload(), "Misdirected request error");
}

@test:Config {}
function test422StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 422);
    test:assertEquals(response.statusCode, 422);
    common:assertTextPayload(response.getTextPayload(), "Unprocessable entity error");
}

@test:Config {}
function test423StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 423);
    test:assertEquals(response.statusCode, 423);
    common:assertTextPayload(response.getTextPayload(), "Locked error");
}

@test:Config {}
function test424StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 424);
    test:assertEquals(response.statusCode, 424);
    common:assertTextPayload(response.getTextPayload(), "Failed dependency error");
}

@test:Config {}
function test426StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 426);
    test:assertEquals(response.statusCode, 426);
    common:assertTextPayload(response.getTextPayload(), "Upgrade required error");
}

@test:Config {}
function test428StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 428);
    test:assertEquals(response.statusCode, 428);
    common:assertTextPayload(response.getTextPayload(), "Precondition required error");
}

@test:Config {}
function test429StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 429);
    test:assertEquals(response.statusCode, 429);
    common:assertTextPayload(response.getTextPayload(), "Too many requests error");
}

@test:Config {}
function test431StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 431);
    test:assertEquals(response.statusCode, 431);
    common:assertTextPayload(response.getTextPayload(), "Request header fields too large error");
}

@test:Config {}
function test451StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 451);
    test:assertEquals(response.statusCode, 451);
    common:assertTextPayload(response.getTextPayload(), "Unavailable for legal reasons error");
}

@test:Config {}
function test500StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 500);
    test:assertEquals(response.statusCode, 500);
    common:assertTextPayload(response.getTextPayload(), "Internal server error error");
}

@test:Config {}
function test501StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 501);
    test:assertEquals(response.statusCode, 501);
    common:assertTextPayload(response.getTextPayload(), "Not implemented error");
}

@test:Config {}
function test502StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 502);
    test:assertEquals(response.statusCode, 502);
    common:assertTextPayload(response.getTextPayload(), "Bad gateway error");
}

@test:Config {}
function test503StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 503);
    test:assertEquals(response.statusCode, 503);
    common:assertTextPayload(response.getTextPayload(), "Service unavailable error");
}

@test:Config {}
function test504StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 504);
    test:assertEquals(response.statusCode, 504);
    common:assertTextPayload(response.getTextPayload(), "Gateway timeout error");
}

@test:Config {}
function test505StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 505);
    test:assertEquals(response.statusCode, 505);
    common:assertTextPayload(response.getTextPayload(), "HTTP version not supported error");
}

@test:Config {}
function test506StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 506);
    test:assertEquals(response.statusCode, 506);
    common:assertTextPayload(response.getTextPayload(), "Variant also negotiates error");
}

@test:Config {}
function test507StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 507);
    test:assertEquals(response.statusCode, 507);
    common:assertTextPayload(response.getTextPayload(), "Insufficient storage error");
}

@test:Config {}
function test508StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 508);
    test:assertEquals(response.statusCode, 508);
    common:assertTextPayload(response.getTextPayload(), "Loop detected error");
}

@test:Config {}
function test510StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 510);
    test:assertEquals(response.statusCode, 510);
    common:assertTextPayload(response.getTextPayload(), "Not extended error");
}

@test:Config {}
function test511StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 511);
    test:assertEquals(response.statusCode, 511);
    common:assertTextPayload(response.getTextPayload(), "Network authentication required error");
}

@test:Config {}
function testDefaultStatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 600);
    test:assertEquals(response.statusCode, 600);
    common:assertTextPayload(response.getTextPayload(), "Default error");
}

@test:Config {}
function testStatusCodeErrorWithMessage() returns error? {
    json msg = {
        "message": "Error message",
        "code": "1234",
        "description": "Error description",
        "details": {
            "api-version": "v1",
            "allowed-versions": ["v1", "v2"]
        }
    };
    map<string|string[]> headers = {
        "header1": "value1",
        "header2": ["value2", "value3"]
    };
    http:Response response = check clientEndpoint->/statusCodeError.post(msg, headers, statusCode = 512);
    test:assertEquals(response.statusCode, 512);
    common:assertJsonPayload(check response.getJsonPayload(), msg);
    test:assertEquals("value1", check response.getHeader("header1"));
    test:assertEquals(["value2", "value3"], check response.getHeaders("header2"));
}
