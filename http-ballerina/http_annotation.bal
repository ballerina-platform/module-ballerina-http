// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

///////////////////////////
/// Service Annotations ///
///////////////////////////

# Contains the configurations for an HTTP service.
#
# + host - Domain name of the service
# + compression - The status of compression
# + chunking - Configures the chunking behaviour for the service
# + cors - The cross origin resource sharing configurations for the service
public type HttpServiceConfig record {|
    string host = "b7a.default";
    CompressionConfig compression = {};
    Chunking chunking = CHUNKING_AUTO;
    CorsConfig cors = {};
|};

# Configurations for CORS support.
#
# + allowHeaders - The array of allowed headers by the service
# + allowMethods - The array of allowed methods by the service
# + allowOrigins - The array of origins with which the response is shared by the service
# + exposeHeaders - The allowlisted headers, which clients are allowed to access
# + allowCredentials - Specifies whether credentials are required to access the service
# + maxAge - The maximum duration to cache the preflight from client side
public type CorsConfig record {|
    string[] allowHeaders = [];
    string[] allowMethods = [];
    string[] allowOrigins = [];
    string[] exposeHeaders = [];
    boolean allowCredentials = false;
    int maxAge= -1;
|};

# Configurations for a WebSocket service.
#
# + path - Path of the WebSocket service
# + subProtocols - Negotiable sub protocol by the service
# + idleTimeoutInSeconds - Idle timeout for the client connection. Upon timeout, `onIdleTimeout` resource (if defined)
#                          in the server service will be triggered. Note that this overrides the `timeoutInMillis` config
#                          in the `http:Listener`.
# + maxFrameSize - The maximum payload size of a WebSocket frame in bytes.
#                  If this is not set or is negative or zero, the default frame size will be used.
public type WSServiceConfig record {|
    string path = "";
    string[] subProtocols = [];
    int idleTimeoutInSeconds = 0;
    int maxFrameSize = 0;
|};

// TODO: Enable this when Ballerina supports service life time
//public type HttpServiceLifeTime "REQUEST"|"CONNECTION"|"SESSION"|"SINGLETON";

# The annotation which is used to configure an HTTP service.
public annotation HttpServiceConfig ServiceConfig on service;

# The annotation which is used to configure a WebSocket service.
public annotation WSServiceConfig WebSocketServiceConfig on service;

////////////////////////////
/// Resource Annotations ///
////////////////////////////

# Configuration for an HTTP resource.
#
# + body - Inbound request entity body name which declared in signature
# + consumes - The media types which are accepted by resource
# + produces - The media types which are produced by resource
# + cors - The cross origin resource sharing configurations for the resource. If not set, the resource will inherit the CORS behaviour of the enclosing service.
# + transactionInfectable - Allow to participate in the distributed transactions if value is true
# + webSocketUpgrade - Annotation to define HTTP to WebSocket upgrade
public type HttpResourceConfig record {|
    string[] consumes = [];
    string[] produces = [];
    CorsConfig cors = {};
    boolean transactionInfectable = true;
    WebSocketUpgradeConfig? webSocketUpgrade = ();
|};

# Resource configuration to upgrade from HTTP to WebSocket.
#
# + upgradePath - Path which is used to upgrade from HTTP to WebSocket
# + upgradeService - Callback service for a successful upgrade
public type WebSocketUpgradeConfig record {|
    string upgradePath = "";
    Service upgradeService?;
|};

# The annotation which is used to configure an HTTP resource.
public annotation HttpResourceConfig ResourceConfig on object function;

# Path param order config keep the signature path param index against the variable names for runtime path param processing.
#
# + pathParamOrder - Specifies index of signature path param against the param variable name
type HttpParamOrderConfig record {|
    map<int> pathParamOrder = {};
|};

//# The annotation which is used to configure an path param order.
annotation HttpParamOrderConfig ParamOrderConfig on object function;

# Defines the Payload resource signature parameter and return parameter.
#
# + mediaType - Specifies the allowed media types of the corresponding payload type
public type HttpPayload record {|
    string|string[] mediaType = "";
|};

# The annotation which is used to define the Payload resource signature parameter and return parameter.
public annotation HttpPayload Payload on parameter;

# Configures the typing details type of the Caller resource signature parameter.
public type HttpCallerInfo record {|
|};

# The annotation which is used to configure the type of the response.
public annotation HttpCallerInfo CallerInfo on parameter;

# Defines the Header resource signature parameter.
#
# + name - Specifies the name of the required header
public type HttpHeader record {|
    string name?;
|};

# The annotation which is used to define the Header resource signature parameter.
public annotation HttpHeader Header on parameter;
