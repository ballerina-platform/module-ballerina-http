// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Defines the possible Status code response record types.
public type StatusCodeResponse Continue|SwitchingProtocols|Ok|Created|Accepted|NonAuthoritativeInformation|NoContent|
    ResetContent|PartialContent|MultipleChoices|MovedPermanently|Found|SeeOther|NotModified|UseProxy|TemporaryRedirect|
    PermanentRedirect|BadRequest|Unauthorized|PaymentRequired|Forbidden|NotFound|MethodNotAllowed|NotAcceptable|
    ProxyAuthenticationRequired|RequestTimeout|Conflict|Gone|LengthRequired|PreconditionFailed|PayloadTooLarge|
    UriTooLong|UnsupportedMediaType|RangeNotSatisfiable|ExpectationFailed|UpgradeRequired|RequestHeaderFieldsTooLarge|
    InternalServerError|NotImplemented|BadGateway|ServiceUnavailable|GatewayTimeout|HttpVersionNotSupported;

# The `Status` object creates the distinction for the different response status code types.
#
# + code - The response status code
type Status distinct object {
    public int code;
};

# The common attributed of response status code record type.
#
# + mediaType - The value of response `Content-type` header
# + headers - The response headers
# + body - The response payload
type CommonResponse record {|
    string mediaType?;
    map<string|string[]> headers?;
    anydata body?;
|};

// Status code class declarations
public readonly class StatusContinue {
    *Status;
    public STATUS_CONTINUE code = STATUS_CONTINUE;
}

public readonly class StatusSwitchingProtocols {
    *Status;
    public STATUS_SWITCHING_PROTOCOLS code = STATUS_SWITCHING_PROTOCOLS;
}

public readonly class StatusOK {
    *Status;
    public STATUS_OK code = STATUS_OK;
}

public readonly class StatusCreated {
    *Status;
    public STATUS_CREATED code = STATUS_CREATED;
}

public readonly class StatusAccepted {
    *Status;
    public STATUS_ACCEPTED code = STATUS_ACCEPTED;
}

public readonly class StatusNonAuthoritativeInformation {
    *Status;
    public STATUS_NON_AUTHORITATIVE_INFORMATION code = STATUS_NON_AUTHORITATIVE_INFORMATION;
}

public readonly class StatusNoContent {
    *Status;
    public STATUS_NO_CONTENT code = STATUS_NO_CONTENT;
}

public readonly class StatusResetContent {
    *Status;
    public STATUS_RESET_CONTENT code = STATUS_RESET_CONTENT;
}

public readonly class StatusPartialContent {
    *Status;
    public STATUS_PARTIAL_CONTENT code = STATUS_PARTIAL_CONTENT;
}

public readonly class StatusMultipleChoices {
    *Status;
    public STATUS_MULTIPLE_CHOICES code = STATUS_MULTIPLE_CHOICES;
}

public readonly class StatusMovedPermanently {
    *Status;
    public STATUS_MOVED_PERMANENTLY code = STATUS_MOVED_PERMANENTLY;
}

public readonly class StatusFound {
    *Status;
    public STATUS_FOUND code = STATUS_FOUND;
}

public readonly class StatusSeeOther {
    *Status;
    public STATUS_SEE_OTHER code = STATUS_SEE_OTHER;
}

public readonly class StatusNotModified {
    *Status;
    public STATUS_NOT_MODIFIED code = STATUS_NOT_MODIFIED;
}

public readonly class StatusUseProxy {
    *Status;
    public STATUS_USE_PROXY code = STATUS_USE_PROXY;
}

public readonly class StatusTemporaryRedirect {
    *Status;
    public STATUS_TEMPORARY_REDIRECT code = STATUS_TEMPORARY_REDIRECT;
}

public readonly class StatusPermanentRedirect {
    *Status;
    public STATUS_PERMANENT_REDIRECT code = STATUS_PERMANENT_REDIRECT;
}

public readonly class StatusBadRequest {
    *Status;
    public STATUS_BAD_REQUEST code = STATUS_BAD_REQUEST;
}

public readonly class StatusUnauthorized {
    *Status;
    public STATUS_UNAUTHORIZED code = STATUS_UNAUTHORIZED;
}

public readonly class StatusPaymentRequired {
    *Status;
    public STATUS_PAYMENT_REQUIRED code = STATUS_PAYMENT_REQUIRED;
}

public readonly class StatusForbidden {
    *Status;
    public STATUS_FORBIDDEN code = STATUS_FORBIDDEN;
}

public readonly class StatusNotFound {
    *Status;
    public STATUS_NOT_FOUND code = STATUS_NOT_FOUND;
}

