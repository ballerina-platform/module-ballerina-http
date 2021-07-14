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

// TODO: Make the fields optional once configurable records support union members
# Represents HTTP trace log configuration.
#
# + console - Boolean value to enable or disable console trace logs
# + path - File path to store trace logs
# + host - Socket hostname to publish the trace logs
# + port - Socket port to publish the trace logs
public type TraceLogConfiguration record {|
    boolean console = false;
    string path = "";
    string host = "";
    int port = 0;
|};

// TODO: Make the fields optional once configurable records support union members
# Represents HTTP access log configuration.
#
# + console - Boolean value to enable or disable console access logs
# + path - File path to store access logs
public type AccessLogConfiguration record {|
    boolean console = false;
    string path = "";
|};

configurable TraceLogConfiguration & readonly traceLogConfig = {};
configurable AccessLogConfiguration & readonly accessLogConfig = {};

isolated function initializeHttpLogs(TraceLogConfiguration traceLogConfig, AccessLogConfiguration accessLogConfig)
returns handle = @java:Constructor {
    'class: "io.ballerina.stdlib.http.api.logging.HttpLogManager"
} external;
