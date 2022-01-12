// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// Remove the union once https://github.com/ballerina-platform/ballerina-lang/issues/30490 is fixed.
# Defines the possible status code response record types.
public type StatusCodeResponse Continue|SwitchingProtocols|Ok|Created|Accepted|NonAuthoritativeInformation|NoContent|
    ResetContent|PartialContent|MultipleChoices|MovedPermanently|Found|SeeOther|NotModified|UseProxy|TemporaryRedirect|
    PermanentRedirect|BadRequest|Unauthorized|PaymentRequired|Forbidden|NotFound|MethodNotAllowed|NotAcceptable|
    ProxyAuthenticationRequired|RequestTimeout|Conflict|Gone|LengthRequired|PreconditionFailed|PayloadTooLarge|
    UriTooLong|UnsupportedMediaType|RangeNotSatisfiable|ExpectationFailed|UpgradeRequired|RequestHeaderFieldsTooLarge|
    InternalServerError|NotImplemented|BadGateway|ServiceUnavailable|GatewayTimeout|HttpVersionNotSupported;

# Defines the possible success status code response record types.
type SuccessStatusCodeResponse Ok|Created|Accepted|NonAuthoritativeInformation|NoContent|ResetContent|
    PartialContent;

# The `Status` object creates the distinction for the different response status code types.
#
# + code - The response status code
public type Status distinct object {
    public int code;
};

# The common attributed of response status code record type.
#
# + mediaType - The value of response `Content-type` header
# + headers - The response headers
# + body - The response payload
public type CommonResponse record {|
    string mediaType?;
    map<string|int|boolean|string[]|int[]|boolean[]> headers?;
    anydata body?;
|};

// Status code class declarations
# Represents the status code of `STATUS_CONTINUE`.
#
# + code - The response status code
public readonly class StatusContinue {
    *Status;
    public STATUS_CONTINUE code = STATUS_CONTINUE;
}

# Represents the status code of `STATUS_SWITCHING_PROTOCOLS`.
#
# + code - The response status code
public readonly class StatusSwitchingProtocols {
    *Status;
    public STATUS_SWITCHING_PROTOCOLS code = STATUS_SWITCHING_PROTOCOLS;
}

# Represents the status code of `STATUS_OK`.
#
# + code - The response status code
public readonly class StatusOK {
    *Status;
    public STATUS_OK code = STATUS_OK;
}

# Represents the status code of `STATUS_CREATED`.
#
# + code - The response status code
public readonly class StatusCreated {
    *Status;
    public STATUS_CREATED code = STATUS_CREATED;
}

# Represents the status code of `STATUS_ACCEPTED`.
#
# + code - The response status code
public readonly class StatusAccepted {
    *Status;
    public STATUS_ACCEPTED code = STATUS_ACCEPTED;
}

# Represents the status code of `STATUS_NON_AUTHORITATIVE_INFORMATION`.
#
# + code - The response status code
public readonly class StatusNonAuthoritativeInformation {
    *Status;
    public STATUS_NON_AUTHORITATIVE_INFORMATION code = STATUS_NON_AUTHORITATIVE_INFORMATION;
}

# Represents the status code of `STATUS_NO_CONTENT`.
#
# + code - The response status code
public readonly class StatusNoContent {
    *Status;
    public STATUS_NO_CONTENT code = STATUS_NO_CONTENT;
}

# Represents the status code of `STATUS_RESET_CONTENT`.
#
# + code - The response status code
public readonly class StatusResetContent {
    *Status;
    public STATUS_RESET_CONTENT code = STATUS_RESET_CONTENT;
}

# Represents the status code of `STATUS_PARTIAL_CONTENT`.
#
# + code - The response status code
public readonly class StatusPartialContent {
    *Status;
    public STATUS_PARTIAL_CONTENT code = STATUS_PARTIAL_CONTENT;
}

# Represents the status code of `STATUS_MULTIPLE_CHOICES`.
#
# + code - The response status code
public readonly class StatusMultipleChoices {
    *Status;
    public STATUS_MULTIPLE_CHOICES code = STATUS_MULTIPLE_CHOICES;
}

# Represents the status code of `STATUS_MOVED_PERMANENTLY`.
#
# + code - The response status code
public readonly class StatusMovedPermanently {
    *Status;
    public STATUS_MOVED_PERMANENTLY code = STATUS_MOVED_PERMANENTLY;
}

# Represents the status code of `STATUS_FOUND`.
#
# + code - The response status code
public readonly class StatusFound {
    *Status;
    public STATUS_FOUND code = STATUS_FOUND;
}

