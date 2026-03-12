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

import ballerina/file;
import ballerina/jballerina.java;
import ballerina/log;

function init() returns error? {
    setModule();
    LogFileConfig? traceFileConfig = traceLogAdvancedConfig.file;
    if traceFileConfig is LogFileConfig {
        check validateLogFileConfig(traceFileConfig);
    } else if traceLogAdvancedConfig.path is string {
        check validateFilePath(<string>traceLogAdvancedConfig.path);
    }

    LogFileConfig? accessFileConfig = accessLogConfig.file;
    if accessFileConfig is LogFileConfig {
        check validateLogFileConfig(accessFileConfig);
    } else if accessLogConfig.path is string {
        check validateFilePath(<string>accessLogConfig.path);
    }
    _ = check getInstance(traceLogConsole, traceLogAdvancedConfig, accessLogConfig);
}

isolated function validateLogFileConfig(LogFileConfig config) returns Error? {
    check validateFilePath(config.path);
    if config.rotation is log:RotationConfig {
        check validateRotationConfig(<log:RotationConfig>config.rotation);
    }
}

isolated function validateRotationConfig(log:RotationConfig config) returns Error? {
    log:RotationPolicy policy = config.policy;
    int maxFileSize = config.maxFileSize;
    int maxAge = config.maxAge;
    int maxBackupFiles = config.maxBackupFiles;

    // Validate parameters based on policy
    if (policy == log:SIZE_BASED || policy == log:BOTH) && maxFileSize <= 0 {
        return error Error(string `Invalid rotation configuration: maxFileSize must be positive, got: ${maxFileSize}`);
    }

    if (policy == log:TIME_BASED || policy == log:BOTH) && maxAge <= 0 {
        return error Error(string `Invalid rotation configuration: maxAge must be positive, got: ${maxAge}`);
    }

    if maxBackupFiles < 0 {
        return error Error(string `Invalid rotation configuration: maxBackupFiles cannot be negative, got: ${maxBackupFiles}`);
    }
}

isolated function validateFilePath(string path) returns Error? {
    if path.trim().length() == 0 {
        return error Error("Invalid configuration: 'rotation' requires a valid 'path' for file logging.");
    }
    string|error fileName = file:basename(path);
    // Ensure the basename is not empty
    if fileName is error {
        return error Error("Invalid path: " + fileName.message());
    }
    // Ensure the basename is not empty
    boolean|file:Error isDirectory = file:test(fileName, file:IS_DIR);
    if fileName.trim().length() == 0 || isDirectory is true {
        return error Error("Path must include a file name, not just a directory.");
    }
}

function setModule() = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils"
} external;
