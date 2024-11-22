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

# Contains the configurations for an HTTP service.
#
# + host - Domain name of the service
# + compression - The status of compression
# + chunking - Configures the chunking behaviour for the service
# + cors - The cross origin resource sharing configurations for the service
# + auth - Service auth configurations
# + mediaTypeSubtypePrefix - Service specific media-type subtype prefix
# + treatNilableAsOptional - Treat Nilable parameters as optional
# + openApiDefinition - The generated OpenAPI definition for the HTTP service. This is auto-generated at compile-time if OpenAPI doc auto generation is enabled
# + validation - Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
# + serviceType - The service object type which defines the service contract. This is auto-generated at compile-time
# + basePath - Base path to be used with the service implementation. This is only allowed on service contract types
# + laxDataBinding - Enables or disalbles relaxed data binding on the service side. Disabled by default
public type HttpServiceConfig record {|
    string host = "b7a.default";
    CompressionConfig compression = {};
    Chunking chunking = CHUNKING_AUTO;
    CorsConfig cors = {};
    ListenerAuthConfig[] auth?;
    string mediaTypeSubtypePrefix?;
    boolean treatNilableAsOptional = true;
    byte[] openApiDefinition = [];
    boolean validation = true;
    typedesc<ServiceContract> serviceType?;
    string basePath?;
    boolean laxDataBinding = false;
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

# The annotation which is used to configure an HTTP service.
public annotation HttpServiceConfig ServiceConfig on service, type;

# Configuration for an HTTP resource.
#
# + name - The name of the resource
# + consumes - The media types which are accepted by resource
# + produces - The media types which are produced by resource
# + cors - The cross origin resource sharing configurations for the resource. If not set, the resource will inherit the CORS behaviour of the enclosing service.
# + transactionInfectable - Allow to participate in the distributed transactions if value is true
# + auth - Resource auth configurations
# + linkedTo - The array of linked resources
public type HttpResourceConfig record {|
    string name?;
    string[] consumes = [];
    string[] produces = [];
    CorsConfig cors = {};
    boolean transactionInfectable = true;
    ListenerAuthConfig[]|Scopes auth?;
    LinkedTo[] linkedTo?;
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
    // TODO : allow error type once the limitation in typedesc is resolved
    typedesc<ResponseMessage|StatusCodeResponse|Error> respondType?;
|};

# The annotation which is used to configure the type of the response.
public annotation HttpCallerInfo CallerInfo on parameter;

# Defines the Header resource signature parameter.
#
# + name - Specifies the name of the required header
public type HttpHeader record {|
    string name?;
|};

# The annotation which is used to define the Header parameter.
public const annotation HttpHeader Header on parameter, record field;

# Defines the query resource signature parameter.
# 
# + name - Specifies the name of the query parameter
public type HttpQuery record {|
    string name?;
|};

# The annotation which is used to define the query parameter.
public const annotation HttpQuery Query on parameter, record field;

# Defines the HTTP response cache configuration. By default the `no-cache` directive is setted to the `cache-control`
# header. In addition to that `etag` and `last-modified` headers are also added for cache validation.
#
# + mustRevalidate - Sets the `must-revalidate` directive
# + noCache - Sets the `no-cache` directive
# + noStore - Sets the `no-store` directive
# + noTransform - Sets the `no-transform` directive
# + isPrivate - Sets the `private` and `public` directives
# + proxyRevalidate - Sets the `proxy-revalidate` directive
# + maxAge - Sets the `max-age` directive. Default value is 3600 seconds
# + sMaxAge - Sets the `s-maxage` directive
# + noCacheFields - Optional fields for the `no-cache` directive. Before sending a listed field in a response, it
#                   must be validated with the origin server
# + privateFields - Optional fields for the `private` directive. A cache can omit the fields specified and store
#                   the rest of the response
# + setETag - Sets the `etag` header for the given payload
# + setLastModified - Sets the current time as the `last-modified` header
public type HttpCacheConfig record {|
    boolean mustRevalidate = true;
    boolean noCache = false;
    boolean noStore = false;
    boolean noTransform = false;
    boolean isPrivate = false;
    boolean proxyRevalidate = false;
    decimal maxAge = 3600;
    decimal sMaxAge = -1;
    string[] noCacheFields = [];
    string[] privateFields = [];
    boolean setETag = true;
    boolean setLastModified = true;
|};

# The annotation which is used to define the response cache configuration. This annotation only supports `anydata` and
# Success(2XX) `StatusCodeResponses` return types. Default annotation adds `must-revalidate,public,max-age=3600` as
# `cache-control` header in addition to `etag` and `last-modified` headers.
public annotation HttpCacheConfig Cache on return;
