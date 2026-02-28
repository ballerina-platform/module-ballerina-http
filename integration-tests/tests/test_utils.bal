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

import ballerina/io;
import ballerina/jballerina.java;

configurable string bal_exec_path = ?;
configurable string temp_dir_path = ?;

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
                f.name.startsWith(COMBINED_POLICY_PREFIX) ||
                f.name.startsWith(CONCURRENT_WRITES_PREFIX) ||
                f.name.startsWith(ZERO_BACKUP_PREFIX)) && f.name.endsWith(FILE_EXT) {
                _ = check removeFile(f.absPath, false);
            }
        }
    }
    return;
}

function countRotatedFiles(string prefix) returns int|error {
    FileInfo[] files = check listFiles(LOG_DIR);
    int rotatedFileCount = 0;
    foreach FileInfo f in files {
        if f.name.startsWith(prefix + "-") && f.name.endsWith(FILE_EXT) {
            rotatedFileCount += 1;
        }
    }
    return rotatedFileCount;
}

function getRotatedFiles(string prefix) returns FileInfo[]|error {
    FileInfo[] files = check listFiles(LOG_DIR);
    FileInfo[] rotatedFiles = [];
    foreach FileInfo f in files {
        if f.name.startsWith(prefix + "-") && f.name.endsWith(FILE_EXT) {
            rotatedFiles.push(f);
        }
    }
    return rotatedFiles;
}

function countLogEntries(string filePath) returns int|error {
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

function exec(@untainted string command, @untainted map<string> env = {},
                     @untainted string? dir = (), @untainted string... args) returns Process|error = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.nativeimpl.Exec"
} external;

isolated function listFiles(string path) returns FileInfo[]|error {
    string jsonStr = check listFilesJson(path);
    return jsonStr.fromJsonStringWithType();
}