public readonly class StatusMethodNotAllowed {
    *Status;
    public STATUS_METHOD_NOT_ALLOWED code = STATUS_METHOD_NOT_ALLOWED;
}

public readonly class StatusNotAcceptable {
    *Status;
    public STATUS_NOT_ACCEPTABLE code = STATUS_NOT_ACCEPTABLE;
}

public readonly class StatusProxyAuthenticationRequired {
    *Status;
    public STATUS_PROXY_AUTHENTICATION_REQUIRED code = STATUS_PROXY_AUTHENTICATION_REQUIRED;
}

public readonly class StatusRequestTimeout {
    *Status;
    public STATUS_REQUEST_TIMEOUT code = STATUS_REQUEST_TIMEOUT;
}

public readonly class StatusConflict {
    *Status;
    public STATUS_CONFLICT code = STATUS_CONFLICT;
}

public readonly class StatusGone {
    *Status;
    public STATUS_GONE code = STATUS_GONE;
}

public readonly class StatusLengthRequired {
    *Status;
    public STATUS_LENGTH_REQUIRED code = STATUS_LENGTH_REQUIRED;
}

public readonly class StatusPreconditionFailed {
    *Status;
    public STATUS_PRECONDITION_FAILED code = STATUS_PRECONDITION_FAILED;
}

public readonly class StatusPayloadTooLarge {
    *Status;
    public STATUS_PAYLOAD_TOO_LARGE code = STATUS_PAYLOAD_TOO_LARGE;
}

public readonly class StatusUriTooLong {
    *Status;
    public STATUS_URI_TOO_LONG code = STATUS_URI_TOO_LONG;
}

public readonly class StatusUnsupportedMediaType {
    *Status;
    public STATUS_UNSUPPORTED_MEDIA_TYPE code = STATUS_UNSUPPORTED_MEDIA_TYPE;
}

public readonly class StatusRangeNotSatisfiable {
    *Status;
    public STATUS_RANGE_NOT_SATISFIABLE code = STATUS_RANGE_NOT_SATISFIABLE;
}

public readonly class StatusExpectationFailed {
    *Status;
    public STATUS_EXPECTATION_FAILED code = STATUS_EXPECTATION_FAILED;
}

public readonly class StatusUpgradeRequired {
    *Status;
    public STATUS_UPGRADE_REQUIRED code = STATUS_UPGRADE_REQUIRED;
}

public readonly class StatusRequestHeaderFieldsTooLarge {
    *Status;
    public STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE code = STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE;
}

public readonly class StatusInternalServerError {
    *Status;
    public STATUS_INTERNAL_SERVER_ERROR code = STATUS_INTERNAL_SERVER_ERROR;
}

public readonly class StatusNotImplemented {
    *Status;
    public STATUS_NOT_IMPLEMENTED code = STATUS_NOT_IMPLEMENTED;
}

public readonly class StatusBadGateway {
    *Status;
    public STATUS_BAD_GATEWAY code = STATUS_BAD_GATEWAY;
}

public readonly class StatusServiceUnavailable {
    *Status;
    public STATUS_SERVICE_UNAVAILABLE code = STATUS_SERVICE_UNAVAILABLE;
}

public readonly class StatusGatewayTimeout {
    *Status;
    public STATUS_GATEWAY_TIMEOUT code = STATUS_GATEWAY_TIMEOUT;
}

public readonly class StatusHttpVersionNotSupported {
    *Status;
    public STATUS_HTTP_VERSION_NOT_SUPPORTED code = STATUS_HTTP_VERSION_NOT_SUPPORTED;
}

