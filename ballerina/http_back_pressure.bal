// Copyright (c) 2026 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/jballerina.java;

// Maximum time (in seconds) a message transfer may sit completely still because the application has not
// consumed what is already delivered, or because the peer has not read what is already written, before the
// `timeout` is allowed to apply after all.
//
// Inbound bodies are read from the socket on demand and outbound bodies are written as the peer accepts them,
// so a slow application on either end legitimately holds a transfer still. That is not the remote endpoint's
// fault and must not fail the transfer, but excusing it forever would mean a connection could never be
// reclaimed from a hung application or an unresponsive reader. Any progress at all restarts this span, so it
// only applies to a transfer that has not moved a single byte for its whole duration.
//
// A negative value excuses back-pressure indefinitely. Zero excuses none of it, restoring the behaviour of
// treating any inactivity as an idle connection.
configurable decimal maxBackPressureStallTime = 300;

isolated function externSetMaxBackPressureStallTime(decimal maxBackPressureStallTime) = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternBackPressureConfig",
    name: "setMaxBackPressureStallTime"
} external;
