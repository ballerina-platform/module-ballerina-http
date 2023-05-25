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

import ballerina/jballerina.java;
import ballerina/mime;
import ballerina/time;

# Represents the details of an HTTP error.
#
# + headers - The error response headers
# + body - The error response body
public type ErrorDetail record {
    map<string|string[]> headers?;
    anydata body?;
};

# Represents the details of an HTTP error.
#
# + statusCode - The inbound error response status code
public type DefaultErrorDetail record {
    *ErrorDetail;
    int statusCode?;
};

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

# Represents the HTTP status code error.
public type StatusCodeError distinct error<ErrorDetail>;

# Represents 4XX HTTP status code errors.
public type '4XXStatusCodeError distinct StatusCodeError;

# Represents 5XX HTTP status code errors.
public type '5XXStatusCodeError distinct StatusCodeError;

# Represents the default HTTP status code error.
public type DefaultStatusCodeError distinct StatusCodeError & error<DefaultErrorDetail>;

# Represents the HTTP 400 Bad Request error.
public type BadRequestError distinct '4XXStatusCodeError;

# Represents the HTTP 401 Unauthorized error.
public type UnauthorizedError distinct '4XXStatusCodeError;

# Represents the HTTP 402 Payment Required error.
public type PaymentRequiredError distinct '4XXStatusCodeError;

# Represents the HTTP 403 Forbidden error.
public type ForbiddenError distinct '4XXStatusCodeError;

# Represents the HTTP 404 Not Found error.
public type NotFoundError distinct '4XXStatusCodeError;

# Represents the HTTP 405 Method Not Allowed error.
public type MethodNotAllowedError distinct '4XXStatusCodeError;

# Represents the HTTP 406 Not Acceptable error.
public type NotAcceptableError distinct '4XXStatusCodeError;

# Represents the HTTP 407 Proxy Authentication Required error.
public type ProxyAuthenticationRequiredError distinct '4XXStatusCodeError;

# Represents the HTTP 408 Request Timeout error.
public type RequestTimeoutError distinct '4XXStatusCodeError;

# Represents the HTTP 409 Conflict error.
public type ConflictError distinct '4XXStatusCodeError;

# Represents the HTTP 410 Gone error.
public type GoneError distinct '4XXStatusCodeError;

# Represents the HTTP 411 Length Required error.
public type LengthRequiredError distinct '4XXStatusCodeError;

# Represents the HTTP 412 Precondition Failed error.
public type PreconditionFailedError distinct '4XXStatusCodeError;

# Represents the HTTP 413 Payload Too Large error.
public type PayloadTooLargeError distinct '4XXStatusCodeError;

# Represents the HTTP 414 URI Too Long error.
public type URITooLongError distinct '4XXStatusCodeError;

# Represents the HTTP 415 Unsupported Media Type error.
public type UnsupportedMediaTypeError distinct '4XXStatusCodeError;

# Represents the HTTP 416 Range Not Satisfiable error.
public type RangeNotSatisfiableError distinct '4XXStatusCodeError;

# Represents the HTTP 417 Expectation Failed error.
public type ExpectationFailedError distinct '4XXStatusCodeError;

# Represents the HTTP 421 Misdirected Request error.
public type MisdirectedRequestError distinct '4XXStatusCodeError;

# Represents the HTTP 422 Unprocessable Entity error.
public type UnprocessableEntityError distinct '4XXStatusCodeError;

# Represents the HTTP 423 Locked error.
public type LockedError distinct '4XXStatusCodeError;

# Represents the HTTP 424 Failed Dependency error.
public type FailedDependencyError distinct '4XXStatusCodeError;

# Represents the HTTP 426 Upgrade Required error.
public type UpgradeRequiredError distinct '4XXStatusCodeError;

# Represents the HTTP 428 Precondition Required error.
public type PreconditionRequiredError distinct '4XXStatusCodeError;

# Represents the HTTP 429 Too Many Requests error.
public type TooManyRequestsError distinct '4XXStatusCodeError;

# Represents the HTTP 431 Request Header Fields Too Large error.
public type RequestHeaderFieldsTooLargeError distinct '4XXStatusCodeError;

# Represents the HTTP 451 Unavailable For Legal Reasons error.
public type UnavailableDueToLegalReasonsError distinct '4XXStatusCodeError;

# Represents the HTTP 500 Internal Server Error error.
public type InternalServerErrorError distinct '5XXStatusCodeError;

# Represents the HTTP 501 Not Implemented error.
public type NotImplementedError distinct '5XXStatusCodeError;

# Represents the HTTP 502 Bad Gateway error.
public type BadGatewayError distinct '5XXStatusCodeError;

# Represents the HTTP 503 Service Unavailable error.
public type ServiceUnavailableError distinct '5XXStatusCodeError;

