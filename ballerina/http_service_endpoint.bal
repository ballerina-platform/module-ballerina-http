// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/jballerina.java;

# This is used for creating HTTP server endpoints. An HTTP server endpoint is capable of responding to
# remote callers. The `Listener` is responsible for initializing the endpoint using the provided configurations.
public isolated class Listener {

    private int port;
    private InferredListenerConfiguration inferredConfig;

    # Gets invoked during module initialization to initialize the listener.
    #
    # + port - Listening port of the HTTP service listener
    # + config - Configurations for the HTTP service listener
    # + return - A `ListenerError` if an error occurred during the listener initialization
    public isolated function init(int port, *ListenerConfiguration config) returns ListenerError? {
        InferredListenerConfiguration inferredListenerConfig = {
            host: config.host,
            http1Settings: config.http1Settings,
            secureSocket: config.secureSocket,
            httpVersion: config.httpVersion,
            timeout: config.timeout,
            server: config.server,
            requestLimits: config.requestLimits
        };
        self.inferredConfig = inferredListenerConfig.cloneReadOnly();
        self.port = port;
        return externInitEndpoint(self, config);
    }

    isolated function createInterceptors() returns Interceptor[] {
        return [new DefaultErrorInterceptor()];
    }

    # Starts the registered service programmatically.
    #
    # + return - An `error` if an error occurred during the listener starting process
    public isolated function 'start() returns error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.service.endpoint.Start"
    } external;

    # Stops the service listener gracefully. Already-accepted requests will be served before connection closure.
    #
    # + return - An `error` if an error occurred during the listener stopping process
    public isolated function gracefulStop() returns error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.service.endpoint.GracefulStop"
    } external;

    # Stops the service listener immediately. It is not implemented yet.
    #
    # + return - An `error` if an error occurred during the listener stop process
    public isolated function immediateStop() returns error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.service.endpoint.ImmediateStop"
    } external;

    # Attaches a service to the listener.
    #
    # + httpService - The service that needs to be attached
    # + name - Name of the service
    # + return - An `error` if an error occurred during the service attachment process or else `()`
    public isolated function attach(Service httpService, string[]|string? name = ()) returns error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.service.endpoint.Register",
        name: "register"
    } external;

    # Detaches an HTTP service from the listener.
    #
    # + httpService - The service to be detached
    # + return - An `error` if one occurred during detaching of a service or else `()`
    public isolated function detach(Service httpService) returns error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.service.endpoint.Detach"
    } external;

    # Retrieves the port of the HTTP listener.
    #
    # + return - The HTTP listener port
    public isolated function getPort() returns int {
        lock {
            return self.port;
        }
    }

    # Retrieves the `InferredListenerConfiguration` of the HTTP listener.
    #
    # + return - The readonly HTTP listener inferred configuration
    public isolated function getConfig() returns readonly & InferredListenerConfiguration {
        lock {
            return <readonly & InferredListenerConfiguration> self.inferredConfig.cloneReadOnly();
        }
    }
}

isolated function externInitEndpoint(Listener listenerObj, ListenerConfiguration config) returns ListenerError? =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.service.endpoint.InitEndpoint",
    name: "initEndpoint"
} external;

# Presents a read-only view of the remote address.
#
# + host - The remote host name
# + port - The remote port
# + ip - The remote IP address
public type Remote record {|
    string host;
    int port;
    string ip;
|};

# Presents a read-only view of the local address.
#
# + host - The local host name
# + port - The local port
# + ip - The local IP address
public type Local record {|
    string host;
    int port;
    string ip;
|};

