// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

final http:Client statusCodeBindingClient1 = check new (string `localhost:${statusCodeBindingPort1}`);

service /api on new http:Listener(statusCodeBindingPort1) {

    resource function get status\-code\-response(int code) returns http:StatusCodeResponse {
        return getStatusCodeResponse(code);
    }
}

function getStatusCodeResponse(int code) returns http:StatusCodeResponse {
    match code {
        // Cannot test these since these status codes expects different behaviors at transport level
        // 100 => {
        //     return <http:Continue>{body: {msg: "Continue response"}, mediaType: "application/org+json", headers: {"x-error": "Continue"}};
        // }
        // 101 => {
        //     return <http:SwitchingProtocols>{body: {msg: "Switching protocols response"}, mediaType: "application/org+json", headers: {"x-error": "Switching protocols"}};
        // }
        102 => {
            return <http:Processing>{body: {msg: "Processing response"}, mediaType: "application/org+json", headers: {"x-error": "Processing"}};
        }
        103 => {
            return <http:EarlyHints>{body: {msg: "Early hints response"}, mediaType: "application/org+json", headers: {"x-error": "Early hints"}};
        }
        200 => {
            return <http:Ok>{body: {msg: "OK response"}, mediaType: "application/org+json", headers: {"x-error": "OK"}};
        }
        201 => {
            return <http:Created>{body: {msg: "Created response"}, mediaType: "application/org+json", headers: {"x-error": "Created"}};
        }
        202 => {
            return <http:Accepted>{body: {msg: "Accepted response"}, mediaType: "application/org+json", headers: {"x-error": "Accepted"}};
        }
        203 => {
            return <http:NonAuthoritativeInformation>{body: {msg: "Non-authoritative information response"}, mediaType: "application/org+json", headers: {"x-error": "Non-authoritative information"}};
        }
        204 => {
            return <http:NoContent>{headers: {"x-error": "No content"}};
        }
        205 => {
            return <http:ResetContent>{body: {msg: "Reset content response"}, mediaType: "application/org+json", headers: {"x-error": "Reset content"}};
        }
        206 => {
            return <http:PartialContent>{body: {msg: "Partial content response"}, mediaType: "application/org+json", headers: {"x-error": "Partial content"}};
        }
        207 => {
            return <http:MultiStatus>{body: {msg: "Multi-status response"}, mediaType: "application/org+json", headers: {"x-error": "Multi-status"}};
        }
        208 => {
            return <http:AlreadyReported>{body: {msg: "Already reported response"}, mediaType: "application/org+json", headers: {"x-error": "Already reported"}};
        }
        226 => {
            return <http:IMUsed>{body: {msg: "IM used response"}, mediaType: "application/org+json", headers: {"x-error": "IM used"}};
        }
        300 => {
            return <http:MultipleChoices>{body: {msg: "Multiple choices response"}, mediaType: "application/org+json", headers: {"x-error": "Multiple choices"}};
        }
        301 => {
            return <http:MovedPermanently>{body: {msg: "Moved permanently response"}, mediaType: "application/org+json", headers: {"x-error": "Moved permanently"}};
        }
        302 => {
            return <http:Found>{body: {msg: "Found response"}, mediaType: "application/org+json", headers: {"x-error": "Found"}};
        }
        303 => {
            return <http:SeeOther>{body: {msg: "See other response"}, mediaType: "application/org+json", headers: {"x-error": "See other"}};
        }
        304 => {
            return <http:NotModified>{body: {msg: "Not modified response"}, mediaType: "application/org+json", headers: {"x-error": "Not modified"}};
        }
        305 => {
            return <http:UseProxy>{body: {msg: "Use proxy response"}, mediaType: "application/org+json", headers: {"x-error": "Use proxy"}};
        }
        307 => {
            return <http:TemporaryRedirect>{body: {msg: "Temporary redirect response"}, mediaType: "application/org+json", headers: {"x-error": "Temporary redirect"}};
        }
        308 => {
            return <http:PermanentRedirect>{body: {msg: "Permanent redirect response"}, mediaType: "application/org+json", headers: {"x-error": "Permanent redirect"}};
        }
        400 => {
            return <http:BadRequest>{body: {msg: "Bad request error"}, mediaType: "application/org+json", headers: {"x-error": "Bad request"}};
        }
        401 => {
            return <http:Unauthorized>{body: {msg: "Unauthorized error"}, mediaType: "application/org+json", headers: {"x-error": "Unauthorized"}};
        }
        402 => {
            return <http:PaymentRequired>{body: {msg: "Payment required error"}, mediaType: "application/org+json", headers: {"x-error": "Payment required"}};
        }
        403 => {
            return <http:Forbidden>{body: {msg: "Forbidden error"}, mediaType: "application/org+json", headers: {"x-error": "Forbidden"}};
        }
        404 => {
            return <http:NotFound>{body: {msg: "Not found error"}, mediaType: "application/org+json", headers: {"x-error": "Not found"}};
        }
        405 => {
            return <http:MethodNotAllowed>{body: {msg: "Method not allowed error"}, mediaType: "application/org+json", headers: {"x-error": "Method not allowed"}};
        }
        406 => {
            return <http:NotAcceptable>{body: {msg: "Not acceptable error"}, mediaType: "application/org+json", headers: {"x-error": "Not acceptable"}};
        }
        407 => {
            return <http:ProxyAuthenticationRequired>{body: {msg: "Proxy authentication required error"}, mediaType: "application/org+json", headers: {"x-error": "Proxy authentication required"}};
        }
        408 => {
            return <http:RequestTimeout>{body: {msg: "Request timeout error"}, mediaType: "application/org+json", headers: {"x-error": "Request timeout"}};
        }
        409 => {
            return <http:Conflict>{body: {msg: "Conflict error"}, mediaType: "application/org+json", headers: {"x-error": "Conflict"}};
        }
        410 => {
            return <http:Gone>{body: {msg: "Gone error"}, mediaType: "application/org+json", headers: {"x-error": "Gone"}};
        }
        411 => {
            return <http:LengthRequired>{body: {msg: "Length required error"}, mediaType: "application/org+json", headers: {"x-error": "Length required"}};
        }
        412 => {
            return <http:PreconditionFailed>{body: {msg: "Precondition failed error"}, mediaType: "application/org+json", headers: {"x-error": "Precondition failed"}};
        }
        413 => {
            return <http:PayloadTooLarge>{body: {msg: "Payload too large error"}, mediaType: "application/org+json", headers: {"x-error": "Payload too large"}};
        }
        414 => {
            return <http:UriTooLong>{body: {msg: "URI too long error"}, mediaType: "application/org+json", headers: {"x-error": "URI too long"}};
        }
        415 => {
            return <http:UnsupportedMediaType>{body: {msg: "Unsupported media type error"}, mediaType: "application/org+json", headers: {"x-error": "Unsupported media type"}};
        }
        416 => {
            return <http:RangeNotSatisfiable>{body: {msg: "Range not satisfiable error"}, mediaType: "application/org+json", headers: {"x-error": "Range not satisfiable"}};
        }
        417 => {
            return <http:ExpectationFailed>{body: {msg: "Expectation failed error"}, mediaType: "application/org+json", headers: {"x-error": "Expectation failed"}};
        }
        421 => {
            return <http:MisdirectedRequest>{body: {msg: "Misdirected request error"}, mediaType: "application/org+json", headers: {"x-error": "Misdirected request"}};
        }
        422 => {
            return <http:UnprocessableEntity>{body: {msg: "Unprocessable entity error"}, mediaType: "application/org+json", headers: {"x-error": "Unprocessable entity"}};
        }
        423 => {
            return <http:Locked>{body: {msg: "Locked error"}, mediaType: "application/org+json", headers: {"x-error": "Locked"}};
        }
        424 => {
            return <http:FailedDependency>{body: {msg: "Failed dependency error"}, mediaType: "application/org+json", headers: {"x-error": "Failed dependency"}};
        }
        425 => {
            return <http:TooEarly>{body: {msg: "Too early error"}, mediaType: "application/org+json", headers: {"x-error": "Too early"}};
        }
        426 => {
            return <http:UpgradeRequired>{body: {msg: "Upgrade required error"}, mediaType: "application/org+json", headers: {"x-error": "Upgrade required"}};
        }
        428 => {
            return <http:PreconditionRequired>{body: {msg: "Precondition required error"}, mediaType: "application/org+json", headers: {"x-error": "Precondition required"}};
        }
        429 => {
            return <http:TooManyRequests>{body: {msg: "Too many requests error"}, mediaType: "application/org+json", headers: {"x-error": "Too many requests"}};
        }
        431 => {
            return <http:RequestHeaderFieldsTooLarge>{body: {msg: "Request header fields too large error"}, mediaType: "application/org+json", headers: {"x-error": "Request header fields too large"}};
        }
        451 => {
            return <http:UnavailableDueToLegalReasons>{body: {msg: "Unavailable for legal reasons error"}, mediaType: "application/org+json", headers: {"x-error": "Unavailable for legal reasons"}};
        }
        500 => {
            return <http:InternalServerError>{body: {msg: "Internal server error"}, mediaType: "application/org+json", headers: {"x-error": "Internal server error"}};
        }
        501 => {
            return <http:NotImplemented>{body: {msg: "Not implemented error"}, mediaType: "application/org+json", headers: {"x-error": "Not implemented"}};
        }
        502 => {
            return <http:BadGateway>{body: {msg: "Bad gateway error"}, mediaType: "application/org+json", headers: {"x-error": "Bad gateway"}};
        }
        503 => {
            return <http:ServiceUnavailable>{body: {msg: "Service unavailable error"}, mediaType: "application/org+json", headers: {"x-error": "Service unavailable"}};
        }
        504 => {
            return <http:GatewayTimeout>{body: {msg: "Gateway timeout error"}, mediaType: "application/org+json", headers: {"x-error": "Gateway timeout"}};
        }
        505 => {
            return <http:HttpVersionNotSupported>{body: {msg: "HTTP version not supported error"}, mediaType: "application/org+json", headers: {"x-error": "HTTP version not supported"}};
        }
        506 => {
            return <http:VariantAlsoNegotiates>{body: {msg: "Variant also negotiates error"}, mediaType: "application/org+json", headers: {"x-error": "Variant also negotiates"}};
        }
        507 => {
            return <http:InsufficientStorage>{body: {msg: "Insufficient storage error"}, mediaType: "application/org+json", headers: {"x-error": "Insufficient storage"}};
        }
        508 => {
            return <http:LoopDetected>{body: {msg: "Loop detected error"}, mediaType: "application/org+json", headers: {"x-error": "Loop detected"}};
        }
        510 => {
            return <http:NotExtended>{body: {msg: "Not extended error"}, mediaType: "application/org+json", headers: {"x-error": "Not extended"}};
        }
        511 => {
            return <http:NetworkAuthenticationRequired>{body: {msg: "Network authentication required error"}, mediaType: "application/org+json", headers: {"x-error": "Network authentication required"}};
        }
        _ => {
            return <http:BadRequest>{body: {msg: "Bad request with unknown status code"}, mediaType: "application/org+json", headers: {"x-error": "Unknown status code"}};
        }
    }
}