// Status code object initialization
final StatusContinue STATUS_CONTINUE_OBJ = new;
final StatusSwitchingProtocols STATUS_SWITCHING_PROTOCOLS_OBJ = new;
final StatusOK STATUS_OK_OBJ = new;
final StatusCreated STATUS_CREATED_OBJ = new;
final StatusAccepted STATUS_ACCEPTED_OBJ = new;
final StatusNonAuthoritativeInformation STATUS_NON_AUTHORITATIVE_INFORMATION_OBJ = new;
final StatusNoContent STATUS_NO_CONTENT_OBJ = new;
final StatusResetContent STATUS_RESET_CONTENT_OBJ = new;
final StatusPartialContent STATUS_PARTIAL_CONTENT_OBJ = new;
final StatusMultipleChoices STATUS_MULTIPLE_CHOICES_OBJ = new;
final StatusMovedPermanently STATUS_MOVED_PERMANENTLY_OBJ = new;
final StatusFound STATUS_FOUND_OBJ = new;
final StatusSeeOther STATUS_SEE_OTHER_OBJ = new;
final StatusNotModified STATUS_NOT_MODIFIED_OBJ = new;
final StatusUseProxy STATUS_USE_PROXY_OBJ = new;
final StatusTemporaryRedirect STATUS_TEMPORARY_REDIRECT_OBJ = new;
final StatusPermanentRedirect STATUS_PERMANENT_REDIRECT_OBJ = new;
final StatusBadRequest STATUS_BAD_REQUEST_OBJ = new;
final StatusUnauthorized STATUS_UNAUTHORIZED_OBJ = new;
final StatusPaymentRequired STATUS_PAYMENT_REQUIRED_OBJ = new;
final StatusForbidden STATUS_FORBIDDEN_OBJ = new;
final StatusNotFound STATUS_NOT_FOUND_OBJ = new;
final StatusMethodNotAllowed STATUS_METHOD_NOT_ALLOWED_OBJ = new;
final StatusNotAcceptable STATUS_NOT_ACCEPTABLE_OBJ = new;
final StatusProxyAuthenticationRequired STATUS_PROXY_AUTHENTICATION_REQUIRED_OBJ = new;
final StatusRequestTimeout STATUS_REQUEST_TIMEOUT_OBJ = new;
final StatusConflict STATUS_CONFLICT_OBJ = new;
final StatusGone STATUS_GONE_OBJ = new;
final StatusLengthRequired STATUS_LENGTH_REQUIRED_OBJ = new;
final StatusPreconditionFailed STATUS_PRECONDITION_FAILED_OBJ = new;
final StatusPayloadTooLarge STATUS_PAYLOAD_TOO_LARGE_OBJ = new;
final StatusUriTooLong STATUS_URI_TOO_LONG_OBJ = new;
final StatusUnsupportedMediaType STATUS_UNSUPPORTED_MEDIA_TYPE_OBJ = new;
final StatusRangeNotSatisfiable STATUS_RANGE_NOT_SATISFIABLE_OBJ = new;
final StatusExpectationFailed STATUS_EXPECTATION_FAILED_OBJ = new;
final StatusUpgradeRequired STATUS_UPGRADE_REQUIRED_OBJ = new;
final StatusRequestHeaderFieldsTooLarge STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE_OBJ = new;
final StatusInternalServerError STATUS_INTERNAL_SERVER_ERROR_OBJ = new;
final StatusNotImplemented STATUS_NOT_IMPLEMENTED_OBJ = new;
final StatusBadGateway STATUS_BAD_GATEWAY_OBJ = new;
final StatusServiceUnavailable STATUS_SERVICE_UNAVAILABLE_OBJ = new;
final StatusGatewayTimeout STATUS_GATEWAY_TIMEOUT_OBJ = new;
final StatusHttpVersionNotSupported STATUS_HTTP_VERSION_NOT_SUPPORTED_OBJ = new;

// Status code record types
public type Continue record {
    *CommonResponse;
    readonly StatusContinue status = STATUS_CONTINUE_OBJ;
};

public type SwitchingProtocols record {
    *CommonResponse;
    readonly StatusSwitchingProtocols status = STATUS_SWITCHING_PROTOCOLS_OBJ;
};

public type Ok record {
    *CommonResponse;
    readonly StatusOK status = STATUS_OK_OBJ;
};

public type Created record {
    *CommonResponse;
    readonly StatusCreated status = STATUS_CREATED_OBJ;
};

public type Accepted record {
    *CommonResponse;
    readonly StatusAccepted status = STATUS_ACCEPTED_OBJ;
};

public type NonAuthoritativeInformation record {
    *CommonResponse;
    readonly StatusNonAuthoritativeInformation status = STATUS_NON_AUTHORITATIVE_INFORMATION_OBJ;
};

public type NoContent record {
    *CommonResponse;
    readonly StatusNoContent status = STATUS_NO_CONTENT_OBJ;
};

public type ResetContent record {
    *CommonResponse;
    readonly StatusResetContent status = STATUS_RESET_CONTENT_OBJ;
};

public type PartialContent record {
    *CommonResponse;
    readonly StatusPartialContent status = STATUS_PARTIAL_CONTENT_OBJ;
};

public type MultipleChoices record {
    *CommonResponse;
    readonly StatusMultipleChoices status = STATUS_MULTIPLE_CHOICES_OBJ;
};

public type MovedPermanently record {
    *CommonResponse;
    readonly StatusMovedPermanently status = STATUS_MOVED_PERMANENTLY_OBJ;
};

public type Found record {
    *CommonResponse;
    readonly StatusFound status = STATUS_FOUND_OBJ;
};

public type SeeOther record {
    *CommonResponse;
    readonly StatusSeeOther status = STATUS_SEE_OTHER_OBJ;
};

public type NotModified record {
    *CommonResponse;
    readonly StatusNotModified status = STATUS_NOT_MODIFIED_OBJ;
};

