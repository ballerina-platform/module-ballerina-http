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

// Authorization headers forwarded to whatever host the redirect names
function forwardsCredentials() returns http:Client|error {
    return new ("https://api.example.com", followRedirects = {
        enabled: true,
        allowAuthHeaders: true
    });
}

// The same, supplied as a positional configuration record
function forwardsCredentialsInline() returns http:Client|error {
    return new ("https://api.example.com", {
        followRedirects: {
            enabled: true,
            allowAuthHeaders: true
        }
    });
}

// Negative case - redirects followed with the headers stripped
function stripsCredentials() returns http:Client|error {
    return new ("https://api.example.com", followRedirects = {
        enabled: true,
        allowAuthHeaders: false
    });
}

// Negative case - the default already strips the headers
function defaultRedirects() returns http:Client|error {
    return new ("https://api.example.com", followRedirects = {
        enabled: true
    });
}
