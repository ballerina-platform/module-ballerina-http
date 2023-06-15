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

    resource function get statusCodeErrorWithCause(int statusCode) returns http:DefaultStatusCodeError {
        error err = statusCode == 0 ? error("New error") : getStatusCodeError(statusCode);
        return error http:DefaultStatusCodeError("Default error", err);
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
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Bad request error", "Bad Request", 400,
                "/statusCodeError?statusCode=400", "GET");
}

@test:Config {}
function test401StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 401);
    test:assertEquals(response.statusCode, 401);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Unauthorized error", "Unauthorized", 401,
                "/statusCodeError?statusCode=401", "GET");
}

@test:Config {}
function test402StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 402);
    test:assertEquals(response.statusCode, 402);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Payment required error", "Payment Required", 402,
                "/statusCodeError?statusCode=402", "GET");
}

@test:Config {}
function test403StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 403);
    test:assertEquals(response.statusCode, 403);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Forbidden error", "Forbidden", 403,
                "/statusCodeError?statusCode=403", "GET");
}

@test:Config {}
function test404StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 404);
    test:assertEquals(response.statusCode, 404);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Not found error", "Not Found", 404,
                "/statusCodeError?statusCode=404", "GET");
}

@test:Config {}
function test405StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 405);
    test:assertEquals(response.statusCode, 405);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Method not allowed error", "Method Not Allowed", 405,
                "/statusCodeError?statusCode=405", "GET");
}

@test:Config {}
function test406StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 406);
    test:assertEquals(response.statusCode, 406);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Not acceptable error", "Not Acceptable", 406,
                "/statusCodeError?statusCode=406", "GET");
}

@test:Config {}
function test407StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 407);
    test:assertEquals(response.statusCode, 407);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Proxy authentication required error", "Proxy Authentication Required", 407,
                "/statusCodeError?statusCode=407", "GET");
}

@test:Config {}
function test408StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 408);
    test:assertEquals(response.statusCode, 408);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Request timeout error", "Request Timeout", 408,
                "/statusCodeError?statusCode=408", "GET");
}

@test:Config {}
function test409StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 409);
    test:assertEquals(response.statusCode, 409);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Conflict error", "Conflict", 409,
                "/statusCodeError?statusCode=409", "GET");
}

@test:Config {}
function test410StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 410);
    test:assertEquals(response.statusCode, 410);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Gone error", "Gone", 410,
                "/statusCodeError?statusCode=410", "GET");
}

@test:Config {}
function test411StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 411);
    test:assertEquals(response.statusCode, 411);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Length required error", "Length Required", 411,
                "/statusCodeError?statusCode=411", "GET");
}

@test:Config {}
function test412StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 412);
    test:assertEquals(response.statusCode, 412);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Precondition failed error", "Precondition Failed", 412,
                "/statusCodeError?statusCode=412", "GET");
}

@test:Config {}
function test413StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 413);
    test:assertEquals(response.statusCode, 413);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Payload too large error", "Request Entity Too Large", 413,
                "/statusCodeError?statusCode=413", "GET");
}

@test:Config {}
function test414StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 414);
    test:assertEquals(response.statusCode, 414);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "URI too long error", "Request-URI Too Long", 414,
                "/statusCodeError?statusCode=414", "GET");
}

@test:Config {}
function test415StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 415);
    test:assertEquals(response.statusCode, 415);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Unsupported media type error", "Unsupported Media Type", 415,
                "/statusCodeError?statusCode=415", "GET");
}

@test:Config {}
function test416StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 416);
    test:assertEquals(response.statusCode, 416);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Range not satisfiable error", "Requested Range Not Satisfiable", 416,
                "/statusCodeError?statusCode=416", "GET");
}

@test:Config {}
function test417StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 417);
    test:assertEquals(response.statusCode, 417);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Expectation failed error", "Expectation Failed", 417,
                "/statusCodeError?statusCode=417", "GET");
}

@test:Config {}
function test421StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 421);
    test:assertEquals(response.statusCode, 421);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Misdirected request error", "Misdirected Request", 421,
                "/statusCodeError?statusCode=421", "GET");
}

@test:Config {}
function test422StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 422);
    test:assertEquals(response.statusCode, 422);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Unprocessable entity error", "Unprocessable Entity", 422,
                "/statusCodeError?statusCode=422", "GET");
}

@test:Config {}
function test423StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 423);
    test:assertEquals(response.statusCode, 423);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Locked error", "Locked", 423,
                "/statusCodeError?statusCode=423", "GET");
}

@test:Config {}
function test424StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 424);
    test:assertEquals(response.statusCode, 424);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Failed dependency error", "Failed Dependency", 424,
                "/statusCodeError?statusCode=424", "GET");
}

