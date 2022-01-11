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

import ballerina/io;
import ballerina/mime;

# The types of messages that are accepted by HTTP `client` when sending out the outbound request.
public type RequestMessage Request|string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|
                           (map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>|();

# The types of messages that are accepted by HTTP `listener` when sending out the outbound response.
public type ResponseMessage Response|string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|
                            (map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>|();

# The HTTP service type.
public type Service distinct service object {

};

# The types of the response payload that are returned by the HTTP `client` after the data binding operation.
public type PayloadType string|xml|json|map<string>|map<json>|byte[]|record {| anydata...; |}|record {| anydata...;|}[];

# The types of data values that are expected by the HTTP `client` to return after the data binding operation.
public type TargetType typedesc<Response|PayloadType>;

# Defines the HTTP operations related to circuit breaker, failover and load balancer.
#
# `FORWARD`: Forward the specified payload
# `GET`: Request a resource
# `POST`: Create a new resource
# `DELETE`: Deletes the specified resource
# `OPTIONS`: Request communication options available
# `PUT`: Replace the target resource
# `PATCH`: Apply partial modification to the resource
# `HEAD`: Identical to `GET` but no resource body should be returned
# `SUBMIT`: Submits a http request and returns an HttpFuture object
# `NONE`: No operation should be performed
public type HttpOperation HTTP_FORWARD|HTTP_GET|HTTP_POST|HTTP_DELETE|HTTP_OPTIONS|HTTP_PUT|HTTP_PATCH|HTTP_HEAD
                                                                                                |HTTP_SUBMIT|HTTP_NONE;
# Defines the safe HTTP operations which do not modify resource representation.
type safeHttpOperation HTTP_GET|HTTP_HEAD|HTTP_OPTIONS;

// Common type used for HttpFuture and Response used for resiliency clients.
type HttpResponse Response|HttpFuture;

# A record for providing configurations for content compression.
#
# + enable - The status of compression
# + contentTypes - Content types which are allowed for compression
public type CompressionConfig record {|
    Compression enable = COMPRESSION_AUTO;
    string[] contentTypes = [];
|};

type HTTPError record {
    string message = "";
};

# Common client configurations for the next level clients.
#
# + httpVersion - The HTTP version understood by the client
# + http1Settings - Configurations related to HTTP/1.x protocol
# + http2Settings - Configurations related to HTTP/2 protocol
# + timeout - The maximum time to wait (in seconds) for a response before closing the connection
# + forwarded - The choice of setting `forwarded`/`x-forwarded` header
# + followRedirects - Configurations associated with Redirection
# + poolConfig - Configurations associated with request pooling
# + cache - HTTP caching related configurations
# + compression - Specifies the way of handling compression (`accept-encoding`) header
# + auth - Configurations related to client authentication
# + circuitBreaker - Configurations associated with the behaviour of the Circuit Breaker
# + retryConfig - Configurations associated with retrying
# + cookieConfig - Configurations associated with cookies
# + responseLimits - Configurations associated with inbound response size limits
public type CommonClientConfiguration record {|
    string httpVersion = HTTP_1_1;
    ClientHttp1Settings http1Settings = {};
    ClientHttp2Settings http2Settings = {};
    decimal timeout = 60;
    string forwarded = "disable";
    FollowRedirects? followRedirects = ();
    PoolConfiguration? poolConfig = ();
    CacheConfig cache = {};
    Compression compression = COMPRESSION_AUTO;
    ClientAuthConfig? auth = ();
    CircuitBreakerConfig? circuitBreaker = ();
    RetryConfig? retryConfig = ();
    CookieConfig? cookieConfig = ();
    ResponseLimitConfigs responseLimits = {};
|};

# Represents a server-provided hyperlink
public type Link record {
    # Names the relationship of the linked target to the current representation
    string rel;
    # Target URL
    string href;
    # Expected resource representation media types
    string[] types?;
    # Allowed resource methods
    Method[] methods?;
};

# Represents available server-provided links
public type Links record {|
    # Array of available links
    Link[] links;
|};

# Represents the parsed header value details
public type HeaderValue record {|
    # The header value
    string value;
    # Map of header parameters
    map<string> params;
|};
