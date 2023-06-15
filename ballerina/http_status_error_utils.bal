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

import http.httpscerr;
import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/time;

# Represents the structure of the HTTP error payload.
#
# + timestamp - Timestamp of the error
# + status - Relevant HTTP status code
# + reason - Reason phrase
# + message - Error message
# + path - Request path
# + method - Method type of the request
public type ErrorPayload record {
    string timestamp;
    int status;
    string reason;
    string message;
    string path;
    string method;
};

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

    if err !is httpscerr:StatusCodeError {
        setPayload(err.message(), response, returnMediaType);
        return response;
    }

    if err !is NoContentError {
        anydata body = err.detail()?.body ?: err.message();
        setPayload(body, response, returnMediaType);
    }

    map<string|string[]> headers = err.detail().headers ?: {};
    setHeaders(headers, response);

    return response;
}

isolated function getErrorResponseForInterceptor(error err, Request request) returns Response {
    Response response = new;

    if err is ApplicationResponseError {
        response.statusCode = err.detail().statusCode;
        if err.detail().body is () {
            setErrorPayload(err, request, response);
        } else {
            setPayload(err.detail().body, response);
        }
        setHeaders(err.detail().headers, response);
        return response;
    }

    response.statusCode = getStatusCode(err);

    if err !is httpscerr:StatusCodeError {
        setErrorPayload(err, request, response);
        return response;
    }

    if err.detail()?.body is () {
        setErrorPayload(err, request, response);
        if err.detail()?.headers !is () {
            setHeaders(<map<string|string[]>>err.detail()?.headers, response);
        }
        return response;
    }

    if err !is NoContentError {
        if err.detail()?.body is () {
            setErrorPayload(err, request, response);
        } else {
            setPayload(err.detail()?.body, response);
        }
    }

    map<string|string[]> headers = err.detail().headers ?: {};
    setHeaders(headers, response);

    return response;
}

isolated function setErrorPayload(error err, Request request, Response response) {
    ErrorPayload errorPayload = {
        timestamp: time:utcToString(time:utcNow()),
        status: response.statusCode,
        reason: externGetReasonFromStatusCode(response.statusCode),
        message: err.message(),
        path: request.rawPath,
        method: request.method
    };
    response.setPayload(errorPayload.toJson(), mime:APPLICATION_JSON);
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

isolated function getStatusCode(error err) returns int {
    if err is httpscerr:BadRequestError {
        return 400;
    } else if err is httpscerr:UnauthorizedError {
        return 401;
    } else if err is httpscerr:PaymentRequiredError {
        return 402;
    } else if err is httpscerr:ForbiddenError {
        return 403;
    } else if err is httpscerr:NotFoundError {
        return 404;
    } else if err is httpscerr:MethodNotAllowedError {
        return 405;
    } else if err is httpscerr:NotAcceptableError {
        return 406;
    } else if err is httpscerr:ProxyAuthenticationRequiredError {
        return 407;
    } else if err is httpscerr:RequestTimeoutError {
        return 408;
    } else if err is httpscerr:ConflictError {
        return 409;
    } else if err is httpscerr:GoneError {
        return 410;
    } else if err is httpscerr:LengthRequiredError {
        return 411;
    } else if err is httpscerr:PreconditionFailedError {
        return 412;
    } else if err is httpscerr:PayloadTooLargeError {
        return 413;
    } else if err is httpscerr:URITooLongError {
        return 414;
    } else if err is httpscerr:UnsupportedMediaTypeError {
        return 415;
    } else if err is httpscerr:RangeNotSatisfiableError {
        return 416;
    } else if err is httpscerr:ExpectationFailedError {
        return 417;
    } else if err is httpscerr:MisdirectedRequestError {
        return 421;
    } else if err is httpscerr:UnprocessableEntityError {
        return 422;
    } else if err is httpscerr:LockedError {
        return 423;
    } else if err is httpscerr:FailedDependencyError {
        return 424;
    } else if err is httpscerr:UpgradeRequiredError {
        return 426;
    } else if err is httpscerr:PreconditionRequiredError {
        return 428;
    } else if err is httpscerr:TooManyRequestsError {
        return 429;
    } else if err is httpscerr:RequestHeaderFieldsTooLargeError {
        return 431;
    } else if err is httpscerr:UnavailableDueToLegalReasonsError {
        return 451;
    } else if err is httpscerr:InternalServerErrorError {
        return 500;
    } else if err is httpscerr:NotImplementedError {
        return 501;
    } else if err is httpscerr:BadGatewayError {
        return 502;
    } else if err is httpscerr:ServiceUnavailableError {
        return 503;
    } else if err is httpscerr:GatewayTimeoutError {
        return 504;
    } else if err is httpscerr:HTTPVersionNotSupportedError {
        return 505;
    } else if err is httpscerr:VariantAlsoNegotiatesError {
        return 506;
    } else if err is httpscerr:InsufficientStorageError {
        return 507;
    } else if err is httpscerr:LoopDetectedError {
        return 508;
    } else if err is httpscerr:NotExtendedError {
        return 510;
    } else if err is httpscerr:NetworkAuthenticationRequiredError {
        return 511;
    } else if err is httpscerr:DefaultStatusCodeError {
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

isolated function externGetReasonFromStatusCode(int statusCode) returns string =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternUtils",
    name: "getReasonFromStatusCode"
} external;
