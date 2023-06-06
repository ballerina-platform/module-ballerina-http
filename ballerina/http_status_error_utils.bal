// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import http.http_status;

isolated function getErrorResponse(error err, string? returnMediaType = ()) returns Response {
    Response response = new;
    
    // Handling the client errors
    if err is ApplicationResponseError {
        response.statusCode = err.detail().statusCode;
        setPayload(err.detail().body, response, returnMediaType);
        setHeaders(err.detail().headers, response);
        return response;
    }

    // Handling the server errors
    response.statusCode = getStatusCode(err);

    if err !is http_status:StatusCodeError {
        setPayload(err.message(), response, returnMediaType);
        return response;
    }

    if err !is NoContentError {
        // TODO: Change after this fix: https://github.com/ballerina-platform/ballerina-lang/issues/39669
        // response.body = err.detail()?.body ?: err.message();
        anydata body = err.detail()?.body is () ? err.message() : err.detail()?.body;
        setPayload(body, response, returnMediaType);
    }

    map<string|string[]> headers = err.detail().headers ?: {};
    setHeaders(headers, response);

    return response;
}

isolated function setHeaders(map<string|string[]> headers, Response response) {
    foreach var [key, values] in headers.entries() {
        if values is string[] {
            foreach var value in values {
                response.addHeader(key, value);
            }
            continue;
        }
        response.setHeader(key, values);
    }
}

isolated function getStatusCode(error err) returns int{
    if err is http_status:BadRequestError {
        return 400;
    } else if err is http_status:UnauthorizedError {
        return 401;
    } else if err is http_status:PaymentRequiredError {
        return 402;
    } else if err is http_status:ForbiddenError {
        return 403;
    } else if err is http_status:NotFoundError {
        return 404;
    } else if err is http_status:MethodNotAllowedError {
        return 405;
    } else if err is http_status:NotAcceptableError {
        return 406;
    } else if err is http_status:ProxyAuthenticationRequiredError {
        return 407;
    } else if err is http_status:RequestTimeoutError {
        return 408;
    } else if err is http_status:ConflictError {
        return 409;
    } else if err is http_status:GoneError {
        return 410;
    } else if err is http_status:LengthRequiredError {
        return 411;
    } else if err is http_status:PreconditionFailedError {
        return 412;
    } else if err is http_status:PayloadTooLargeError {
        return 413;
    } else if err is http_status:URITooLongError {
        return 414;
    } else if err is http_status:UnsupportedMediaTypeError {
        return 415;
    } else if err is http_status:RangeNotSatisfiableError {
        return 416;
    } else if err is http_status:ExpectationFailedError {
        return 417;
    } else if err is http_status:MisdirectedRequestError {
        return 421;
    } else if err is http_status:UnprocessableEntityError {
        return 422;
    } else if err is http_status:LockedError {
        return 423;
    } else if err is http_status:FailedDependencyError {
        return 424;
    } else if err is http_status:UpgradeRequiredError {
        return 426;
    } else if err is http_status:PreconditionRequiredError {
        return 428;
    } else if err is http_status:TooManyRequestsError {
        return 429;
    } else if err is http_status:RequestHeaderFieldsTooLargeError {
        return 431;
    } else if err is http_status:UnavailableDueToLegalReasonsError {
        return 451;
    } else if err is http_status:InternalServerErrorError {
        return 500;
    } else if err is http_status:NotImplementedError {
        return 501;
    } else if err is http_status:BadGatewayError {
        return 502;
    } else if err is http_status:ServiceUnavailableError {
        return 503;
    } else if err is http_status:GatewayTimeoutError {
        return 504;
    } else if err is http_status:HTTPVersionNotSupportedError {
        return 505;
    } else if err is http_status:VariantAlsoNegotiatesError {
        return 506;
    } else if err is http_status:InsufficientStorageError {
        return 507;
    } else if err is http_status:LoopDetectedError {
        return 508;
    } else if err is http_status:NotExtendedError {
        return 510;
    } else if err is http_status:NetworkAuthenticationRequiredError {
        return 511;
    } else if err is http_status:DefaultStatusCodeError {
        int? statusCode = err.detail().statusCode;
        if statusCode is int {
            return statusCode;
        }
        error? cause = err.cause();
        if cause is error {
            return getStatusCode(cause);
        }
    }
    // All other errors are default to InternalServerError
    return 500;
}