public type UseProxy record {
    *CommonResponse;
    readonly StatusUseProxy status = STATUS_USE_PROXY_OBJ;
};

public type TemporaryRedirect record {
    *CommonResponse;
    readonly StatusTemporaryRedirect status = STATUS_TEMPORARY_REDIRECT_OBJ;
};

public type PermanentRedirect record {
    *CommonResponse;
    readonly StatusPermanentRedirect status = STATUS_PERMANENT_REDIRECT_OBJ;
};

public type BadRequest record {
    *CommonResponse;
    readonly StatusBadRequest status = STATUS_BAD_REQUEST_OBJ;
};

public type Unauthorized record {
    *CommonResponse;
    readonly StatusUnauthorized status = STATUS_UNAUTHORIZED_OBJ;
};

public type PaymentRequired record {
    *CommonResponse;
    readonly StatusPaymentRequired status = STATUS_PAYMENT_REQUIRED_OBJ;
};

public type Forbidden record {
    *CommonResponse;
    readonly StatusForbidden status = STATUS_FORBIDDEN_OBJ;
};

public type NotFound record {
    *CommonResponse;
    readonly StatusNotFound status = STATUS_NOT_FOUND_OBJ;
};

public type MethodNotAllowed record {
    *CommonResponse;
    readonly StatusMethodNotAllowed status = STATUS_METHOD_NOT_ALLOWED_OBJ;
};

public type NotAcceptable record {
    *CommonResponse;
    readonly StatusNotAcceptable status = STATUS_NOT_ACCEPTABLE_OBJ;
};

public type ProxyAuthenticationRequired record {
    *CommonResponse;
    readonly StatusProxyAuthenticationRequired status = STATUS_PROXY_AUTHENTICATION_REQUIRED_OBJ;
};

public type RequestTimeout record {
    *CommonResponse;
    readonly StatusRequestTimeout status = STATUS_REQUEST_TIMEOUT_OBJ;
};

public type Conflict record {
    *CommonResponse;
    readonly StatusConflict status = STATUS_CONFLICT_OBJ;
};

public type Gone record {
    *CommonResponse;
    readonly StatusGone status = STATUS_GONE_OBJ;
};

public type LengthRequired record {
    *CommonResponse;
    readonly StatusLengthRequired status = STATUS_LENGTH_REQUIRED_OBJ;
};

public type PreconditionFailed record {
    *CommonResponse;
    readonly StatusPreconditionFailed status = STATUS_PRECONDITION_FAILED_OBJ;
};

public type PayloadTooLarge record {
    *CommonResponse;
    readonly StatusPayloadTooLarge status = STATUS_PAYLOAD_TOO_LARGE_OBJ;
};

public type UriTooLong record {
    *CommonResponse;
    readonly StatusUriTooLong status = STATUS_URI_TOO_LONG_OBJ;
};

public type UnsupportedMediaType record {
    *CommonResponse;
    readonly StatusUnsupportedMediaType status = STATUS_UNSUPPORTED_MEDIA_TYPE_OBJ;
};

public type RangeNotSatisfiable record {
    *CommonResponse;
    readonly StatusRangeNotSatisfiable status = STATUS_RANGE_NOT_SATISFIABLE_OBJ;
};

public type ExpectationFailed record {
    *CommonResponse;
    readonly StatusExpectationFailed status = STATUS_EXPECTATION_FAILED_OBJ;
};

public type UpgradeRequired record {
    *CommonResponse;
    readonly StatusUpgradeRequired status = STATUS_UPGRADE_REQUIRED_OBJ;
};

public type RequestHeaderFieldsTooLarge record {
    *CommonResponse;
    readonly StatusRequestHeaderFieldsTooLarge status = STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE_OBJ;
};

public type InternalServerError record {
    *CommonResponse;
    readonly StatusInternalServerError status = STATUS_INTERNAL_SERVER_ERROR_OBJ;
};

public type NotImplemented record {
    *CommonResponse;
    readonly StatusNotImplemented status = STATUS_NOT_IMPLEMENTED_OBJ;
};

public type BadGateway record {
    *CommonResponse;
    readonly StatusBadGateway status = STATUS_BAD_GATEWAY_OBJ;
};

public type ServiceUnavailable record {
    *CommonResponse;
    readonly StatusServiceUnavailable status = STATUS_SERVICE_UNAVAILABLE_OBJ;
};

public type GatewayTimeout record {
    *CommonResponse;
    readonly StatusGatewayTimeout status = STATUS_GATEWAY_TIMEOUT_OBJ;
};

public type HttpVersionNotSupported record {
    *CommonResponse;
    readonly StatusHttpVersionNotSupported status = STATUS_HTTP_VERSION_NOT_SUPPORTED_OBJ;
};
