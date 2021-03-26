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

# Represents http protocol scheme
const string HTTP_SCHEME = "http://";

# Represents https protocol scheme
const string HTTPS_SCHEME = "https://";

# Constant for the default listener endpoint timeout
const decimal DEFAULT_LISTENER_TIMEOUT = 120; //2 mins

# Constant for the default failover starting index for failover endpoints
const int DEFAULT_FAILOVER_EP_STARTING_INDEX = 0;

# Maximum number of requests that can be processed at a given time on a single connection.
const int MAX_PIPELINED_REQUESTS = 10;

# Represents multipart primary type
public const string MULTIPART_AS_PRIMARY_TYPE = "multipart/";

# Constant for the HTTP FORWARD method
public const HTTP_FORWARD = "FORWARD";

# Constant for the HTTP GET method
public const HTTP_GET = "GET";

# Constant for the HTTP POST method
public const HTTP_POST = "POST";

# Constant for the HTTP DELETE method
public const HTTP_DELETE = "DELETE";

# Constant for the HTTP OPTIONS method
public const HTTP_OPTIONS = "OPTIONS";

# Constant for the HTTP PUT method
public const HTTP_PUT = "PUT";

# Constant for the HTTP PATCH method
public const HTTP_PATCH = "PATCH";

# Constant for the HTTP HEAD method
public const HTTP_HEAD = "HEAD";

# constant for the HTTP SUBMIT method
public const HTTP_SUBMIT = "SUBMIT";

# Constant for the identify not an HTTP Operation
public const HTTP_NONE = "NONE";

# Constant for telemetry tag http.url
const HTTP_URL = "http.url";

# Constant for telemetry tag http.method
const HTTP_METHOD = "http.method";

# Constant for telemetry tag http.status_code_group
const HTTP_STATUS_CODE_GROUP = "http.status_code_group";

# Constant for telemetry tag http.status_code
const HTTP_STATUS_CODE = "http.status_code";

# Constant for telemetry tag http.base_url
const HTTP_BASE_URL = "http.base_url";

# Constant for status code range suffix
const STATUS_CODE_GROUP_SUFFIX = "xx";

# Represents RFC_1123_DATE_TIME formatter
const string RFC_1123_DATE_TIME = "RFC_1123_DATE_TIME";

# Constant for the service name reference.
public const SERVICE_NAME = "SERVICE_NAME";
# Constant for the resource name reference.
public const RESOURCE_NAME = "RESOURCE_NAME";
# Constant for the request method reference.
public const REQUEST_METHOD = "REQUEST_METHOD";

# Defines the possible values for the mutual ssl status.
#
# `passed`: Mutual SSL handshake is successful.
# `failed`: Mutual SSL handshake has failed.
public type MutualSslStatus PASSED | FAILED | ();

# Mutual SSL handshake is successful.
public const PASSED = "passed";

# Mutual SSL handshake has failed.
public const FAILED = "failed";

# Not a mutual ssl connection.
public const NONE = ();
