/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api;

/**
 * Defines enum for Http Error types. This enum stores Error type name.
 */
public enum HttpErrorType {
    // ResiliencyError
    FAILOVER_ALL_ENDPOINTS_FAILED("FailoverAllEndpointsFailed"),
    FAILOVER_ENDPOINT_ACTION_FAILED("FailoverActionFailedError"),
    UPSTREAM_SERVICE_UNAVAILABLE("UpstreamServiceUnavailableError"),
    ALL_LOAD_BALANCE_ENDPOINTS_FAILED("AllLoadBalanceEndpointsFailedError"),
    ALL_RETRY_ATTEMPTS_FAILED("AllRetryAttemptsFailed"),
    IDLE_TIMEOUT_TRIGGERED("IdleTimeoutError"),
    LISTENER_STARTUP_FAILURE("ListenerError"),

    // OutboundRequestError (Client)
    INIT_OUTBOUND_REQUEST_FAILED("InitializingOutboundRequestError"),
    WRITING_OUTBOUND_REQUEST_HEADER_FAILED("WritingOutboundRequestHeaderError"),
    WRITING_OUTBOUND_REQUEST_BODY_FAILED("WritingOutboundRequestBodyError"),

    // InboundResponseError (Client)
    INIT_INBOUND_RESPONSE_FAILED("{ballerina/http}InitializingInboundResponseFailed"),
    READING_INBOUND_RESPONSE_HEADERS_FAILED("ReadingInboundResponseHeadersError"),
    READING_INBOUND_RESPONSE_BODY_FAILED("ReadingInboundResponseBodyError"),

    // InboundRequestError
    INIT_INBOUND_REQUEST_FAILED("InitializingInboundRequestError"),
    READING_INBOUND_REQUEST_HEADER_FAILED("ReadingInboundRequestHeaderError"),
    READING_INBOUND_REQUEST_BODY_FAILED("ReadingInboundRequestBodyError"),

    // OutboundResponseError
    INIT_OUTBOUND_RESPONSE_FAILED("{ballerina/http}InitializingOutboundResponseFailed"),
    WRITING_OUTBOUND_RESPONSE_HEADERS_FAILED("WritingOutboundResponseHeadersError"),
    WRITING_OUTBOUND_RESPONSE_BODY_FAILED("WritingOutboundResponseBodyError"),
    INIT_100_CONTINUE_RESPONSE_FAILED("Initiating100ContinueResponseError"),
    WRITING_100_CONTINUE_RESPONSE_FAILED("Writing100ContinueResponseError"),

    // Other errors
    GENERIC_CLIENT_ERROR("GenericClientError"),
    GENERIC_LISTENER_ERROR("GenericListenerError"),
    UNSUPPORTED_ACTION("UnsupportedActionError"),
    HTTP2_CLIENT_ERROR("Http2ClientError"),
    MAXIMUM_WAIT_TIME_EXCEEDED("MaximumWaitTimeExceededError"),
    SSL_ERROR("SslError"),
    INVALID_CONTENT_LENGTH("InvalidContentLengthError"),
    HEADER_NOT_FOUND_ERROR("HeaderNotFoundError"),
    CLIENT_ERROR("ClientError"),
    PAYLOAD_BINDING_CLIENT_ERROR("PayloadBindingClientError"),
    INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR("InternalPayloadBindingListenerError"),
    INTERNAL_PAYLOAD_VALIDATION_LISTENER_ERROR("InternalPayloadValidationListenerError"),
    INTERNAL_HEADER_BINDING_LISTENER_ERROR("InternalHeaderBindingListenerError"),
    INTERNAL_QUERY_PARAM_BINDING_ERROR("InternalQueryParameterBindingError"),
    INTERNAL_PATH_PARAM_BINDING_ERROR("InternalPathParameterBindingError"),
    INTERNAL_INTERCEPTOR_RETURN_ERROR("InternalInterceptorReturnError"),
    INTERNAL_REQ_DISPATCHING_ERROR("InternalRequestDispatchingError"),
    INTERNAL_RESOURCE_NOT_FOUND_ERROR("InternalResourceNotFoundError"),
    INTERNAL_RESOURCE_METHOD_NOT_ALLOWED_ERROR("InternalResourceMethodNotAllowedError"),
    INTERNAL_UNSUPPORTED_REQUEST_MEDIA_TYPE_ERROR("InternalUnsupportedRequestMediaTypeError"),
    INTERNAL_REQUEST_NOT_ACCEPTABLE_ERROR("InternalRequestNotAcceptableError"),
    INTERNAL_SERVICE_NOT_FOUND_ERROR("InternalServiceNotFoundError"),
    INTERNAL_BAD_MATRIX_PARAMS_ERROR("InternalBadMatrixParamError"),
    INTERNAL_RESOURCE_DISPATCHING_SERVER_ERROR("InternalResourceDispatchingServerError"),
    INTERNAL_LISTENER_AUTHZ_ERROR("InternalListenerAuthzError"),
    INTERNAL_LISTENER_AUTHN_ERROR("InternalListenerAuthnError"),
    CLIENT_CONNECTOR_ERROR("ClientConnectorError"),
    INTERNAL_RESOURCE_PATH_VALIDATION_ERROR("InternalResourcePathValidationError"),
    INTERNAL_HEADER_VALIDATION_LISTENER_ERROR("InternalHeaderValidationListenerError"),
    INTERNAL_QUERY_PARAM_VALIDATION_ERROR("InternalQueryParameterValidationError"),
    STATUS_CODE_RECORD_BINDING_ERROR("StatusCodeRecordBindingError"),
    HEADER_NOT_FOUND_CLIENT_ERROR("HeaderNotFoundClientError"),
    HEADER_BINDING_CLIENT_ERROR("HeaderBindingClientError"),
    HEADER_VALIDATION_CLIENT_ERROR("HeaderValidationClientError"),
    MEDIA_TYPE_BINDING_CLIENT_ERROR("MediaTypeBindingClientError"),
    MEDIA_TYPE_VALIDATION_CLIENT_ERROR("MediaTypeValidationClientError");

    private final String errorName;

    HttpErrorType(String errorName) {
        this.errorName = errorName;
    }

    /**
     * Returns the name of the error type, which is defined in the ballerina http errors.
     *
     * @return the name of the error type as a String
     */
    public String getErrorName() {
        return errorName;
    }
}
