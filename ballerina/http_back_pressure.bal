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

// Maximum time (in seconds) a message transfer may sit still solely because of application back-pressure
// (a slow reader or writer) before `timeout` is allowed to apply after all. Negative excuses it indefinitely;
// zero excuses none of it.
configurable decimal maxBackPressureStallTime = 300;

isolated function externSetMaxBackPressureStallTime(decimal maxBackPressureStallTime) = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternBackPressureConfig",
    name: "setMaxBackPressureStallTime"
} external;