# Represents the status code of `STATUS_SEE_OTHER`.
#
# + code - The response status code
public readonly class StatusSeeOther {
    *Status;
    public STATUS_SEE_OTHER code = STATUS_SEE_OTHER;
}

# Represents the status code of `STATUS_NOT_MODIFIED`.
#
# + code - The response status code
public readonly class StatusNotModified {
    *Status;
    public STATUS_NOT_MODIFIED code = STATUS_NOT_MODIFIED;
}

# Represents the status code of `STATUS_USE_PROXY`.
#
# + code - The response status code
public readonly class StatusUseProxy {
    *Status;
    public STATUS_USE_PROXY code = STATUS_USE_PROXY;
}

# Represents the status code of `STATUS_TEMPORARY_REDIRECT`.
#
# + code - The response status code
public readonly class StatusTemporaryRedirect {
    *Status;
    public STATUS_TEMPORARY_REDIRECT code = STATUS_TEMPORARY_REDIRECT;
}

# Represents the status code of `STATUS_PERMANENT_REDIRECT`.
#
# + code - The response status code
public readonly class StatusPermanentRedirect {
    *Status;
    public STATUS_PERMANENT_REDIRECT code = STATUS_PERMANENT_REDIRECT;
}

# Represents the status code of `STATUS_BAD_REQUEST`.
#
# + code - The response status code
public readonly class StatusBadRequest {
    *Status;
    public STATUS_BAD_REQUEST code = STATUS_BAD_REQUEST;
}

# Represents the status code of `STATUS_UNAUTHORIZED`.
#
# + code - The response status code
public readonly class StatusUnauthorized {
    *Status;
    public STATUS_UNAUTHORIZED code = STATUS_UNAUTHORIZED;
}

# Represents the status code of `STATUS_PAYMENT_REQUIRED`.
#
# + code - The response status code
public readonly class StatusPaymentRequired {
    *Status;
    public STATUS_PAYMENT_REQUIRED code = STATUS_PAYMENT_REQUIRED;
}

# Represents the status code of `STATUS_FORBIDDEN`.
#
# + code - The response status code
public readonly class StatusForbidden {
    *Status;
    public STATUS_FORBIDDEN code = STATUS_FORBIDDEN;
}

# Represents the status code of `STATUS_NOT_FOUND`.
#
# + code - The response status code
public readonly class StatusNotFound {
    *Status;
    public STATUS_NOT_FOUND code = STATUS_NOT_FOUND;
}

# Represents the status code of `STATUS_METHOD_NOT_ALLOWED`.
#
# + code - The response status code
public readonly class StatusMethodNotAllowed {
    *Status;
    public STATUS_METHOD_NOT_ALLOWED code = STATUS_METHOD_NOT_ALLOWED;
}

# Represents the status code of `STATUS_NOT_ACCEPTABLE`.
#
# + code - The response status code
public readonly class StatusNotAcceptable {
    *Status;
    public STATUS_NOT_ACCEPTABLE code = STATUS_NOT_ACCEPTABLE;
}

# Represents the status code of `STATUS_PROXY_AUTHENTICATION_REQUIRED`.
#
# + code - The response status code
public readonly class StatusProxyAuthenticationRequired {
    *Status;
    public STATUS_PROXY_AUTHENTICATION_REQUIRED code = STATUS_PROXY_AUTHENTICATION_REQUIRED;
}

# Represents the status code of `STATUS_REQUEST_TIMEOUT`.
#
# + code - The response status code
public readonly class StatusRequestTimeout {
    *Status;
    public STATUS_REQUEST_TIMEOUT code = STATUS_REQUEST_TIMEOUT;
}

# Represents the status code of `STATUS_CONFLICT`.
#
# + code - The response status code
public readonly class StatusConflict {
    *Status;
    public STATUS_CONFLICT code = STATUS_CONFLICT;
}

# Represents the status code of `STATUS_GONE`.
#
# + code - The response status code
public readonly class StatusGone {
    *Status;
    public STATUS_GONE code = STATUS_GONE;
}

# Represents the status code of `STATUS_LENGTH_REQUIRED`.
#
# + code - The response status code
public readonly class StatusLengthRequired {
    *Status;
    public STATUS_LENGTH_REQUIRED code = STATUS_LENGTH_REQUIRED;
}

# Represents the status code of `STATUS_PRECONDITION_FAILED`.
#
# + code - The response status code
public readonly class StatusPreconditionFailed {
    *Status;
    public STATUS_PRECONDITION_FAILED code = STATUS_PRECONDITION_FAILED;
}