@test:Config {}
function test426StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 426);
    test:assertEquals(response.statusCode, 426);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Upgrade required error", "Upgrade Required", 426,
                "/statusCodeError?statusCode=426", "GET");
}

@test:Config {}
function test428StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 428);
    test:assertEquals(response.statusCode, 428);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Precondition required error", "Precondition Required", 428,
                "/statusCodeError?statusCode=428", "GET");
}

@test:Config {}
function test429StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 429);
    test:assertEquals(response.statusCode, 429);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Too many requests error", "Too Many Requests", 429,
                "/statusCodeError?statusCode=429", "GET");
}

@test:Config {}
function test431StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 431);
    test:assertEquals(response.statusCode, 431);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Request header fields too large error", "Request Header Fields Too Large", 431,
                "/statusCodeError?statusCode=431", "GET");
}

@test:Config {}
function test451StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 451);
    test:assertEquals(response.statusCode, 451);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Unavailable for legal reasons error", "Unavailable For Legal Reasons", 451,
                "/statusCodeError?statusCode=451", "GET");
}

@test:Config {}
function test500StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 500);
    test:assertEquals(response.statusCode, 500);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Internal server error error", "Internal Server Error", 500,
                "/statusCodeError?statusCode=500", "GET");
}

@test:Config {}
function test501StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 501);
    test:assertEquals(response.statusCode, 501);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Not implemented error", "Not Implemented", 501,
                "/statusCodeError?statusCode=501", "GET");
}

@test:Config {}
function test502StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 502);
    test:assertEquals(response.statusCode, 502);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Bad gateway error", "Bad Gateway", 502,
                "/statusCodeError?statusCode=502", "GET");
}

@test:Config {}
function test503StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 503);
    test:assertEquals(response.statusCode, 503);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Service unavailable error", "Service Unavailable", 503,
                "/statusCodeError?statusCode=503", "GET");
}

@test:Config {}
function test504StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 504);
    test:assertEquals(response.statusCode, 504);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Gateway timeout error", "Gateway Timeout", 504,
                "/statusCodeError?statusCode=504", "GET");
}

@test:Config {}
function test505StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 505);
    test:assertEquals(response.statusCode, 505);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "HTTP version not supported error", "HTTP Version Not Supported", 505,
                "/statusCodeError?statusCode=505", "GET");
}

@test:Config {}
function test506StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 506);
    test:assertEquals(response.statusCode, 506);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Variant also negotiates error", "Variant Also Negotiates", 506,
                "/statusCodeError?statusCode=506", "GET");
}

@test:Config {}
function test507StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 507);
    test:assertEquals(response.statusCode, 507);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Insufficient storage error", "Insufficient Storage", 507,
                "/statusCodeError?statusCode=507", "GET");
}

@test:Config {}
function test508StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 508);
    test:assertEquals(response.statusCode, 508);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Loop detected error", "Loop Detected", 508,
                "/statusCodeError?statusCode=508", "GET");
}

@test:Config {}
function test510StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 510);
    test:assertEquals(response.statusCode, 510);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Not extended error", "Not Extended", 510,
                "/statusCodeError?statusCode=510", "GET");
}

@test:Config {}
function test511StatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 511);
    test:assertEquals(response.statusCode, 511);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Network authentication required error", "Network Authentication Required", 511,
                "/statusCodeError?statusCode=511", "GET");
}

@test:Config {}
function testDefaultStatusCodeError() returns error? {
    http:Response response = check clientEndpoint->/statusCodeError(statusCode = 600);
    test:assertEquals(response.statusCode, 600);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Default error", "Internal Server Error", 600,
                "/statusCodeError?statusCode=600", "GET");
}

@test:Config {}
function testDefaultStatusCodeErrorWith400ErrorCause() returns error? {
    http:Response response = check clientEndpoint->/statusCodeErrorWithCause(statusCode = 400);
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Default error", "Bad Request", 400,
                "/statusCodeErrorWithCause?statusCode=400", "GET");
}

@test:Config {}
function testDefaultStatusCodeErrorWithCause() returns error? {
    http:Response response = check clientEndpoint->/statusCodeErrorWithCause(statusCode = 0);
    test:assertEquals(response.statusCode, 500);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Default error", "Internal Server Error", 500,
                "/statusCodeErrorWithCause?statusCode=0", "GET");
}

@test:Config {}
function testDefaultStatusCodeErrorWithDefaultErrorCause() returns error? {
    http:Response response = check clientEndpoint->/statusCodeErrorWithCause(statusCode = 600);
    test:assertEquals(response.statusCode, 600);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "Default error", "Internal Server Error", 600,
                "/statusCodeErrorWithCause?statusCode=600", "GET");
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
