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

// Noncompliant: discloses the product version.
listener http:Listener versionedListener = new (9090, server = "ballerina/2201.13.5");

// Noncompliant: version disclosed through a configuration record.
listener http:Listener configuredListener = new (9091, {server: "nginx/1.25.3"});

// Compliant: a bare product name discloses no version.
listener http:Listener namedListener = new (9092, server = "gateway");

// Compliant: the header is not set at all.
listener http:Listener defaultListener = new (9093);

service /a on versionedListener {
    resource function get one() returns string {
        return "one";
    }
}
