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

// SSL turned off entirely for the client
function disabledSsl() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        enable: false
    });
}

// Host name verification turned off while the channel stays encrypted
function unverifiedHostName() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        cert: "/path/to/public.crt",
        verifyHostName: false
    });
}

// Both switched off, supplied as a positional configuration record
function disabledSslAndHostName() returns http:Client|error {
    return new ("https://api.example.com", {
        secureSocket: {
            enable: false,
            verifyHostName: false
        }
    });
}

// Negative case - validation left at its secure defaults
function secureClient() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        cert: "/path/to/public.crt"
    });
}

// Negative case - validation explicitly enabled
function explicitlySecureClient() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = {
        enable: true,
        cert: "/path/to/public.crt",
        verifyHostName: true
    });
}

// A target of a failover client accepts any certificate
function failoverTargetWithoutValidation() returns http:FailoverClient|error {
    return new ({
        targets: [
            {url: "https://primary.example.com", secureSocket: {cert: "/path/to/public.crt"}},
            {url: "https://backup.example.com", secureSocket: {enable: false}}
        ]
    });
}

// The included configuration record passed by its parameter name
function configPassedByName() returns http:Client|error {
    return new ("https://api.example.com", config = {
        secureSocket: {
            verifyHostName: false
        }
    });
}

// The secure socket held in an immutable variable, reported at the argument that references it
final http:ClientSecureSocket & readonly insecureSocket = {enable: false};

function secureSocketFromVariable() returns http:Client|error {
    return new ("https://api.example.com", secureSocket = insecureSocket);
}

// The configuration declared in another file, reported here at the argument that references it
function configFromAnotherFile() returns http:Client|error {
    return new ("https://api.example.com", sharedInsecureConfig);
}

// Negative case - a mutable configuration may be changed before use, so its initializer is not followed
function mutableConfig() returns http:Client|error {
    http:ClientConfiguration config = {};
    config.secureSocket = {cert: "/path/to/public.crt"};
    return new ("https://api.example.com", config);
}
