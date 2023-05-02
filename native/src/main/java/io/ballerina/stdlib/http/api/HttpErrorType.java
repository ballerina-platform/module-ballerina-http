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
    PAYLOAD_BINDING_LISTENER_ERROR("PayloadBindingListenerError"),
    PAYLOAD_VALIDATION_LISTENER_ERROR("PayloadValidationListenerError"),
    HEADER_BINDING_ERROR("HeaderBindingError"),
    QUERY_PARAM_BINDING_ERROR("QueryParameterBindingError"),
    PATH_PARAM_BINDING_ERROR("PathParameterBindingError"),
    INTERCEPTOR_RETURN_ERROR("InterceptorReturnError"),
    REQ_DISPATCHING_ERROR("RequestDispatchingError"),
    RESOURCE_NOT_FOUND_ERROR("ResourceNotFoundError"),
    RESOURCE_METHOD_NOT_ALLOWED_ERROR("ResourceMethodNotAllowedError"),
    UNSUPPORTED_REQUEST_MEDIA_TYPE_ERROR("UnsupportedRequestMediaTypeError"),
    REQUEST_NOT_ACCEPTABLE_ERROR("RequestNotAcceptableError"),
    SERVICE_NOT_FOUND_ERROR("ServiceNotFoundError"),
    BAD_MATRIX_PARAMS_ERROR("BadMatrixParamError"),
    RESOURCE_DISPATCHING_SERVER_ERROR("ResourceDispatchingServerError"),
    INTERNAL_LISTENER_AUTHZ_ERROR("InternalListenerAuthzError"),
    INTERNAL_LISTENER_AUTHN_ERROR("InternalListenerAuthnError"),
    CLIENT_CONNECTOR_ERROR("ClientConnectorError"),
    RESOURCE_PATH_VALIDATION_ERROR("ResourcePathValidationError"),
    HEADER_VALIDATION_ERROR("HeaderValidationError"),
    QUERY_PARAM_VALIDATION_ERROR("QueryParameterValidationError");

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
