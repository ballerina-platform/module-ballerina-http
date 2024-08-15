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
public type RequestMessage anydata|Request|mime:Entity[]|stream<byte[], io:Error?>;

# The types of messages that are accepted by HTTP `listener` when sending out the outbound response.
public type ResponseMessage anydata|Response|mime:Entity[]|stream<byte[], io:Error?>|stream<SseEvent, error?>
                                |stream<SseEvent, error>;

# The HTTP service type.
public type Service distinct service object {

};

# The HTTP service contract type.
public type ServiceContract distinct service object {
    *Service;
};

# The types of data values that are expected by the HTTP `client` to return after the data binding operation.
public type TargetType typedesc<Response|anydata|stream<SseEvent, error?>>;

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
public type CompressionConfig record {|
    # The status of compression
    Compression enable = COMPRESSION_AUTO;
    # Content types which are allowed for compression
    string[] contentTypes = [];
|};

type HTTPError record {
    string message = "";
};

# Common client configurations for the next level clients.
public type CommonClientConfiguration record {|
    # The HTTP version understood by the client
    HttpVersion httpVersion = HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    ClientHttp1Settings http1Settings = {};
    # Configurations related to HTTP/2 protocol
    ClientHttp2Settings http2Settings = {};
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 30;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = "disable";
    # Configurations associated with Redirection
    FollowRedirects? followRedirects = ();
    # Configurations associated with request pooling
    PoolConfiguration? poolConfig = ();
    # HTTP caching related configurations
    CacheConfig cache = {};
    # Specifies the way of handling compression (`accept-encoding`) header
    Compression compression = COMPRESSION_AUTO;
    # Configurations related to client authentication
    ClientAuthConfig? auth = ();
    # Configurations associated with the behaviour of the Circuit Breaker
    CircuitBreakerConfig? circuitBreaker = ();
    # Configurations associated with retrying
    RetryConfig? retryConfig = ();
    # Configurations associated with cookies
    CookieConfig? cookieConfig = ();
    # Configurations associated with inbound response size limits
    ResponseLimitConfigs responseLimits = {};
    # Proxy server related options
    ProxyConfig? proxy = ();
    # Enables the inbound payload validation functionalty which provided by the constraint package. Enabled by default
    boolean validation = true;
    # Provides settings related to client socket configuration
    ClientSocketConfig socketConfig = {};
|};

# Represents a server-provided hyperlink
public type Link record {
    # Names the relationship of the linked target to the current representation
    string rel?;
    # Target URL
    string href;
    # Expected resource representation media types
    string[] types?;
    # Allowed resource methods
    Method[] methods?;
};

# Represents available server-provided links
public type Links record {|
    # Map of available links
    map<Link> _links;
|};

public type LinkedTo record {|
    # Name of the linked resource
    string name;
    # Name of the relationship between the linked resource and the current resource.
    # Defaulted to the IANA link relation `self`
    string relation = "self";
    # Method allowed in the linked resource
    string method?;
|};

# Represents the parsed header value details
public type HeaderValue record {|
    # The header value
    string value;
    # Map of header parameters
    map<string> params;
|};

# Represents a Server Sent Event emitted from a service.
public type SseEvent record {|
    # Name of the event
    string event?; 
    # Id of the event
    string id?;
    # Data part of the event
    string data?; 
    # The reconnect time on failure in milliseconds.
    int 'retry?;
    # Comment added to the event
    string comment?;
|};

# Dummy types used in the compiler plugin
type ResourceReturnType Response|StatusCodeResponse|anydata|stream<SseEvent, error?>|stream<SseEvent, error>|error;
type InterceptorResourceReturnType ResourceReturnType|NextService;
