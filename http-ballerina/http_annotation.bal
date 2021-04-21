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
# + auth - Listener authenticaton configurations
public type HttpServiceConfig record {|
    string host = "b7a.default";
    CompressionConfig compression = {};
    Chunking chunking = CHUNKING_AUTO;
    CorsConfig cors = {};
    ListenerAuthConfig[] auth?;
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
    decimal maxAge= -1;
|};

// TODO: Enable this when Ballerina supports service life time
//public type HttpServiceLifeTime "REQUEST"|"CONNECTION"|"SESSION"|"SINGLETON";

# The annotation which is used to configure an HTTP service.
public annotation HttpServiceConfig ServiceConfig on service;

////////////////////////////
/// Resource Annotations ///
////////////////////////////

# Configuration for an HTTP resource.
#
# + consumes - The media types which are accepted by resource
# + produces - The media types which are produced by resource
# + cors - The cross origin resource sharing configurations for the resource. If not set, the resource will inherit the CORS behaviour of the enclosing service.
# + transactionInfectable - Allow to participate in the distributed transactions if value is true
# + auth - Listener authenticaton configurations
public type HttpResourceConfig record {|
    string[] consumes = [];
    string[] produces = [];
    CorsConfig cors = {};
    boolean transactionInfectable = true;
    ListenerAuthConfig[] auth?;
|};

# The annotation which is used to configure an HTTP resource.
public annotation HttpResourceConfig ResourceConfig on object function;

# Defines the Payload resource signature parameter and return parameter.
#
# + mediaType - Specifies the allowed media types of the corresponding payload type
public type HttpPayload record {|
    string|string[] mediaType?;
|};

# The annotation which is used to define the Payload resource signature parameter and return parameter.
public annotation HttpPayload Payload on parameter, return;

# Configures the typing details type of the Caller resource signature parameter.
#
# + respondType - Specifies the type of response
public type HttpCallerInfo record {|
    typedesc<ResponseMessage> respondType?;
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
