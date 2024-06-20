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

// TODO: Remove this once the command line argument support is given for configurable record
configurable boolean traceLogConsole = false;

# Represents HTTP trace log configuration.
#
# + console - Boolean value to enable or disable console trace logs
# + path - Optional file path to store trace logs
# + host - Optional socket hostname to publish the trace logs
# + port - Optional socket port to publish the trace logs
public type TraceLogAdvancedConfiguration record {|
    boolean console = false;
    string path?;
    string host?;
    int port?;
|};

# Represents HTTP access log configuration.
#
# + console - Boolean value to enable or disable console access logs
# + format - The format of access logs to be printed (either `flat` or `json`)
# + attributes - The list of attributes of access logs to be printed
# + path - Optional file path to store access logs
public type AccessLogConfiguration record {|
    boolean console = false;
    string format = "flat";
    string[] attributes?;
    string path?;
|};

configurable TraceLogAdvancedConfiguration traceLogAdvancedConfig = {};
configurable AccessLogConfiguration accessLogConfig = {
    console: true,
    format: "flat"
};

isolated function initializeHttpLogs(boolean traceLogConsole, TraceLogAdvancedConfiguration traceLogAdvancedConfig,
AccessLogConfiguration accessLogConfig, string protocol = "HTTP") returns handle = @java:Constructor {
    'class: "io.ballerina.stdlib.http.api.logging.HttpLogManager"
} external;
