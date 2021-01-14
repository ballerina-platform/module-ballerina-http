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
import ballerina/java;

/////////////////////////////
/// HTTP Listener Endpoint ///
/////////////////////////////
# This is used for creating HTTP server endpoints. An HTTP server endpoint is capable of responding to
# remote callers. The `Listener` is responsible for initializing the endpoint using the provided configurations.
public class Listener {

    private int port = 0;
    private ListenerConfiguration config = {};
    private string instanceId;

    # Gets invoked during module initialization to initialize the listener.
    #
    # + port - Listening port of the HTTP service listener
    # + config - Configurations for the HTTP service listener
    public isolated function init(int port, ListenerConfiguration? config = ()) {
        self.instanceId = uuid();
        self.config = config ?: {};
        self.port = port;
        addAuthFilter(self.config.filters);
        error? err = externInitEndpoint(self);
        if (err is error) {
            panic err;
        }
    }

    # Starts the registered service programmatically.
    #
    # + return - An `error` if an error occurred during the listener starting process
    public isolated function 'start() returns error? {
        return externStart(self);
    }

    # Stops the service listener gracefully. Already-accepted requests will be served before connection closure.
    #
    # + return - An `error` if an error occurred during the listener stopping process
    public isolated function gracefulStop() returns error? {
        return externGracefulStop(self);
    }

    # Stops the service listener immediately. It is not implemented yet.
    #
    # + return - An `error` if an error occurred during the listener stop process
    public isolated function immediateStop() returns error? {
        error err = error("not implemented");
        return err;
    }

    # Attaches a service to the listener.
    #
    # + s - The service that needs to be attached
    # + name - Name of the service
    # + return - An `error` an error occurred during the service attachment process or else nil
    public isolated function attach(Service s, string[]|string? name = ()) returns error? {
        return externRegister(self, s, name);
    }

    # Detaches a Http or WebSocket service from the listener. Note that detaching a WebSocket service would not affect
    # The functionality of the existing connections.
    #
    # + s - The service to be detached
    # + return - An `error` if one occurred during detaching of a service or else `()`
    public isolated function detach(Service s) returns error? {
        return externDetach(self, s);
    }

    # Retrieve the port from the HTTP listener.
    #
    # + return - The HTTP listener port
    public isolated function getPort() returns int {
        return self.port;
    }
}

isolated function externInitEndpoint(Listener listenerObj) returns error? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.InitEndpoint",
    name: "initEndpoint"
} external;

isolated function externRegister(Listener listenerObj, Service s, string[]|string? name) returns error? =
@java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Register",
    name: "register"
} external;

isolated function externStart(Listener listenerObj) returns error? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Start",
    name: "start"
} external;

isolated function externGracefulStop(Listener listenerObj) returns error? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.GracefulStop",
    name: "gracefulStop"
} external;

isolated function externDetach(Listener listenerObj, Service s) returns error? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Detach",
    name: "detach"
} external;

# Presents a read-only view of the remote address.
#
# + host - The remote host IP
# + port - The remote port
public type Remote record {|
    string host = "";
    int port = 0;
|};

# Presents a read-only view of the local address.
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
# + filters - If any pre-processing needs to be done to the request before dispatching the request to the
#             resource, filters can applied
# + timeoutInMillis - Period of time in milliseconds that a connection waits for a read/write operation. Use value 0 to
#                   disable timeout
# + server - The server name which should appear as a response header
# + webSocketCompressionEnabled - Enable support for compression in WebSocket
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
    ListenerHttp1Settings http1Settings = {};
    ListenerSecureSocket? secureSocket = ();
    string httpVersion = "1.1";
    (RequestFilter|ResponseFilter)[] filters = [];
    int timeoutInMillis = DEFAULT_LISTENER_TIMEOUT;
    string? server = ();
    boolean webSocketCompressionEnabled = true;
|};

# Provides settings related to HTTP/1.x protocol.
#
# + keepAlive - Can be set to either `KEEPALIVE_AUTO`, which respects the `connection` header, or `KEEPALIVE_ALWAYS`,
#               which always keeps the connection alive, or `KEEPALIVE_NEVER`, which always closes the connection
# + maxPipelinedRequests - Defines the maximum number of requests that can be processed at a given time on a single
#                          connection. By default 10 requests can be pipelined on a single cinnection and user can
#                          change this limit appropriately.
# + maxUriLength - Maximum allowed length for a URI. Exceeding this limit will result in a
#                  `414 - URI Too Long` response.
# + maxHeaderSize - Maximum allowed size for headers. Exceeding this limit will result in a
#                   `413 - Payload Too Large` response.
# + maxEntityBodySize - Maximum allowed size for the entity body. By default it is set to -1 which means there
#                       is no restriction `maxEntityBodySize`, On the Exceeding this limit will result in a
#                       `413 - Payload Too Large` response.
public type ListenerHttp1Settings record {|
    KeepAlive keepAlive = KEEPALIVE_AUTO;
    int maxPipelinedRequests = MAX_PIPELINED_REQUESTS;
    int maxUriLength = 4096;
    int maxHeaderSize = 8192;
    int maxEntityBodySize = -1;
|};

# Configures the SSL/TLS options to be used for HTTP service.
#
# + trustStore - Configures the trust store to be used
# + keyStore - Configures the key store to be used
# + certFile - A file containing the certificate of the server
# + keyFile - A file containing the private key of the server
# + keyPassword - Password of the private key if it is encrypted
# + trustedCertFile - A file containing a list of certificates or a single certificate that the server trusts
# + protocol - SSL/TLS protocol related options
# + certValidation - Certificate validation against CRL or OCSP related options
# + ciphers - List of ciphers to be used (e.g.: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
#             TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA)
# + sslVerifyClient - The type of client certificate verification. (e.g.: "require" or "optional")
# + shareSession - Enable/disable new SSL session creation
# + handshakeTimeoutInSeconds - SSL handshake time out
# + sessionTimeoutInSeconds - SSL session time out
# + ocspStapling - Enable/disable OCSP stapling
public type ListenerSecureSocket record {|
    crypto:TrustStore? trustStore = ();
    crypto:KeyStore? keyStore = ();
    string certFile = "";
    string keyFile = "";
    string keyPassword = "";
    string trustedCertFile = "";
    Protocols? protocol = ();
    ValidateCert? certValidation = ();
    string[] ciphers = ["TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA", "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256"];
    string sslVerifyClient = "";
    boolean shareSession = true;
    int? handshakeTimeoutInSeconds = ();
    int? sessionTimeoutInSeconds = ();
    ListenerOcspStapling? ocspStapling = ();
|};

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

// Add auth filter as the first filter of the filter chain.
isolated function addAuthFilter((RequestFilter|ResponseFilter)[] filters) {
    AuthFilter authFilter = new;
    filters.unshift(authFilter);
}