@test:Config {}
function testSCResBindingWith1XXStatusCodes() returns error? {
    http:Processing processingResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 102);
    test:assertTrue(processingResponse is http:Processing, "Response type mismatched");
    testStatusCodeResponse(processingResponse, 102, "Processing", "Processing response");

    http:EarlyHints earlyHintsResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 103);
    test:assertTrue(earlyHintsResponse is http:EarlyHints, "Response type mismatched");
    testStatusCodeResponse(earlyHintsResponse, 103, "Early hints", "Early hints response");
}

@test:Config {}
function testSCResBindingWith2XXStatusCodes() returns error? {
    http:Ok okResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 200);
    test:assertTrue(okResponse is http:Ok, "Response type mismatched");
    testStatusCodeResponse(okResponse, 200, "OK", "OK response");

    http:Created createdResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 201);
    test:assertTrue(createdResponse is http:Created, "Response type mismatched");
    testStatusCodeResponse(createdResponse, 201, "Created", "Created response");

    http:Accepted acceptedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 202);
    test:assertTrue(acceptedResponse is http:Accepted, "Response type mismatched");
    testStatusCodeResponse(acceptedResponse, 202, "Accepted", "Accepted response");

    http:NonAuthoritativeInformation nonAuthoritativeInformationResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 203);
    test:assertTrue(nonAuthoritativeInformationResponse is http:NonAuthoritativeInformation, "Response type mismatched");
    testStatusCodeResponse(nonAuthoritativeInformationResponse, 203, "Non-authoritative information", "Non-authoritative information response");

    http:NoContent noContentResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 204);
    test:assertTrue(noContentResponse is http:NoContent, "Response type mismatched");
    testStatusCodeResponse(noContentResponse, 204, "No content");

    http:ResetContent resetContentResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 205);
    test:assertTrue(resetContentResponse is http:ResetContent, "Response type mismatched");
    testStatusCodeResponse(resetContentResponse, 205, "Reset content", "Reset content response");

    http:PartialContent partialContentResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 206);
    test:assertTrue(partialContentResponse is http:PartialContent, "Response type mismatched");
    testStatusCodeResponse(partialContentResponse, 206, "Partial content", "Partial content response");

    http:MultiStatus multiStatusResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 207);
    test:assertTrue(multiStatusResponse is http:MultiStatus, "Response type mismatched");
    testStatusCodeResponse(multiStatusResponse, 207, "Multi-status", "Multi-status response");

    http:AlreadyReported alreadyReportedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 208);
    test:assertTrue(alreadyReportedResponse is http:AlreadyReported, "Response type mismatched");
    testStatusCodeResponse(alreadyReportedResponse, 208, "Already reported", "Already reported response");

    http:IMUsed imUsedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 226);
    test:assertTrue(imUsedResponse is http:IMUsed, "Response type mismatched");
    testStatusCodeResponse(imUsedResponse, 226, "IM used", "IM used response");
}

