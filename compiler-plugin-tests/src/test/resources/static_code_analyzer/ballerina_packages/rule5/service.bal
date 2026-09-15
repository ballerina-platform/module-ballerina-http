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

// Wildcard origin combined with credentials
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true
    }
}
service /credentialed on new http:Listener(8080) {
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["*"],
            allowCredentials: true
        }
    }
    resource function get greet() returns string? {
        return;
    }
}

// Negative case - wildcard origin without credentials triggers only ballerina/http:2
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false
    }
}
service /wildcardOnly on new http:Listener(8081) {
    resource function get greet() returns string? {
        return;
    }
}

// Negative case - credentials with an explicit origin is not flagged
@http:ServiceConfig {
    cors: {
        allowOrigins: ["https://example.com"],
        allowCredentials: true
    }
}
service /explicitOrigin on new http:Listener(8082) {
    resource function get greet() returns string? {
        return;
    }
}