# Provides a set of configurations for HTTP service endpoints.
#
# + host - The host name/IP of the endpoint
# + http1Settings - Configurations related to HTTP/1.x protocol
# + secureSocket - The SSL configurations for the service endpoint. This needs to be configured in order to
#                  communicate through HTTPS.
# + httpVersion - Highest HTTP version supported by the endpoint
# + timeout - Period of time in seconds that a connection waits for a read/write operation. Use value 0 to
#                   disable timeout
# + server - The server name which should appear as a response header
# + requestLimits - Configurations associated with inbound request size limits
# + gracefulStopTimeout - Grace period of time in seconds for listener gracefulStop
# + socketConfig - Provides settings related to server socket configuration
# + http2InitialWindowSize - Configuration to change the initial window size in HTTP/2
# + minIdleTimeInStaleState - Minimum time in seconds for a connection to be kept open which has received a GOAWAY.
#                             This only applies for HTTP/2. Default value is 5 minutes. If the value is set to -1,
#                             the connection will be closed after all in-flight streams are completed
# + timeBetweenStaleEviction - Time between the connection stale eviction runs in seconds. This only applies for HTTP/2.
#                              Default value is 30 seconds
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
    ListenerHttp1Settings http1Settings = {};
    ListenerSecureSocket? secureSocket = ();
    HttpVersion httpVersion = HTTP_2_0;
    decimal timeout = DEFAULT_LISTENER_TIMEOUT;
    string? server = ();
    RequestLimitConfigs requestLimits = {};
    decimal gracefulStopTimeout = DEFAULT_GRACEFULSTOP_TIMEOUT;
    ServerSocketConfig socketConfig = {};
    int http2InitialWindowSize = 65535;
    decimal minIdleTimeInStaleState = 300;
    decimal timeBetweenStaleEviction = 30;
|};

# Provides a set of cloneable configurations for HTTP listener.
#
# + host - The host name/IP of the endpoint
# + http1Settings - Configurations related to HTTP/1.x protocol
# + secureSocket - The SSL configurations for the service endpoint. This needs to be configured in order to
#                  communicate through HTTPS.
# + httpVersion - Highest HTTP version supported by the endpoint
# + timeout - Period of time in seconds that a connection waits for a read/write operation. Use value 0 to
#                   disable timeout
# + server - The server name which should appear as a response header
# + requestLimits - Configurations associated with inbound request size limits
public type InferredListenerConfiguration record {|
    string host;
    ListenerHttp1Settings http1Settings;
    ListenerSecureSocket? secureSocket;
    HttpVersion httpVersion;
    decimal timeout;
    string? server;
    RequestLimitConfigs requestLimits;
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
#                  response. For HTTP/2, this limit will not be applicable as it already has a `:path`
#                  pseudo-header which will be validated by `maxHeaderSize`
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

# Provides settings related to server socket configuration.
#
# + soBackLog - Requested maximum length of the queue of incoming connections.
public type ServerSocketConfig record {|
    *ClientSocketConfig;
    int soBackLog = 100;
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

# Represents client verify options.
public enum VerifyClient {
   REQUIRE,
   OPTIONAL
}

# Represents protocol options.
public enum Protocol {
   SSL,
   TLS,
   DTLS
}

# Represents certification validation type options.
public enum CertValidationType {
   OCSP_CRL,
   OCSP_STAPLING
}

# Defines the possible values for the keep-alive configuration in service and client endpoints.
public type KeepAlive KEEPALIVE_AUTO|KEEPALIVE_ALWAYS|KEEPALIVE_NEVER;

# Decides to keep the connection alive or not based on the `connection` header of the client request }
public const KEEPALIVE_AUTO = "AUTO";
# Keeps the connection alive irrespective of the `connection` header value }
public const KEEPALIVE_ALWAYS = "ALWAYS";
# Closes the connection irrespective of the `connection` header value }
public const KEEPALIVE_NEVER = "NEVER";

# Constant for the service name reference.
public const SERVICE_NAME = "SERVICE_NAME";
# Constant for the resource name reference.
public const RESOURCE_NAME = "RESOURCE_NAME";
# Constant for the request method reference.
public const REQUEST_METHOD = "REQUEST_METHOD";