@test:Config {}
function testSCResBindingWith3XXStatusCodes() returns error? {
    http:MultipleChoices multipleChoicesResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 300);
    test:assertTrue(multipleChoicesResponse is http:MultipleChoices, "Response type mismatched");
    testStatusCodeResponse(multipleChoicesResponse, 300, "Multiple choices", "Multiple choices response");

    http:MovedPermanently movedPermanentlyResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 301);
    test:assertTrue(movedPermanentlyResponse is http:MovedPermanently, "Response type mismatched");
    testStatusCodeResponse(movedPermanentlyResponse, 301, "Moved permanently", "Moved permanently response");

    http:Found foundResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 302);
    test:assertTrue(foundResponse is http:Found, "Response type mismatched");
    testStatusCodeResponse(foundResponse, 302, "Found", "Found response");

    http:SeeOther seeOtherResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 303);
    test:assertTrue(seeOtherResponse is http:SeeOther, "Response type mismatched");
    testStatusCodeResponse(seeOtherResponse, 303, "See other", "See other response");

    http:NotModified notModifiedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 304);
    test:assertTrue(notModifiedResponse is http:NotModified, "Response type mismatched");
    testStatusCodeResponse(notModifiedResponse, 304, "Not modified", "Not modified response");

    http:UseProxy useProxyResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 305);
    test:assertTrue(useProxyResponse is http:UseProxy, "Response type mismatched");
    testStatusCodeResponse(useProxyResponse, 305, "Use proxy", "Use proxy response");

    http:TemporaryRedirect temporaryRedirectResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 307);
    test:assertTrue(temporaryRedirectResponse is http:TemporaryRedirect, "Response type mismatched");
    testStatusCodeResponse(temporaryRedirectResponse, 307, "Temporary redirect", "Temporary redirect response");

    http:PermanentRedirect permanentRedirectResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 308);
    test:assertTrue(permanentRedirectResponse is http:PermanentRedirect, "Response type mismatched");
    testStatusCodeResponse(permanentRedirectResponse, 308, "Permanent redirect", "Permanent redirect response");
}

