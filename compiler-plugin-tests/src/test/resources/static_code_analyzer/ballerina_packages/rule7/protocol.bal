// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com)
//
// WSO2 LLC. licenses this file to you under the Apache License,
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


import ballerina/http;

// The SSL protocol family selected by name
function sslProtocolClient() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        cert: "/path/to/public.crt",
        protocol: {
            name: http:SSL,
            versions: ["TLSv1.2"]
        }
    });
}

// Withdrawn TLS versions named on a client
function weakVersionsClient() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        cert: "/path/to/public.crt",
        protocol: {
            name: http:TLS,
            versions: ["TLSv1.0", "TLSv1.1", "TLSv1.2"]
        }
    });
}

// Withdrawn TLS version named on a listener
function weakVersionsListener() returns http:Listener|error {
    return new (9090, secureSocket = {
        key: {
            certFile: "/path/to/public.crt",
            keyFile: "/path/to/private.key"
        },
        protocol: {
            name: http:TLS,
            versions: ["SSLv3"]
        }
    });
}

// Negative case - current TLS versions only
function secureProtocolClient() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        cert: "/path/to/public.crt",
        protocol: {
            name: http:TLS,
            versions: ["TLSv1.2", "TLSv1.3"]
        }
    });
}
