// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Represents a single service and its related configurations.
#
# + url - URL of the target service
# + secureSocket - Configurations for secure communication with the remote HTTP endpoint
public type TargetService record {|
    string url = "";
    ClientSecureSocket? secureSocket = ();
|};

# Provides a set of configurations for controlling the behaviours when communicating with a remote HTTP endpoint.
# The following fields are inherited from the other configuration records in addition to the `Client`-specific
# configs.
#
# + secureSocket - SSL/TLS-related options
public type ClientConfiguration record {|
    *CommonClientConfiguration;
    ClientSecureSocket? secureSocket = ();
|};

# Provides settings related to HTTP/1.x protocol.
#
# + keepAlive - Specifies whether to reuse a connection for multiple requests
# + chunking - The chunking behaviour of the request
# + proxy - Proxy server related options
public type ClientHttp1Settings record {|
    KeepAlive keepAlive = KEEPALIVE_AUTO;
    Chunking chunking = CHUNKING_AUTO;
    ProxyConfig? proxy = ();
|};

# Provides inbound response status line, total header and entity body size threshold configurations.
#
# + maxStatusLineLength - Maximum allowed length for response status line(`HTTP/1.1 200 OK`). Exceeding this limit will
#                         result in a `ClientError`
# + maxHeaderSize - Maximum allowed size for headers. Exceeding this limit will result in a `ClientError`
# + maxEntityBodySize - Maximum allowed size for the entity body. By default it is set to -1 which means there is no
#                       restriction `maxEntityBodySize`, On the Exceeding this limit will result in a `ClientError`
public type ResponseLimitConfigs record {|
    int maxStatusLineLength = 4096;
    int maxHeaderSize = 8192;
    int maxEntityBodySize = -1;
|};

# Provides settings related to HTTP/2 protocol.
#
# + http2PriorKnowledge - Configuration to enable HTTP/2 prior knowledge
public type ClientHttp2Settings record {|
    boolean http2PriorKnowledge = false;
|};

# Provides configurations for controlling the retrying behavior in failure scenarios.
#
# + count - Number of retry attempts before giving up
# + interval - Retry interval in seconds
# + backOffFactor - Multiplier, which increases the retry interval exponentially.
# + maxWaitInterval - Maximum time of the retry interval in seconds
# + statusCodes - HTTP response status codes which are considered as failures
public type RetryConfig record {|
    int count = 0;
    decimal interval = 0;
    float backOffFactor = 0.0;
    decimal maxWaitInterval = 0;
    int[] statusCodes = [];
|};

# Provides configurations for facilitating secure communication with a remote HTTP endpoint.
#
# + enable - Enable SSL validation
# + cert - Configurations associated with `crypto:TrustStore` or single certificate file that the client trusts
# + key - Configurations associated with `crypto:KeyStore` or combination of certificate and private key of the client
# + protocol - SSL/TLS protocol related options
# + certValidation - Certificate validation against OCSP_CRL, OCSP_STAPLING related options
# + ciphers - List of ciphers to be used
#             eg: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
# + verifyHostName - Enable/disable host name verification
# + shareSession - Enable/disable new SSL session creation
# + handshakeTimeout - SSL handshake time out
# + sessionTimeout - SSL session time out
# + sniHostName - Server name indication(SNI) to be used. If this is not present, hostname from the target URL will be used
public type ClientSecureSocket record {|
    boolean enable = true;
    crypto:TrustStore|string cert?;
    crypto:KeyStore|CertKey key?;
    record {|
        Protocol name;
        string[] versions = [];
    |} protocol?;
    record {|
        CertValidationType 'type = OCSP_STAPLING;
        int cacheSize;
        int cacheValidityPeriod;
    |} certValidation?;
    string[] ciphers?;
    boolean verifyHostName = true;
    boolean shareSession = true;
    decimal handshakeTimeout?;
    decimal sessionTimeout?;
    string sniHostName?;
|};

# Provides configurations for controlling the endpoint's behaviour in response to HTTP redirect related responses.
# The response status codes of 301, 302, and 303 are redirected using a GET request while 300, 305, 307, and 308
# status codes use the original request HTTP method during redirection.
#
# + enabled - Enable/disable redirection
# + maxCount - Maximum number of redirects to follow
# + allowAuthHeaders - By default Authorization and Proxy-Authorization headers are removed from the redirect requests.
#                      Set it to true if Auth headers are needed to be sent during the redirection
public type FollowRedirects record {|
    boolean enabled = false;
    int maxCount = 5;
    boolean allowAuthHeaders = false;
|};

# Proxy server configurations to be used with the HTTP client endpoint.
#
# + host - Host name of the proxy server
# + port - Proxy server port
# + userName - Proxy server username
# + password - proxy server password
public type ProxyConfig record {|
    string host = "";
    int port = 0;
    string userName = "";
    string password = "";
|};

# Client configuration for cookies.
#
# + enabled - User agents provide users with a mechanism for disabling or enabling cookies
# + maxCookiesPerDomain - Maximum number of cookies per domain, which is 50
# + maxTotalCookieCount - Maximum number of total cookies allowed to be stored in cookie store, which is 3000
# + blockThirdPartyCookies - User can block cookies from third party responses and refuse to send cookies for third party requests, if needed
# + persistentCookieHandler - To manage persistent cookies, users are provided with a mechanism for specifying a persistent cookie store with their own mechanism
#                             which references the persistent cookie handler or specifying the CSV persistent cookie handler. If not specified any, only the session cookies are used
public type CookieConfig record {|
     boolean enabled = false;
     int maxCookiesPerDomain = 50;
     int maxTotalCookieCount = 3000;
     boolean blockThirdPartyCookies = true;
     PersistentCookieHandler persistentCookieHandler?;
|};

# Provides settings related to client socket configuration.
#
# + connectTimeOut - Connect timeout of the channel in seconds. If the Channel does not support connect operation,
# this property is not used at all, and therefore will be ignored.
# + receiveBufferSize - Sets the SO_RCVBUF option to the specified value for this Socket.
# + sendBufferSize - Sets the SO_SNDBUF option to the specified value for this Socket.
# + tcpNoDelay - Enable/disable TCP_NODELAY (disable/enable Nagle's algorithm).
# + socketReuse - Enable/disable the SO_REUSEADDR socket option.
# + keepAlive - Enable/disable SO_KEEPALIVE.
public type ClientSocketConfig record {|
    decimal connectTimeOut = 15;
    int receiveBufferSize = 1048576;
    int sendBufferSize = 1048576;
    boolean tcpNoDelay = true;
    boolean socketReuse = true;
    boolean keepAlive = false;
|};

# Represents HTTP methods.
public enum Method {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS
}