@test:Config {}
function testSCResBindingWith4XXStatusCodes() returns error? {
    http:BadRequest badRequestResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 400);
    test:assertTrue(badRequestResponse is http:BadRequest, "Response type mismatched");
    testStatusCodeResponse(badRequestResponse, 400, "Bad request", "Bad request error");

    http:Unauthorized unauthorizedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 401);
    test:assertTrue(unauthorizedResponse is http:Unauthorized, "Response type mismatched");
    testStatusCodeResponse(unauthorizedResponse, 401, "Unauthorized", "Unauthorized error");

    http:PaymentRequired paymentRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 402);
    test:assertTrue(paymentRequiredResponse is http:PaymentRequired, "Response type mismatched");
    testStatusCodeResponse(paymentRequiredResponse, 402, "Payment required", "Payment required error");

    http:Forbidden forbiddenResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 403);
    test:assertTrue(forbiddenResponse is http:Forbidden, "Response type mismatched");
    testStatusCodeResponse(forbiddenResponse, 403, "Forbidden", "Forbidden error");

    http:NotFound notFoundResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 404);
    test:assertTrue(notFoundResponse is http:NotFound, "Response type mismatched");
    testStatusCodeResponse(notFoundResponse, 404, "Not found", "Not found error");

    http:MethodNotAllowed methodNotAllowedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 405);
    test:assertTrue(methodNotAllowedResponse is http:MethodNotAllowed, "Response type mismatched");
    testStatusCodeResponse(methodNotAllowedResponse, 405, "Method not allowed", "Method not allowed error");

    http:NotAcceptable notAcceptableResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 406);
    test:assertTrue(notAcceptableResponse is http:NotAcceptable, "Response type mismatched");
    testStatusCodeResponse(notAcceptableResponse, 406, "Not acceptable", "Not acceptable error");

    http:ProxyAuthenticationRequired proxyAuthenticationRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 407);
    test:assertTrue(proxyAuthenticationRequiredResponse is http:ProxyAuthenticationRequired, "Response type mismatched");
    testStatusCodeResponse(proxyAuthenticationRequiredResponse, 407, "Proxy authentication required", "Proxy authentication required error");

    http:RequestTimeout requestTimeoutResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 408);
    test:assertTrue(requestTimeoutResponse is http:RequestTimeout, "Response type mismatched");
    testStatusCodeResponse(requestTimeoutResponse, 408, "Request timeout", "Request timeout error");

    http:Conflict conflictResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 409);
    test:assertTrue(conflictResponse is http:Conflict, "Response type mismatched");
    testStatusCodeResponse(conflictResponse, 409, "Conflict", "Conflict error");

    http:Gone goneResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 410);
    test:assertTrue(goneResponse is http:Gone, "Response type mismatched");
    testStatusCodeResponse(goneResponse, 410, "Gone", "Gone error");

    http:LengthRequired lengthRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 411);
    test:assertTrue(lengthRequiredResponse is http:LengthRequired, "Response type mismatched");
    testStatusCodeResponse(lengthRequiredResponse, 411, "Length required", "Length required error");

    http:PreconditionFailed preconditionFailedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 412);
    test:assertTrue(preconditionFailedResponse is http:PreconditionFailed, "Response type mismatched");
    testStatusCodeResponse(preconditionFailedResponse, 412, "Precondition failed", "Precondition failed error");

    http:PayloadTooLarge payloadTooLargeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 413);
    test:assertTrue(payloadTooLargeResponse is http:PayloadTooLarge, "Response type mismatched");
    testStatusCodeResponse(payloadTooLargeResponse, 413, "Payload too large", "Payload too large error");

    http:UriTooLong uriTooLongResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 414);
    test:assertTrue(uriTooLongResponse is http:UriTooLong, "Response type mismatched");
    testStatusCodeResponse(uriTooLongResponse, 414, "URI too long", "URI too long error");

    http:UnsupportedMediaType unsupportedMediaTypeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 415);
    test:assertTrue(unsupportedMediaTypeResponse is http:UnsupportedMediaType, "Response type mismatched");
    testStatusCodeResponse(unsupportedMediaTypeResponse, 415, "Unsupported media type", "Unsupported media type error");

    http:RangeNotSatisfiable rangeNotSatisfiableResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 416);
    test:assertTrue(rangeNotSatisfiableResponse is http:RangeNotSatisfiable, "Response type mismatched");
    testStatusCodeResponse(rangeNotSatisfiableResponse, 416, "Range not satisfiable", "Range not satisfiable error");

    http:ExpectationFailed expectationFailedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 417);
    test:assertTrue(expectationFailedResponse is http:ExpectationFailed, "Response type mismatched");
    testStatusCodeResponse(expectationFailedResponse, 417, "Expectation failed", "Expectation failed error");

    http:MisdirectedRequest misdirectedRequestResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 421);
    test:assertTrue(misdirectedRequestResponse is http:MisdirectedRequest, "Response type mismatched");
    testStatusCodeResponse(misdirectedRequestResponse, 421, "Misdirected request", "Misdirected request error");

    http:UnprocessableEntity unprocessableEntityResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 422);
    test:assertTrue(unprocessableEntityResponse is http:UnprocessableEntity, "Response type mismatched");
    testStatusCodeResponse(unprocessableEntityResponse, 422, "Unprocessable entity", "Unprocessable entity error");

    http:Locked lockedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 423);
    test:assertTrue(lockedResponse is http:Locked, "Response type mismatched");
    testStatusCodeResponse(lockedResponse, 423, "Locked", "Locked error");

    http:FailedDependency failedDependencyResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 424);
    test:assertTrue(failedDependencyResponse is http:FailedDependency, "Response type mismatched");
    testStatusCodeResponse(failedDependencyResponse, 424, "Failed dependency", "Failed dependency error");

    http:TooEarly tooEarlyResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 425);
    test:assertTrue(tooEarlyResponse is http:TooEarly, "Response type mismatched");
    testStatusCodeResponse(tooEarlyResponse, 425, "Too early", "Too early error");

    http:UpgradeRequired upgradeRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 426);
    test:assertTrue(upgradeRequiredResponse is http:UpgradeRequired, "Response type mismatched");
    testStatusCodeResponse(upgradeRequiredResponse, 426, "Upgrade required", "Upgrade required error");

    http:PreconditionRequired preconditionRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 428);
    test:assertTrue(preconditionRequiredResponse is http:PreconditionRequired, "Response type mismatched");
    testStatusCodeResponse(preconditionRequiredResponse, 428, "Precondition required", "Precondition required error");

    http:TooManyRequests tooManyRequestsResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 429);
    test:assertTrue(tooManyRequestsResponse is http:TooManyRequests, "Response type mismatched");
    testStatusCodeResponse(tooManyRequestsResponse, 429, "Too many requests", "Too many requests error");

    http:RequestHeaderFieldsTooLarge requestHeaderFieldsTooLargeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 431);
    test:assertTrue(requestHeaderFieldsTooLargeResponse is http:RequestHeaderFieldsTooLarge, "Response type mismatched");
    testStatusCodeResponse(requestHeaderFieldsTooLargeResponse, 431, "Request header fields too large", "Request header fields too large error");

    http:UnavailableDueToLegalReasons unavailableDueToLegalReasonsResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 451);
    test:assertTrue(unavailableDueToLegalReasonsResponse is http:UnavailableDueToLegalReasons, "Response type mismatched");
    testStatusCodeResponse(unavailableDueToLegalReasonsResponse, 451, "Unavailable for legal reasons", "Unavailable for legal reasons error");
}

