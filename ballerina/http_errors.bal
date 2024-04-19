// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import http.httpscerr;

# Represents the details of an HTTP error.
# 
# + statusCode - The inbound error response status code
# + headers - The inbound error response headers
# + body - The inbound error response body
public type Detail record {
    int statusCode;
    map<string[]> headers;
    anydata body;
};

# Represents the details of the `LoadBalanceActionError`.
#
# + httpActionErr - Array of errors occurred at each endpoint
public type LoadBalanceActionErrorData record {
    error[] httpActionErr?;
};

// Level 1
# Defines the common error type for the module.
public type Error distinct error;

type InternalError distinct Error;

// Level 2
# Defines the possible listener error types.
public type ListenerError distinct Error;

# Defines the possible client error types.
public type ClientError distinct Error;

# Represents a header not found error when retrieving headers.
public type HeaderNotFoundError distinct Error;

# Represents an error, which occurred due to header binding.
public type HeaderBindingError distinct Error;

# Represents an error, which occurred due to payload binding.
public type PayloadBindingError distinct Error;

# Represents an error, which occurred due to media-type binding.
public type MediaTypeBindingError distinct Error;

// Level 3
# Defines the listener error types that returned while receiving inbound request.
public type InboundRequestError distinct ListenerError;

# Defines the listener error types that returned while sending outbound response.
public type OutboundResponseError distinct ListenerError;

# Represents a generic listener error.
public type GenericListenerError distinct ListenerError;

# Represents an error, which occurred due to a failure in interceptor return.
public type InterceptorReturnError distinct ListenerError & httpscerr:InternalServerErrorError;

type InternalInterceptorReturnError InterceptorReturnError & InternalError;

type HeaderNotFoundClientError ClientError & HeaderNotFoundError;

type HeaderBindingClientError ClientError & HeaderBindingError;

type InternalHeaderBindingListenerError ListenerError & HeaderBindingError & httpscerr:BadRequestError & InternalError;

# Represents an error, which occurred due to a header constraint validation.
public type HeaderValidationError distinct HeaderBindingError;

type HeaderValidationClientError ClientError & HeaderValidationError;

type InternalHeaderValidationListenerError ListenerError & HeaderValidationError & httpscerr:BadRequestError & InternalError;

# Represents an error, which occurred due to the absence of the payload.
public type NoContentError distinct ClientError;

type PayloadBindingClientError ClientError & PayloadBindingError;

type InternalPayloadBindingListenerError distinct ListenerError & PayloadBindingError & httpscerr:BadRequestError & InternalError;

# Represents an error, which occurred due to payload constraint validation.
public type PayloadValidationError distinct PayloadBindingError;

type PayloadValidationClientError ClientError & PayloadValidationError;

type InternalPayloadValidationListenerError distinct ListenerError & PayloadValidationError & httpscerr:BadRequestError & InternalError;

# Represents an error, which occurred due to a query parameter binding.
public type QueryParameterBindingError distinct ListenerError & httpscerr:BadRequestError;

type InternalQueryParameterBindingError QueryParameterBindingError & InternalError;

# Represents an error, which occurred due to a query parameter constraint validation.
public type QueryParameterValidationError distinct QueryParameterBindingError;

type InternalQueryParameterValidationError QueryParameterValidationError & InternalError;

# Represents an error, which occurred due to a path parameter binding.
public type PathParameterBindingError distinct ListenerError & httpscerr:BadRequestError;

type InternalPathParameterBindingError PathParameterBindingError & InternalError;

type MediaTypeBindingClientError ClientError & MediaTypeBindingError;

# Represents an error, which occurred due to media type validation.
public type MediaTypeValidationError distinct MediaTypeBindingError;

type MediaTypeValidationClientError ClientError & MediaTypeValidationError;

# Represents an error, which occurred during the request dispatching.
public type RequestDispatchingError distinct ListenerError;

type InternalRequestDispatchingError RequestDispatchingError & InternalError;

