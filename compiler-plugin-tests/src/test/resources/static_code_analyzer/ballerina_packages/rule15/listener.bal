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

// No ceiling on the request body, so one request can exhaust the service
function unlimitedBody() returns http:Listener|error {
    return new (9090, requestLimits = {
        maxEntityBodySize: -1
    });
}

// The same, supplied as a positional configuration record
function unlimitedBodyInline() returns http:Listener|error {
    return new (9091, {
        requestLimits: {
            maxUriLength: 4096,
            maxEntityBodySize: -1
        }
    });
}

// Negative case - a bounded request body
function boundedBody() returns http:Listener|error {
    return new (9092, requestLimits = {
        maxEntityBodySize: 1048576
    });
}