@test:Config {}
function testSCResBindingWith5XXStatusCodes() returns error? {
    http:InternalServerError internalServerErrorResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 500);
    test:assertTrue(internalServerErrorResponse is http:InternalServerError, "Response type mismatched");
    testStatusCodeResponse(internalServerErrorResponse, 500, "Internal server error", "Internal server error");

    http:NotImplemented notImplementedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 501);
    test:assertTrue(notImplementedResponse is http:NotImplemented, "Response type mismatched");
    testStatusCodeResponse(notImplementedResponse, 501, "Not implemented", "Not implemented error");

    http:BadGateway badGatewayResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 502);
    test:assertTrue(badGatewayResponse is http:BadGateway, "Response type mismatched");
    testStatusCodeResponse(badGatewayResponse, 502, "Bad gateway", "Bad gateway error");

    http:ServiceUnavailable serviceUnavailableResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 503);
    test:assertTrue(serviceUnavailableResponse is http:ServiceUnavailable, "Response type mismatched");
    testStatusCodeResponse(serviceUnavailableResponse, 503, "Service unavailable", "Service unavailable error");

    http:GatewayTimeout gatewayTimeoutResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 504);
    test:assertTrue(gatewayTimeoutResponse is http:GatewayTimeout, "Response type mismatched");
    testStatusCodeResponse(gatewayTimeoutResponse, 504, "Gateway timeout", "Gateway timeout error");

    http:HttpVersionNotSupported httpVersionNotSupportedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 505);
    test:assertTrue(httpVersionNotSupportedResponse is http:HttpVersionNotSupported, "Response type mismatched");
    testStatusCodeResponse(httpVersionNotSupportedResponse, 505, "HTTP version not supported", "HTTP version not supported error");

    http:VariantAlsoNegotiates variantAlsoNegotiatesResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 506);
    test:assertTrue(variantAlsoNegotiatesResponse is http:VariantAlsoNegotiates, "Response type mismatched");
    testStatusCodeResponse(variantAlsoNegotiatesResponse, 506, "Variant also negotiates", "Variant also negotiates error");

    http:InsufficientStorage insufficientStorageResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 507);
    test:assertTrue(insufficientStorageResponse is http:InsufficientStorage, "Response type mismatched");
    testStatusCodeResponse(insufficientStorageResponse, 507, "Insufficient storage", "Insufficient storage error");

    http:LoopDetected loopDetectedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 508);
    test:assertTrue(loopDetectedResponse is http:LoopDetected, "Response type mismatched");
    testStatusCodeResponse(loopDetectedResponse, 508, "Loop detected", "Loop detected error");

    http:NotExtended notExtendedResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 510);
    test:assertTrue(notExtendedResponse is http:NotExtended, "Response type mismatched");
    testStatusCodeResponse(notExtendedResponse, 510, "Not extended", "Not extended error");

    http:NetworkAuthenticationRequired networkAuthenticationRequiredResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 511);
    test:assertTrue(networkAuthenticationRequiredResponse is http:NetworkAuthenticationRequired, "Response type mismatched");
    testStatusCodeResponse(networkAuthenticationRequiredResponse, 511, "Network authentication required", "Network authentication required error");

    http:BadRequest badRequestWithUnknownStatusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 999);
    test:assertTrue(badRequestWithUnknownStatusCodeResponse is http:BadRequest, "Response type mismatched");
    testStatusCodeResponse(badRequestWithUnknownStatusCodeResponse, 400, "Unknown status code", "Bad request with unknown status code");
}

