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
import ballerina/log;

// TODO: Remove this once the command line argument support is given for configurable record
configurable boolean traceLogConsole = false;

# Represents HTTP trace log configuration.
#
# + console - Boolean value to enable or disable console trace logs
# + path - Optional file path to store trace logs. This is deprecated in favor of the `file` configuration.
#   Recommended to use `file` configuration for file logging.
# + host - Optional socket hostname to publish the trace logs
# + port - Optional socket port to publish the trace logs
# + file - Optional log file configuration for file destinations
public type TraceLogAdvancedConfiguration record {|
    boolean console = false;
    string path?;
    string host?;
    int port?;
    LogFileConfig file?;
|};

# Represents HTTP access log configuration.
#
# + console - Boolean value to enable or disable console access logs
# + format - The format of access logs to be printed (either `flat` or `json`)
# + attributes - The list of attributes of access logs to be printed
# + path - Optional file path to store access logs. This is deprecated in favor of the `file` configuration.
#   Recommended to use `file` configuration for file logging.
# + file - Optional log file configuration for file destinations
public type AccessLogConfiguration record {|
    boolean console = false;
    string format = "flat";
    string[] attributes?;
    string path?;
    LogFileConfig file?;
|};

# Represents HTTP access log file configuration.
#
# + path - The file path to store access logs
# + rotation - The log rotation configuration for file destinations
public type LogFileConfig record {|
    string path;
    log:RotationConfig rotation?;
|};

configurable TraceLogAdvancedConfiguration traceLogAdvancedConfig = {};
configurable AccessLogConfiguration accessLogConfig = {};

isolated function getInstance(boolean traceLogConsole, TraceLogAdvancedConfiguration traceLogAdvancedConfig,
AccessLogConfiguration accessLogConfig, string protocol = "HTTP") returns handle|error = @java:Method {
    'class: "io.ballerina.stdlib.http.api.logging.HttpLogManager"
} external;