# Represents the status code of `STATUS_PAYLOAD_TOO_LARGE`.
#
# + code - The response status code
public readonly class StatusPayloadTooLarge {
    *Status;
    public STATUS_PAYLOAD_TOO_LARGE code = STATUS_PAYLOAD_TOO_LARGE;
}

# Represents the status code of `STATUS_URI_TOO_LONG`.
#
# + code - The response status code
public readonly class StatusUriTooLong {
    *Status;
    public STATUS_URI_TOO_LONG code = STATUS_URI_TOO_LONG;
}

# Represents the status code of `STATUS_UNSUPPORTED_MEDIA_TYPE`.
#
# + code - The response status code
public readonly class StatusUnsupportedMediaType {
    *Status;
    public STATUS_UNSUPPORTED_MEDIA_TYPE code = STATUS_UNSUPPORTED_MEDIA_TYPE;
}

# Represents the status code of `STATUS_RANGE_NOT_SATISFIABLE`.
#
# + code - The response status code
public readonly class StatusRangeNotSatisfiable {
    *Status;
    public STATUS_RANGE_NOT_SATISFIABLE code = STATUS_RANGE_NOT_SATISFIABLE;
}

# Represents the status code of `STATUS_EXPECTATION_FAILED`.
#
# + code - The response status code
public readonly class StatusExpectationFailed {
    *Status;
    public STATUS_EXPECTATION_FAILED code = STATUS_EXPECTATION_FAILED;
}

# Represents the status code of `STATUS_UPGRADE_REQUIRED`.
#
# + code - The response status code
public readonly class StatusUpgradeRequired {
    *Status;
    public STATUS_UPGRADE_REQUIRED code = STATUS_UPGRADE_REQUIRED;
}

# Represents the status code of `STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE`.
#
# + code - The response status code
public readonly class StatusRequestHeaderFieldsTooLarge {
    *Status;
    public STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE code = STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE;
}

# Represents the status code of `STATUS_INTERNAL_SERVER_ERROR`.
#
# + code - The response status code
public readonly class StatusInternalServerError {
    *Status;
    public STATUS_INTERNAL_SERVER_ERROR code = STATUS_INTERNAL_SERVER_ERROR;
}

# Represents the status code of `STATUS_NOT_IMPLEMENTED`.
#
# + code - The response status code
public readonly class StatusNotImplemented {
    *Status;
    public STATUS_NOT_IMPLEMENTED code = STATUS_NOT_IMPLEMENTED;
}

# Represents the status code of `STATUS_BAD_GATEWAY`.
#
# + code - The response status code
public readonly class StatusBadGateway {
    *Status;
    public STATUS_BAD_GATEWAY code = STATUS_BAD_GATEWAY;
}

# Represents the status code of `STATUS_SERVICE_UNAVAILABLE`.
#
# + code - The response status code
public readonly class StatusServiceUnavailable {
    *Status;
    public STATUS_SERVICE_UNAVAILABLE code = STATUS_SERVICE_UNAVAILABLE;
}

# Represents the status code of `STATUS_GATEWAY_TIMEOUT`.
#
# + code - The response status code
public readonly class StatusGatewayTimeout {
    *Status;
    public STATUS_GATEWAY_TIMEOUT code = STATUS_GATEWAY_TIMEOUT;
}

# Represents the status code of `STATUS_HTTP_VERSION_NOT_SUPPORTED`.
#
# + code - The response status code
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
# The status code response record of `Continue`.
#
# + status - The response status code obj
public type Continue record {|
    *CommonResponse;
    readonly StatusContinue status = STATUS_CONTINUE_OBJ;
|};

# The status code response record of `SwitchingProtocols`.
#
# + status - The response status code obj
public type SwitchingProtocols record {|
    *CommonResponse;
    readonly StatusSwitchingProtocols status = STATUS_SWITCHING_PROTOCOLS_OBJ;
|};

# The status code response record of `Ok`.
#
# + status - The response status code obj
public type Ok record {|
    *CommonResponse;
    readonly StatusOK status = STATUS_OK_OBJ;
|};

# The status code response record of `Created`.
#
# + status - The response status code obj
public type Created record {|
    *CommonResponse;
    readonly StatusCreated status = STATUS_CREATED_OBJ;
|};

# The status code response record of `Accepted`.
#
# + status - The response status code obj
public type Accepted record {|
    *CommonResponse;
    readonly StatusAccepted status = STATUS_ACCEPTED_OBJ;
|};