# Represents the HTTP 504 Gateway Timeout error.
public type GatewayTimeoutError distinct '5XXStatusCodeError;

# Represents the HTTP 505 HTTP Version Not Supported error.
public type HTTPVersionNotSupportedError distinct '5XXStatusCodeError;

# Represents the HTTP 506 Variant Also Negotiates error.
public type VariantAlsoNegotiatesError distinct '5XXStatusCodeError;

# Represents the HTTP 507 Insufficient Storage error.
public type InsufficientStorageError distinct '5XXStatusCodeError;

# Represents the HTTP 508 Loop Detected error.
public type LoopDetectedError distinct '5XXStatusCodeError;

# Represents the HTTP 510 Not Extended error.
public type NotExtendedError distinct '5XXStatusCodeError;

# Represents the HTTP 511 Network Authentication Required error.
public type NetworkAuthenticationRequiredError distinct '5XXStatusCodeError;

# Represents Service Not Found error.
public type ServiceNotFoundError NotFoundError & ServiceDispatchingError;

# Represents Bad Matrix Parameter in the request error.
public type BadMatrixParamError BadRequestError & ServiceDispatchingError;

# Represents an error, which occurred when the resource is not found during dispatching.
public type ResourceNotFoundError NotFoundError & ResourceDispatchingError;

# Represents an error, which occurred due to a path parameter constraint validation.
public type ResourcePathValidationError BadRequestError & ResourceDispatchingError;

# Represents an error, which occurred when the resource method is not allowed during dispatching.
public type ResourceMethodNotAllowedError MethodNotAllowedError & ResourceDispatchingError;

# Represents an error, which occurred when the media type is not supported during dispatching.
public type UnsupportedRequestMediaTypeError UnsupportedMediaTypeError & ResourceDispatchingError;

# Represents an error, which occurred when the payload is not acceptable during dispatching.
public type RequestNotAcceptableError NotAcceptableError & ResourceDispatchingError;

# Represents other internal server errors during dispatching.
public type ResourceDispatchingServerError InternalServerErrorError & ResourceDispatchingError;

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

    if err !is StatusCodeError {
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

    // Handling the client errors
    if err is ApplicationResponseError {
        response.statusCode = err.detail().statusCode;
        setErrorPayload(err, request, response);
        setHeaders(err.detail().headers, response);
        return response;
    }

    // Handling the server errors
    response.statusCode = getStatusCode(err);

    if err !is StatusCodeError {
        setErrorPayload(err, request, response);
        return response;
    }

    if err !is NoContentError {
        setErrorPayload(err, request, response);
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
    if err is BadRequestError {
        return 400;
    } else if err is UnauthorizedError {
        return 401;
    } else if err is PaymentRequiredError {
        return 402;
    } else if err is ForbiddenError {
        return 403;
    } else if err is NotFoundError {
        return 404;
    } else if err is MethodNotAllowedError {
        return 405;
    } else if err is NotAcceptableError {
        return 406;
    } else if err is ProxyAuthenticationRequiredError {
        return 407;
    } else if err is RequestTimeoutError {
        return 408;
    } else if err is ConflictError {
        return 409;
    } else if err is GoneError {
        return 410;
    } else if err is LengthRequiredError {
        return 411;
    } else if err is PreconditionFailedError {
        return 412;
    } else if err is PayloadTooLargeError {
        return 413;
    } else if err is URITooLongError {
        return 414;
    } else if err is UnsupportedMediaTypeError {
        return 415;
    } else if err is RangeNotSatisfiableError {
        return 416;
    } else if err is ExpectationFailedError {
        return 417;
    } else if err is MisdirectedRequestError {
        return 421;
    } else if err is UnprocessableEntityError {
        return 422;
    } else if err is LockedError {
        return 423;
    } else if err is FailedDependencyError {
        return 424;
    } else if err is UpgradeRequiredError {
        return 426;
    } else if err is PreconditionRequiredError {
        return 428;
    } else if err is TooManyRequestsError {
        return 429;
    } else if err is RequestHeaderFieldsTooLargeError {
        return 431;
    } else if err is UnavailableDueToLegalReasonsError {
        return 451;
    } else if err is InternalServerErrorError {
        return 500;
    } else if err is NotImplementedError {
        return 501;
    } else if err is BadGatewayError {
        return 502;
    } else if err is ServiceUnavailableError {
        return 503;
    } else if err is GatewayTimeoutError {
        return 504;
    } else if err is HTTPVersionNotSupportedError {
        return 505;
    } else if err is VariantAlsoNegotiatesError {
        return 506;
    } else if err is InsufficientStorageError {
        return 507;
    } else if err is LoopDetectedError {
        return 508;
    } else if err is NotExtendedError {
        return 510;
    } else if err is NetworkAuthenticationRequiredError {
        return 511;
    } else if err is DefaultStatusCodeError {
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