@test:Config {}
function testSCResBindingWithCommonType() returns error? {
    http:StatusCodeResponse statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 103);
    test:assertTrue(statusCodeResponse is http:EarlyHints, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 103, "Early hints", "Early hints response");

    statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 201);
    test:assertTrue(statusCodeResponse is http:Created, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 201, "Created", "Created response");

    statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 204);
    test:assertTrue(statusCodeResponse is http:NoContent, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 204, "No content");

    statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 304);
    test:assertTrue(statusCodeResponse is http:NotModified, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 304, "Not modified", "Not modified response");

    statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 405);
    test:assertTrue(statusCodeResponse is http:MethodNotAllowed, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 405, "Method not allowed", "Method not allowed error");

    statusCodeResponse = check statusCodeBindingClient1->/api/status\-code\-response(code = 504);
    test:assertTrue(statusCodeResponse is http:GatewayTimeout, "Response type mismatched");
    testStatusCodeResponse(statusCodeResponse, 504, "Gateway timeout", "Gateway timeout error");
}

function testStatusCodeResponse(http:StatusCodeResponse statusCodeResponse, int statusCode, string header, string? body = ()) {
    test:assertEquals(statusCodeResponse.status.code, statusCode, "Status code mismatched");
    test:assertEquals(statusCodeResponse.headers["x-error"], header, "Header mismatched");
    if body is string {
        test:assertEquals(statusCodeResponse?.body, {msg: body}, "Response body mismatched");
        test:assertEquals(statusCodeResponse?.mediaType, "application/org+json", "Media type mismatched");
    }
}