# The status code response record of `NonAuthoritativeInformation`.
#
# + status - The response status code obj
public type NonAuthoritativeInformation record {|
    *CommonResponse;
    readonly StatusNonAuthoritativeInformation status = STATUS_NON_AUTHORITATIVE_INFORMATION_OBJ;
|};

# The status code response record of `NoContent`.
#
# + headers - The response headers
# + status - The response status code obj
public type NoContent record {|
    map<string|string[]> headers?;
    readonly StatusNoContent status = STATUS_NO_CONTENT_OBJ;
|};

# The status code response record of `ResetContent`.
#
# + status - The response status code obj
public type ResetContent record {|
    *CommonResponse;
    readonly StatusResetContent status = STATUS_RESET_CONTENT_OBJ;
|};

# The status code response record of `PartialContent`.
#
# + status - The response status code obj
public type PartialContent record {|
    *CommonResponse;
    readonly StatusPartialContent status = STATUS_PARTIAL_CONTENT_OBJ;
|};

# The status code response record of `MultipleChoices`.
#
# + status - The response status code obj
public type MultipleChoices record {|
    *CommonResponse;
    readonly StatusMultipleChoices status = STATUS_MULTIPLE_CHOICES_OBJ;
|};

# The status code response record of `MovedPermanently`.
#
# + status - The response status code obj
public type MovedPermanently record {|
    *CommonResponse;
    readonly StatusMovedPermanently status = STATUS_MOVED_PERMANENTLY_OBJ;
|};

# The status code response record of `Found`.
#
# + status - The response status code obj
public type Found record {|
    *CommonResponse;
    readonly StatusFound status = STATUS_FOUND_OBJ;
|};

# The status code response record of `SeeOther`.
#
# + status - The response status code obj
public type SeeOther record {|
    *CommonResponse;
    readonly StatusSeeOther status = STATUS_SEE_OTHER_OBJ;
|};

# The status code response record of `NotModified`.
#
# + status - The response status code obj
public type NotModified record {|
    *CommonResponse;
    readonly StatusNotModified status = STATUS_NOT_MODIFIED_OBJ;
|};

# The status code response record of `UseProxy`.
#
# + status - The response status code obj
public type UseProxy record {|
    *CommonResponse;
    readonly StatusUseProxy status = STATUS_USE_PROXY_OBJ;
|};

# The status code response record of `TemporaryRedirect`.
#
# + status - The response status code obj
public type TemporaryRedirect record {|
    *CommonResponse;
    readonly StatusTemporaryRedirect status = STATUS_TEMPORARY_REDIRECT_OBJ;
|};

# The status code response record of `PermanentRedirect`.
#
# + status - The response status code obj
public type PermanentRedirect record {|
    *CommonResponse;
    readonly StatusPermanentRedirect status = STATUS_PERMANENT_REDIRECT_OBJ;
|};

# The status code response record of `BadRequest`.
#
# + status - The response status code obj
public type BadRequest record {|
    *CommonResponse;
    readonly StatusBadRequest status = STATUS_BAD_REQUEST_OBJ;
|};

# The status code response record of `Unauthorized`.
#
# + status - The response status code obj
public type Unauthorized record {|
    *CommonResponse;
    readonly StatusUnauthorized status = STATUS_UNAUTHORIZED_OBJ;
|};

# The status code response record of `PaymentRequired`.
#
# + status - The response status code obj
public type PaymentRequired record {|
    *CommonResponse;
    readonly StatusPaymentRequired status = STATUS_PAYMENT_REQUIRED_OBJ;
|};

# The status code response record of `Forbidden`.
#
# + status - The response status code obj
public type Forbidden record {|
    *CommonResponse;
    readonly StatusForbidden status = STATUS_FORBIDDEN_OBJ;
|};

# The status code response record of `NotFound`.
#
# + status - The response status code obj
public type NotFound record {|
    *CommonResponse;
    readonly StatusNotFound status = STATUS_NOT_FOUND_OBJ;
|};

# The status code response record of `MethodNotAllowed`.
#
# + status - The response status code obj
public type MethodNotAllowed record {|
    *CommonResponse;
    readonly StatusMethodNotAllowed status = STATUS_METHOD_NOT_ALLOWED_OBJ;
|};

# The status code response record of `NotAcceptable`.
#
# + status - The response status code obj
public type NotAcceptable record {|
    *CommonResponse;
    readonly StatusNotAcceptable status = STATUS_NOT_ACCEPTABLE_OBJ;
|};

# The status code response record of `ProxyAuthenticationRequired`.
#
# + status - The response status code obj
public type ProxyAuthenticationRequired record {|
    *CommonResponse;
    readonly StatusProxyAuthenticationRequired status = STATUS_PROXY_AUTHENTICATION_REQUIRED_OBJ;
|};

