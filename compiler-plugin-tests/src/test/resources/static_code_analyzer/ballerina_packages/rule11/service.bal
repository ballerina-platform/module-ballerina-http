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

listener http:Listener securedListener = new (9090, secureSocket = {
    key: {
        certFile: "/path/to/public.crt",
        keyFile: "/path/to/private.key"
    }
});

// No signature configuration, so any self-signed token is accepted
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina"
            },
            scopes: ["admin"]
        }
    ]
}
service /unverified on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// The signature is verified but the token may have been issued for another service
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                audience: "ballerina"
            },
            scopes: ["admin"]
        }
    ]
}
service /noIssuer on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// The token is not checked against an intended audience
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                issuer: "wso2"
            },
            scopes: ["admin"]
        }
    ]
}
service /noAudience on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - signature, issuer and audience all checked
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                issuer: "wso2",
                audience: "ballerina"
            },
            scopes: ["admin"]
        }
    ]
}
service /verified on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Nothing is verified at all, so any self-signed token from any issuer is accepted
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {},
            scopes: ["admin"]
        }
    ]
}
service /noVerification on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}
