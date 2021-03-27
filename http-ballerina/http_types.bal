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

import ballerina/crypto;
import ballerina/io;
import ballerina/mime;

# The types of messages that are accepted by HTTP `client` when sending out the outbound request.
public type RequestMessage Request|string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|
                           (map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>|();

# The types of messages that are accepted by HTTP `listener` when sending out the outbound response.
public type ResponseMessage Response|string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|
                            (map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>|();

# The HTTP service type
public type Service service object {

};

# The types of the response payload that are returned by the HTTP `client` after the data binding operation
public type PayloadType string|xml|json|byte[]|record {| anydata...; |}|record {| anydata...; |}[];

# The types of data values that are expected by the HTTP `client` to return after the data binding operation
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
type HttpOperation HTTP_FORWARD|HTTP_GET|HTTP_POST|HTTP_DELETE|HTTP_OPTIONS|HTTP_PUT|HTTP_PATCH|HTTP_HEAD|
                   HTTP_SUBMIT|HTTP_NONE;
# Defines the safe HTTP operations which do not modify resource representation.
type safeHttpOperation HTTP_GET|HTTP_HEAD|HTTP_OPTIONS;

# Common type used for HttpFuture and Response used for resiliency clients.
type HttpResponse Response|HttpFuture;

# A record for providing configurations for content compression.
#
# + enable - The status of compression
# + contentTypes - Content types which are allowed for compression
public type CompressionConfig record {|
    Compression enable = COMPRESSION_AUTO;
    string[] contentTypes = [];
|};

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
    HttpVersion httpVersion = HTTP_1_1;
    ClientHttp1Settings http1Settings = {};
    ClientHttp2Settings http2Settings = {};
    decimal timeout = 60;
    Forwarded forwarded = FORWARDED_DISABLE;
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

# Presents the remote address.
#
# + host - The remote host IP
# + port - The remote port
public type Remote record {|
    string host = "";
    int port = 0;
|};

# Presents the local address.
#
# + host - The local host name/IP
# + port - The local port
public type Local record {|
    string host = "";
    int port = 0;
|};

# Provides a set of configurations for HTTP service endpoints.
#
# + host - The host name/IP of the endpoint
# + http1Settings - Configurations related to HTTP/1.x protocol
# + secureSocket - The SSL configurations for the service endpoint. This needs to be configured in order to
#                  communicate through HTTPS.
# + httpVersion - Highest HTTP version supported by the endpoint
# + timeout - Period of time in seconds that a connection waits for a read/write operation. Use value 0 to
#             disable timeout
# + server - The server name which should appear as a response header
# + requestLimits - Configurations associated with inbound request size limits
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
    ListenerHttp1Settings http1Settings = {};
    ListenerSecureSocket secureSocket?;
    HttpVersion httpVersion = HTTP_1_1;
    decimal timeout = DEFAULT_LISTENER_TIMEOUT;
    string server?;
    RequestLimitConfigs requestLimits = {};
|};

# Provides settings related to HTTP/1.x protocol.
#
# + keepAlive - Can be set to either `KEEPALIVE_AUTO`, which respects the `connection` header, or `KEEPALIVE_ALWAYS`,
#               which always keeps the connection alive, or `KEEPALIVE_NEVER`, which always closes the connection
# + maxPipelinedRequests - Defines the maximum number of requests that can be processed at a given time on a single
#                          connection. By default 10 requests can be pipelined on a single connection and user can
#                          change this limit appropriately.
public type ListenerHttp1Settings record {|
    KeepAlive keepAlive = KEEPALIVE_AUTO;
    int maxPipelinedRequests = MAX_PIPELINED_REQUESTS;
|};

# Provides inbound request URI, total header and entity body size threshold configurations.
#
# + maxUriLength - Maximum allowed length for a URI. Exceeding this limit will result in a `414 - URI Too Long`
#                  response
# + maxHeaderSize - Maximum allowed size for headers. Exceeding this limit will result in a
#                   `431 - Request Header Fields Too Large` response
# + maxEntityBodySize - Maximum allowed size for the entity body. By default it is set to -1 which means there
#                       is no restriction `maxEntityBodySize`, On the Exceeding this limit will result in a
#                       `413 - Payload Too Large` response
public type RequestLimitConfigs record {|
    int maxUriLength = 4096;
    int maxHeaderSize = 8192;
    int maxEntityBodySize = -1;
|};

# Configures the SSL/TLS options to be used for HTTP service.
#
# + key - Configurations associated with `crypto:KeyStore` or combination of certificate and (PKCS8) private key of the server
# + mutualSsl - Configures associated with mutual SSL operations
# + protocol - SSL/TLS protocol related options
# + certValidation - Certificate validation against OCSP_CRL, OCSP_STAPLING related options
# + ciphers - List of ciphers to be used
#             eg: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
# + shareSession - Enable/Disable new SSL session creation
# + handshakeTimeout - SSL handshake time out
# + sessionTimeout - SSL session time out
public type ListenerSecureSocket record {|
    crypto:KeyStore|CertKey key;
    record {|
        VerifyClient verifyClient = REQUIRE;
        crypto:TrustStore|string cert;
    |} mutualSsl?;
    record {|
        Protocol name;
        string[] versions = [];
    |} protocol?;
    record {|
        CertValidationType 'type = OCSP_STAPLING;
        int cacheSize;
        int cacheValidityPeriod;
    |} certValidation?;
    string[] ciphers = ["TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA", "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256"];
    boolean shareSession = true;
    decimal handshakeTimeout?;
    decimal sessionTimeout?;
|};

# Represents combination of certificate, private key and private key password if encrypted.
#
# + certFile - A file containing the certificate
# + keyFile - A file containing the private key in PKCS8 format
# + keyPassword - Password of the private key if it is encrypted
public type CertKey record {|
   string certFile;
   string keyFile;
   string keyPassword?;
|};

# A record for providing mutual SSL handshake results.
#
# + status - Status of the handshake.
# + base64EncodedCert - Base64 encoded certificate.
public type MutualSslHandshake record {|
    MutualSslStatus status = NONE;
    string base64EncodedCert?;
|};