# The status code response record of `RequestTimeout`.
#
# + status - The response status code obj
public type RequestTimeout record {|
    *CommonResponse;
    readonly StatusRequestTimeout status = STATUS_REQUEST_TIMEOUT_OBJ;
|};

# The status code response record of `Conflict`.
#
# + status - The response status code obj
public type Conflict record {|
    *CommonResponse;
    readonly StatusConflict status = STATUS_CONFLICT_OBJ;
|};

# The status code response record of `Gone`.
#
# + status - The response status code obj
public type Gone record {|
    *CommonResponse;
    readonly StatusGone status = STATUS_GONE_OBJ;
|};

# The status code response record of `LengthRequired`.
#
# + status - The response status code obj
public type LengthRequired record {|
    *CommonResponse;
    readonly StatusLengthRequired status = STATUS_LENGTH_REQUIRED_OBJ;
|};

# The status code response record of `PreconditionFailed`.
#
# + status - The response status code obj
public type PreconditionFailed record {|
    *CommonResponse;
    readonly StatusPreconditionFailed status = STATUS_PRECONDITION_FAILED_OBJ;
|};

# The status code response record of `PayloadTooLarge`.
#
# + status - The response status code obj
public type PayloadTooLarge record {|
    *CommonResponse;
    readonly StatusPayloadTooLarge status = STATUS_PAYLOAD_TOO_LARGE_OBJ;
|};

# The status code response record of `UriTooLong`.
#
# + status - The response status code obj
public type UriTooLong record {|
    *CommonResponse;
    readonly StatusUriTooLong status = STATUS_URI_TOO_LONG_OBJ;
|};

# The status code response record of `UnsupportedMediaType`.
#
# + status - The response status code obj
public type UnsupportedMediaType record {|
    *CommonResponse;
    readonly StatusUnsupportedMediaType status = STATUS_UNSUPPORTED_MEDIA_TYPE_OBJ;
|};

# The status code response record of `RangeNotSatisfiable`.
#
# + status - The response status code obj
public type RangeNotSatisfiable record {|
    *CommonResponse;
    readonly StatusRangeNotSatisfiable status = STATUS_RANGE_NOT_SATISFIABLE_OBJ;
|};

# The status code response record of `ExpectationFailed`.
#
# + status - The response status code obj
public type ExpectationFailed record {|
    *CommonResponse;
    readonly StatusExpectationFailed status = STATUS_EXPECTATION_FAILED_OBJ;
|};

# The status code response record of `UpgradeRequired`.
#
# + status - The response status code obj
public type UpgradeRequired record {|
    *CommonResponse;
    readonly StatusUpgradeRequired status = STATUS_UPGRADE_REQUIRED_OBJ;
|};

# The status code response record of `RequestHeaderFieldsTooLarge`.
#
# + status - The response status code obj
public type RequestHeaderFieldsTooLarge record {|
    *CommonResponse;
    readonly StatusRequestHeaderFieldsTooLarge status = STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE_OBJ;
|};

# The status code response record of `InternalServerError`.
#
# + status - The response status code obj
public type InternalServerError record {|
    *CommonResponse;
    readonly StatusInternalServerError status = STATUS_INTERNAL_SERVER_ERROR_OBJ;
|};

# The status code response record of `NotImplemented`.
#
# + status - The response status code obj
public type NotImplemented record {|
    *CommonResponse;
    readonly StatusNotImplemented status = STATUS_NOT_IMPLEMENTED_OBJ;
|};

# The status code response record of `BadGateway`.
#
# + status - The response status code obj
public type BadGateway record {|
    *CommonResponse;
    readonly StatusBadGateway status = STATUS_BAD_GATEWAY_OBJ;
|};

# The status code response record of `ServiceUnavailable`.
#
# + status - The response status code obj
public type ServiceUnavailable record {|
    *CommonResponse;
    readonly StatusServiceUnavailable status = STATUS_SERVICE_UNAVAILABLE_OBJ;
|};

# The status code response record of `GatewayTimeout`.
#
# + status - The response status code obj
public type GatewayTimeout record {|
    *CommonResponse;
    readonly StatusGatewayTimeout status = STATUS_GATEWAY_TIMEOUT_OBJ;
|};

# The status code response record of `HttpVersionNotSupported`.
#
# + status - The response status code obj
public type HttpVersionNotSupported record {|
    *CommonResponse;
    readonly StatusHttpVersionNotSupported status = STATUS_HTTP_VERSION_NOT_SUPPORTED_OBJ;
|};
