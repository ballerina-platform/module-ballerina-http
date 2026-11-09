// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/jballerina.java;
import ballerina/test;

configurable string bal_exec_path = ?;
configurable string temp_dir_path = ?;

// Built once by the Gradle build, so each test starts the service without recompiling it.
isolated function serviceJarPath() returns string => string `${temp_dir_path}/service/target/bin/service.jar`;

isolated function runService(string configFile, int port) returns Process|error =>
    exec(javaExecutable(), {BAL_CONFIG_FILES: configFile}, (), "-jar", serviceJarPath(), string `-Cport=${port}`);

// All the tests start their services at the same time, which can take a while on a small CI runner.
const int SERVICE_START_TIMEOUT_SECONDS = 120;

isolated function startService(string configFile, int port) returns Process|error {
    if isPortOpen(port) {
        return error(string `port ${port} is already in use, possibly by a service left behind by an earlier run`);
    }
    Process process = check runService(configFile, port);
    string status = waitForService(process, port, SERVICE_START_TIMEOUT_SECONDS);
    if status == "started" {
        return process;
    }
    if status == "exited" {
        return error(string `the service on port ${port} exited before it started: ${check readAll(process.stderr())}`);
    }
    _ = process.stop();
    return error(string `the service on port ${port} did not start within ${SERVICE_START_TIMEOUT_SECONDS} s`);
}

// Starts the service, runs the traffic against it and stops the service even when the traffic fails, so that a
// failing test does not leave the service holding its port and log files. Returns the traffic's result.
isolated function useService(string configFile, int port,
        isolated function (http:Client) returns int|error traffic) returns int|error {
    Process process = check startService(configFile, port);
    http:Client|error 'client = new (string `http://localhost:${port}`);
    int|error result = 'client is error ? 'client : trap traffic('client);
    runtime:sleep(1); // Wait for the service to complete requests
    boolean hasTerminated = process.stop();
    runtime:sleep(1); // Ensure all file handles are released before verification
    test:assertTrue(hasTerminated, "Process should be stopped successfully");
    return result;
}

isolated function sendRequests(http:Client 'client, int count) returns error? {
    foreach int i in 0 ..< count {
        record {}[] _ = check 'client->get("/albums");
        runtime:sleep(1);
    }
}

isolated function readAll(io:ReadableByteChannel channel) returns string|error {
    io:ReadableCharacterChannel characters = new (channel, "UTF-8");
    return characters.read(100000);
}

type FileInfo record {|
    string absPath;
    string name;
    boolean isDir;
    int size;
|};

function cleanLogFiles() returns error? {
    if fileExists(LOG_DIR) {
        FileInfo[] files = check listFiles(LOG_DIR);
        foreach FileInfo f in files {
            if (f.name.startsWith(TIME_BASED_PREFIX) || 
                f.name.startsWith(SIZE_BASED_PREFIX) ||
                f.name.startsWith(COMBINED_POLICY_ACCESS_PREFIX) ||
                f.name.startsWith(COMBINED_POLICY_TRACE_PREFIX) ||
                f.name.startsWith(CONCURRENT_WRITES_PREFIX) ||
                f.name.startsWith(ZERO_BACKUP_ACCESS_PREFIX) ||
                f.name.startsWith(ZERO_BACKUP_UTIL_PREFIX))
                 && f.name.endsWith(FILE_EXT) {
                _ = check removeFile(f.absPath, false);
            }
        }
    }
    return;
}

isolated function countRotatedFiles(string prefix) returns int|error {
    FileInfo[] files = check listFiles(LOG_DIR);
    int rotatedFileCount = 0;
    foreach FileInfo f in files {
        if f.name.startsWith(prefix + "-") && f.name.endsWith(FILE_EXT) {
            rotatedFileCount += 1;
        }
    }
    return rotatedFileCount;
}

isolated function getRotatedFiles(string prefix) returns FileInfo[]|error {
    FileInfo[] files = check listFiles(LOG_DIR);
    FileInfo[] rotatedFiles = [];
    foreach FileInfo f in files {
        if f.name.startsWith(prefix + "-") && f.name.endsWith(FILE_EXT) {
            rotatedFiles.push(f);
        }
    }
    return rotatedFiles;
}

isolated function countLogEntries(string filePath) returns int|error {
    if !fileExists(filePath) {
        return 0;
    }
    string content = check io:fileReadString(filePath);
    string[] lines = re `\n`.split(content);
    int count = 0;
    foreach string line in lines {
        if line.trim().length() > 0 {
            count += 1;
        }
    }
    return count;
}

isolated function fileExists(string path) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.TestFileUtils"
} external;

isolated function listFilesJson(string path) returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.TestFileUtils"
} external;

isolated function removeFile(string path, boolean recursive) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.TestFileUtils"
} external;

isolated function createDirectory(string path) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.TestFileUtils"
} external;

isolated function exec(string command, map<string> env = {},
              string? dir = (), string... args) returns Process|error = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.Exec"
} external;

isolated function listFiles(string path) returns FileInfo[]|error {
    string jsonStr = check listFilesJson(path);
    return jsonStr.fromJsonStringWithType();
}

isolated function isPortOpen(int port) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.PortUtils"
} external;

isolated function waitForService(Process process, int port, int timeoutSeconds) returns string = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.PortUtils"
} external;

isolated function javaExecutable() returns string = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.Exec"
} external;
