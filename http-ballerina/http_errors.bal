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

# Represents the details of an HTTP error.
# 
# + statusCode - The status code, if the inbound error response exists
public type Detail record {
    int statusCode?;
};

# Represents the details of the `LoadBalanceActionError`.
#
# + httpActionErr - Array of errors occurred at each endpoint
public type LoadBalanceActionErrorData record {
    error[] httpActionErr?;
};

// Level 1
# Defines the common error type for the module
public type Error distinct error;

// Level 2
# Defines the possible listener error types
public type ListenerError distinct Error;

# Defines the possible client error types
public type ClientError distinct Error;

// Level 3
# Defines the listener error types that returned while receiving inbound request
public type InboundRequestError distinct ListenerError;

# Defines the listener error types that returned while sending outbound response
public type OutboundResponseError distinct ListenerError;

# Represents a generic listener error
public type GenericListenerError distinct ListenerError;

# Defines the Auth error types that returned from listener
public type ListenerAuthError distinct ListenerError;

# Defines the client error types that returned while sending outbound request
public type OutboundRequestError distinct ClientError;

# Defines the client error types that returned while receiving inbound response
public type InboundResponseError distinct ClientError;

# Defines the Auth error types that returned from client
public type ClientAuthError distinct ClientError;

# Defines the resiliency error types that returned from client
public type ResiliencyError distinct ClientError;

// Generic errors (mostly to wrap errors from other modules)
# Represents a generic client error
public type GenericClientError distinct ClientError;

# Represents an HTTP/2 client generic error
public type Http2ClientError distinct ClientError;

# Represents a client error that occurred due to SSL failure
public type SslError distinct ClientError;

// Level 4
# Represents a header not found error when retrieving headers
public type HeaderNotFoundError distinct GenericListenerError;

// Other client-related errors
# Represents a client error that occurred due to unsupported action invocation
public type UnsupportedActionError distinct GenericClientError;

# Represents a client error that occurred exceeding maximum wait time
public type MaximumWaitTimeExceededError distinct GenericClientError;

# Represents a cookie error that occurred when using the cookies
public type CookieHandlingError distinct GenericClientError;

# Represents an error, which occurred due to bad syntax or incomplete info in the client request(4xx HTTP response)
public type ClientRequestError distinct GenericClientError & error<Detail>;

# Represents an error, which occurred due to a failure of the remote server(5xx HTTP response)
public type RemoteServerError distinct GenericClientError & error<Detail>;

// Resiliency errors
# Represents a client error that occurred due to all the failover endpoint failure
public type FailoverAllEndpointsFailedError distinct ResiliencyError;

# Represents a client error that occurred due to failover action failure
public type FailoverActionFailedError distinct ResiliencyError;

# Represents a client error that occurred due to upstream service unavailability
public type UpstreamServiceUnavailableError distinct ResiliencyError;

# Represents a client error that occurred due to all the load balance endpoint failure
public type AllLoadBalanceEndpointsFailedError distinct ResiliencyError;

# Represents a client error that occurred due to circuit breaker configuration error.
public type CircuitBreakerConfigError distinct ResiliencyError;

# Represents a client error that occurred due to all the the retry attempts failure
public type AllRetryAttemptsFailed distinct ResiliencyError;

# Represents the error that triggered upon a request/response idle timeout
public type IdleTimeoutError distinct ResiliencyError;

# Represents an error occurred in an remote function of the Load Balance connector.
public type LoadBalanceActionError distinct ResiliencyError & error<LoadBalanceActionErrorData>;

// Outbound request errors in client
# Represents a client error that occurred due to outbound request initialization failure
public type InitializingOutboundRequestError distinct OutboundRequestError;

# Represents a client error that occurred while writing outbound request headers
public type WritingOutboundRequestHeadersError distinct OutboundRequestError;

# Represents a client error that occurred while writing outbound request entity body
public type WritingOutboundRequestBodyError distinct OutboundRequestError;

// Inbound response errors in client
# Represents a client error that occurred due to inbound response initialization failure
public type InitializingInboundResponseError distinct InboundResponseError;

# Represents a client error that occurred while reading inbound response headers
public type ReadingInboundResponseHeadersError distinct InboundResponseError;

# Represents a client error that occurred while reading inbound response entity body
public type ReadingInboundResponseBodyError distinct InboundResponseError;

//Inbound request errors in listener
# Represents a listener error that occurred due to inbound request initialization failure
public type InitializingInboundRequestError distinct InboundRequestError;

# Represents a listener error that occurred while reading inbound request headers
public type ReadingInboundRequestHeadersError distinct InboundRequestError;

# Represents a listener error that occurred while writing the inbound request entity body
public type ReadingInboundRequestBodyError distinct InboundRequestError;

// Outbound response errors in listener
# Represents a listener error that occurred due to outbound response initialization failure
public type InitializingOutboundResponseError distinct OutboundResponseError;

# Represents a listener error that occurred while writing outbound response headers
public type WritingOutboundResponseHeadersError distinct OutboundResponseError;

# Represents a listener error that occurred while writing outbound response entity body
public type WritingOutboundResponseBodyError distinct OutboundResponseError;

# Represents an error that occurred due to 100 continue response initialization failure
public type Initiating100ContinueResponseError distinct OutboundResponseError;

# Represents an error that occurred while writing 100 continue response
public type Writing100ContinueResponseError distinct OutboundResponseError;

# Represents a cookie error that occurred when sending cookies in the response
public type InvalidCookieError distinct OutboundResponseError;