# Represents an error, which occurred during the service dispatching.
public type ServiceDispatchingError distinct RequestDispatchingError;

# Represents an error, which occurred during the resource dispatching.
public type ResourceDispatchingError distinct RequestDispatchingError;

# Defines the auth error types that returned from listener.
public type ListenerAuthError distinct ListenerError;

# Defines the authentication error types that returned from listener.
public type ListenerAuthnError distinct httpscerr:UnauthorizedError & ListenerAuthError;

# Defines the authorization error types that returned from listener.
public type ListenerAuthzError distinct httpscerr:ForbiddenError & ListenerAuthError;

# Defined for internal use when panicing from the auth_desugar
type InternalListenerAuthnError distinct httpscerr:UnauthorizedError & ListenerAuthError;

# Defined for internal use when panicing from the auth_desugar
type InternalListenerAuthzError distinct httpscerr:ForbiddenError & ListenerAuthError;

# Defines the client error types that returned while sending outbound request.
public type OutboundRequestError distinct ClientError;

# Defines the client error types that returned while receiving inbound response.
public type InboundResponseError distinct ClientError;

# Defines the Auth error types that returned from client.
public type ClientAuthError distinct ClientError;

# Defines the resiliency error types that returned from client.
public type ResiliencyError distinct ClientError;

// Generic errors (mostly to wrap errors from other modules)
# Represents a generic client error.
public type GenericClientError distinct ClientError;

# Represents an HTTP/2 client generic error.
public type Http2ClientError distinct ClientError;

# Represents a client error that occurred due to SSL failure.
public type SslError distinct ClientError;

# Represents both 4XX and 5XX application response client error.
public type ApplicationResponseError distinct (ClientError & error<Detail>);

// Other client-related errors
# Represents a client error that occurred due to unsupported action invocation.
public type UnsupportedActionError distinct GenericClientError;

# Represents a client error that occurred exceeding maximum wait time.
public type MaximumWaitTimeExceededError distinct GenericClientError;

# Represents a cookie error that occurred when using the cookies.
public type CookieHandlingError distinct GenericClientError;

# Represents a client connector error that occurred.
public type ClientConnectorError distinct ClientError;

# Represents an error, which occurred due to bad syntax or incomplete info in the client request(4xx HTTP response).
public type ClientRequestError distinct (ApplicationResponseError & error<Detail>);

# Represents an error, which occurred due to a failure of the remote server(5xx HTTP response).
public type RemoteServerError distinct (ApplicationResponseError & error<Detail>);

// Resiliency errors
# Represents a client error that occurred due to all the failover endpoint failure.
public type FailoverAllEndpointsFailedError distinct ResiliencyError;

# Represents a client error that occurred due to failover action failure.
public type FailoverActionFailedError distinct ResiliencyError;

# Represents a client error that occurred due to upstream service unavailability.
public type UpstreamServiceUnavailableError distinct ResiliencyError;

# Represents a client error that occurred due to all the load balance endpoint failure.
public type AllLoadBalanceEndpointsFailedError distinct ResiliencyError;

# Represents a client error that occurred due to circuit breaker configuration error.
public type CircuitBreakerConfigError distinct ResiliencyError;

# Represents a client error that occurred due to all the the retry attempts failure.
public type AllRetryAttemptsFailed distinct ResiliencyError;

# Represents the error that triggered upon a request/response idle timeout.
public type IdleTimeoutError distinct ResiliencyError;

# Represents an error occurred in an remote function of the Load Balance connector.
public type LoadBalanceActionError distinct ResiliencyError & error<LoadBalanceActionErrorData>;

// Outbound request errors in client
# Represents a client error that occurred due to outbound request initialization failure.
public type InitializingOutboundRequestError distinct OutboundRequestError;

# Represents a client error that occurred while writing outbound request headers.
public type WritingOutboundRequestHeadersError distinct OutboundRequestError;

# Represents a client error that occurred while writing outbound request entity body.
public type WritingOutboundRequestBodyError distinct OutboundRequestError;

