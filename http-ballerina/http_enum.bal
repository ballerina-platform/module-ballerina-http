// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Defines the supported HTTP protocols.
#
# `HTTP_1_0`: HTTP/1.0 protocol
# `HTTP_1_1`: HTTP/1.1 protocol
# `HTTP_2_0`: HTTP/2.0 protocol
public enum HttpVersion {
    HTTP_1_0,
    HTTP_1_1,
    HTTP_2_0
}

# Defines the possible values for the chunking configuration in HTTP services and clients.
#
# `AUTO`: If the payload is less than 8KB, content-length header is set in the outbound request/response,
#         otherwise chunking header is set in the outbound request/response
# `ALWAYS`: Always set chunking header in the response
# `NEVER`: Never set the chunking header even if the payload is larger than 8KB in the outbound request/response
public enum Chunking {
    CHUNKING_AUTO,
    CHUNKING_ALWAYS,
    CHUNKING_NEVER
}

# Options to compress using gzip or deflate.
#
# `AUTO`: When service behaves as a HTTP gateway inbound request/response accept-encoding option is set as the
#         outbound request/response accept-encoding/content-encoding option
# `ALWAYS`: Always set accept-encoding/content-encoding in outbound request/response
# `NEVER`: Never set accept-encoding/content-encoding header in outbound request/response
public enum Compression {
    COMPRESSION_AUTO,
    COMPRESSION_ALWAYS,
    COMPRESSION_NEVER
}

# Defines the position of the headers in the request/response.
#
# `LEADING`: Header is placed before the payload of the request/response
# `TRAILING`: Header is placed after the payload of the request/response
public enum HeaderPosition {
   LEADING,
   TRAILING
}

# Defines the possible values for the keep-alive configuration in service and client endpoints.
# Decides to keep the connection alive or not based on the `connection` header of the client request
# Keeps the connection alive irrespective of the `connection` header value
# Closes the connection irrespective of the `connection` header value
public enum KeepAlive {
    KEEPALIVE_AUTO,
    KEEPALIVE_ALWAYS,
    KEEPALIVE_NEVER
}

# Defines the possible values for the mutual ssl status.
#
# `passed`: Mutual SSL handshake is successful.
# `failed`: Mutual SSL handshake has failed.
public enum MutualSslStatus {
    PASSED,
    FAILED,
    NONE
}

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
