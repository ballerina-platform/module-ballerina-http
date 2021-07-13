// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

public type TraceLogConfiguration record {|
    boolean consoleEnabled = false;
    string path = "";
    string host = "";
    int port = 0;
|};

public type AccessLogConfiguration record {|
    boolean consoleEnabled = false;
    string path = "";
|};

isolated function initializeHttpLogs() {
    TraceLogConfiguration & readonly traceLogConfig = {};
    AccessLogConfiguration & readonly accessLogConfig = {};
    handle httpLogManager = newHttpLogManager(traceLogConfig, accessLogConfig);
}

isolated function newHttpLogManager(TraceLogConfiguration traceLogConfig, AccessLogConfiguration accessLogConfig)
returns handle = @java:Constructor {
    'class: "io.ballerina.stdlib.http.api.logging.HttpLogManager"
} external;
