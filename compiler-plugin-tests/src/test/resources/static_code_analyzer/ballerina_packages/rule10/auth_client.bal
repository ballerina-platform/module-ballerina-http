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

// The token endpoint client accepts any certificate
function disabledTokenEndpointTls() returns http:Client|error {
    return new ("https://api.example.com", auth = {
        tokenUrl: "https://idp.example.com/token",
        clientId: "client-id",
        clientSecret: "client-secret",
        secureSocket: {
            disable: true
        }
    });
}

// The client's own transport is secured while the token exchange is not
function securedTransportUnsecuredTokenExchange() returns http:Client|error {
    return new ("https://api.example.com", {
        auth: {
            tokenUrl: "https://idp.example.com/token",
            clientId: "client-id",
            clientSecret: "client-secret",
            secureSocket: {
                disable: true
            }
        },
        secureSocket: {
            cert: "/path/to/public.crt"
        }
    });
}

// Negative case - the token endpoint client validates the certificate
function securedTokenEndpoint() returns http:Client|error {
    return new ("https://api.example.com", auth = {
        tokenUrl: "https://idp.example.com/token",
        clientId: "client-id",
        clientSecret: "client-secret",
        secureSocket: {
            cert: "/path/to/public.crt"
        }
    });
}