// Inbound response errors in client
# Represents a client error that occurred due to inbound response initialization failure.
public type InitializingInboundResponseError distinct InboundResponseError;

# Represents a client error that occurred while reading inbound response headers.
public type ReadingInboundResponseHeadersError distinct InboundResponseError;

# Represents a client error that occurred while reading inbound response entity body.
public type ReadingInboundResponseBodyError distinct InboundResponseError;

//Inbound request errors in listener
# Represents a listener error that occurred due to inbound request initialization failure.
public type InitializingInboundRequestError distinct InboundRequestError;

# Represents a listener error that occurred while reading inbound request headers.
public type ReadingInboundRequestHeadersError distinct InboundRequestError;

# Represents a listener error that occurred while writing the inbound request entity body.
public type ReadingInboundRequestBodyError distinct InboundRequestError;

// Outbound response errors in listener
# Represents a listener error that occurred due to outbound response initialization failure.
public type InitializingOutboundResponseError distinct OutboundResponseError;

# Represents a listener error that occurred while writing outbound response headers.
public type WritingOutboundResponseHeadersError distinct OutboundResponseError;

# Represents a listener error that occurred while writing outbound response entity body.
public type WritingOutboundResponseBodyError distinct OutboundResponseError;

# Represents an error that occurred due to 100 continue response initialization failure.
public type Initiating100ContinueResponseError distinct OutboundResponseError;

# Represents an error that occurred while writing 100 continue response.
public type Writing100ContinueResponseError distinct OutboundResponseError;

# Represents a cookie error that occurred when sending cookies in the response.
public type InvalidCookieError distinct OutboundResponseError;

# Represents Service Not Found error.
public type ServiceNotFoundError httpscerr:NotFoundError & ServiceDispatchingError;

type InternalServiceNotFoundError ServiceNotFoundError & InternalError;

# Represents Bad Matrix Parameter in the request error.
public type BadMatrixParamError httpscerr:BadRequestError & ServiceDispatchingError;

type InternalBadMatrixParamError BadMatrixParamError & InternalError;

# Represents an error, which occurred when the resource is not found during dispatching.
public type ResourceNotFoundError httpscerr:NotFoundError & ResourceDispatchingError;

type InternalResourceNotFoundError ResourceNotFoundError & InternalError;

# Represents an error, which occurred due to a path parameter constraint validation.
public type ResourcePathValidationError httpscerr:BadRequestError & ResourceDispatchingError;

type InternalResourcePathValidationError ResourcePathValidationError & InternalError;

# Represents an error, which occurred when the resource method is not allowed during dispatching.
public type ResourceMethodNotAllowedError httpscerr:MethodNotAllowedError & ResourceDispatchingError;

type InternalResourceMethodNotAllowedError ResourceMethodNotAllowedError & InternalError;

# Represents an error, which occurred when the media type is not supported during dispatching.
public type UnsupportedRequestMediaTypeError httpscerr:UnsupportedMediaTypeError & ResourceDispatchingError;

type InternalUnsupportedRequestMediaTypeError UnsupportedRequestMediaTypeError & InternalError;

# Represents an error, which occurred when the payload is not acceptable during dispatching.
public type RequestNotAcceptableError httpscerr:NotAcceptableError & ResourceDispatchingError;

type InternalRequestNotAcceptableError RequestNotAcceptableError & InternalError;

# Represents other internal server errors during dispatching.
public type ResourceDispatchingServerError httpscerr:InternalServerErrorError & ResourceDispatchingError;

type InternalResourceDispatchingServerError ResourceDispatchingServerError & InternalError;

# Represents the client status code binding error
public type StatusCodeResponseBindingError distinct ClientError & error<Detail>;

type StatusCodeBindingClientRequestError distinct StatusCodeResponseBindingError & ClientRequestError;

type StatusCodeBindingRemoteServerError distinct StatusCodeResponseBindingError & RemoteServerError;

type StatusCodeBindingSuccessError distinct StatusCodeResponseBindingError;
