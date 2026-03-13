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
public type TraceLogAdvancedConfiguration record {|
    # Enable or disable console trace logs
    boolean console = false;
    # File path to store trace logs
    # # Deprecated
    # This field is deprecated. Use the file configuration instead.
    @deprecated
    string path?;
    # Socket hostname to publish the trace logs
    string host?;
    # Socket port to publish the trace logs
    int port?;
    # Log file configuration to store trace logs
    LogFileConfig file?;
|};

# Represents HTTP access log configuration.
public type AccessLogConfiguration record {|
    # Enable or disable console access logs
    boolean console = false;
    # The format of access logs to be printed (either `flat` or `json`)
    string format = "flat";
    # The list of attributes of access logs to be printed
    string[] attributes?;
    # File path to store access logs
    # # Deprecated
    # This field is deprecated. Use the file configuration instead.
    @deprecated
    string path?;
    # Log file configuration to store access logs
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
