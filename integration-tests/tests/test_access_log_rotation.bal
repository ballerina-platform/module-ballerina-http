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
import ballerina/log;
import ballerina/test;

const LOG_DIR = "./build/tmp/output";
const TIME_BASED_PREFIX = "time-based-access";
const SIZE_BASED_PREFIX = "size-based-access";
const COMBINED_POLICY_PREFIX = "combined-policy";
const CONCURRENT_WRITES_PREFIX = "concurrent-writes";
const ZERO_BACKUP_PREFIX = "zero-backup";
const FILE_EXT = ".log";

@test:BeforeSuite
function setupIntegrationTests() returns error? {
    // Clean up any existing log files before starting tests
    return cleanLogFiles();
}

@test:AfterSuite
function cleanupIntegrationTests() returns error? {
    // Clean up test files
    return cleanLogFiles();
}

@test:Config {
    serialExecution: true
}
function testSizeBasedAccessLogRotation() returns error? {
    string logFile = "./build/tmp/output/size-based-access.log";
    string configFile = "tests/resources/samples/config/size-based-rotation.toml";

    // Execute the test Ballerina program that generates logs and triggers rotation
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(15); // wait to up the service

    http:Client 'client = check new("http://localhost:9797");
    foreach int i in 0...9 {
        record {}[] _= check 'client->get("/albums");
        runtime:sleep(1);
    }
    runtime:sleep(1); // Wait for the service to complete requests

    boolean hasTerminated = result.stop(); // Stop the process
    runtime:sleep(1); // Ensure all file handles are released before verification
    test:assertTrue(hasTerminated, "Process should be stopped successfully");

    test:assertTrue(fileExists(logFile), "Main log file should exist");
    int rotatedFileCount = check countRotatedFiles(SIZE_BASED_PREFIX);
    test:assertTrue(rotatedFileCount > 0, "Should have created rotated backup files");
    test:assertTrue(rotatedFileCount <= 4, "Should respect maxBackupFiles setting (4)");

    // Verify log file content
    string content = check io:fileReadString(logFile);
    test:assertTrue(content.includes("GET"), "Logs should include attributes from Config.toml");
    test:assertTrue(content.includes("200"), "Logs should include attributes from Config.toml");
    test:assertTrue(content.includes("ballerina"), "Logs should include attributes from Config.toml");
}

@test:Config {
    serialExecution: true
}
function testTimeBasedAccessLogRotation() returns error? {
    string logFile = "./build/tmp/output/time-based-access.log";
    string configFile = "tests/resources/samples/config/time-based-rotation.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(15); // Wait to up the service

    http:Client 'client = check new("http://localhost:9797");
    foreach int i in 0...9 {
        record {}[] _= check 'client->get("/albums");
        runtime:sleep(1);
    }
    runtime:sleep(1); // Wait for the service to complete requests

    boolean hasTerminated = result.stop();
    runtime:sleep(1); // Ensure all file handles are released before verification
    test:assertTrue(hasTerminated, "Process should be stopped successfully"); 

    test:assertTrue(fileExists(logFile), "Main log file should exist");
    int rotatedFileCount = check countRotatedFiles(TIME_BASED_PREFIX);
    test:assertTrue(rotatedFileCount > 0, "Should have created rotated backup files");
    test:assertTrue(rotatedFileCount <= 3, "Should respect maxBackupFiles setting (3)");

    // Verify log file content
    string content = check io:fileReadString(logFile);
    test:assertTrue(content.includes("GET"), "Logs should include attributes from Config.toml");
    test:assertTrue(content.includes("200"), "Logs should include attributes from Config.toml");
    test:assertTrue(content.includes("ballerina"), "Logs should include attributes from Config.toml");
}

@test:Config {
    serialExecution: true
}
function testCombinedPolicyRotation() returns error? {
    string logFile = "./build/tmp/output/combined-policy-access.log";
    string configFile = "tests/resources/samples/config/combined-policy-rotation.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(15); // Wait to up the service

    http:Client 'client = check new("http://localhost:9797");
    foreach int i in 0...9 {
        record {}[] _= check 'client->get("/albums");
        runtime:sleep(1);
    }
    runtime:sleep(1); // Wait for the service to complete requests

    // Verify size-based rotation occurred first
    int rotatedFileCountAfterSize = check countRotatedFiles(COMBINED_POLICY_PREFIX);
    test:assertTrue(rotatedFileCountAfterSize > 0, "Should have rotated when size limit reached");

    // Wait for time interval and generate minimal logs
    runtime:sleep(5);
    record {}[] _= check 'client->get("/albums");
    runtime:sleep(1);

    // Stop the process
    boolean hasTerminated = result.stop();
    runtime:sleep(1);
    test:assertTrue(hasTerminated, "Process should be stopped successfully");

    // Verify time-based rotation also works
    int rotatedFileCountAfterTime = check countRotatedFiles(COMBINED_POLICY_PREFIX);
    test:assertTrue(rotatedFileCountAfterTime >= rotatedFileCountAfterSize, 
        "Should maintain or increase backup files after time interval");

    test:assertTrue(fileExists(logFile), "Main log file should exist");
}

@test:Config {
    serialExecution: true
}
function testConcurrentWrites() returns error? {
    string logFile = "./build/tmp/output/concurrent-writes-access.log";
    string configFile = "tests/resources/samples/config/concurrent-writes-rotation.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(15);

    http:Client client1 = check new("http://localhost:9797");
    http:Client client2 = check new("http://localhost:9797");
    http:Client client3 = check new("http://localhost:9797");

    worker w1 returns error? {
        foreach int i in 0...6 {
            record {}[] _ = check client1->get("/albums");
            runtime:sleep(1);
            
        }
    }

    worker w2 returns error? {
        foreach int i in 0...6 {
            record{}[] _ = check client2->get("/albums");
            runtime:sleep(1);
        }
        
    }

    worker w3 returns error? {
        foreach int i in 0...6 {
            record{}[] _ = check client3->get("/albums");
            runtime:sleep(1);
        }
    }
    runtime:sleep(3); // Wait for all requests to complete and rotation to occur

    () _ = check wait w1;
    _ = check wait w2;
    _ = check wait w3;
    runtime:sleep(1);

    boolean hasTerminated = result.stop();
    runtime:sleep(1);
    test:assertTrue(hasTerminated, "Process should be stopped successfully");

    test:assertTrue(fileExists(logFile), "Main log file should exist");
    int rotatedFileCount = check countRotatedFiles(CONCURRENT_WRITES_PREFIX);
    test:assertTrue(rotatedFileCount >= 0, "Rotation may or may not occur based on volume");

    // Count total log entries across all files (main + rotated)
    int totalLogEntries = check countLogEntries(logFile);
    FileInfo[] rotatedFiles = check getRotatedFiles(CONCURRENT_WRITES_PREFIX);
    foreach FileInfo f in rotatedFiles {
        totalLogEntries += check countLogEntries(f.absPath);
    }

    // Verify no log records were lost
    test:assertTrue(totalLogEntries >= 21, 
        string `Should have logged most concurrent requests. Expected ~21, got ${totalLogEntries}`);

    // Verify log integrity - all entries should be complete lines
    string content = check io:fileReadString(logFile);
    string[] lines = re `\n`.split(content);
    foreach string line in lines {
        if line.trim().length() > 0 {
            test:assertTrue(line.includes("GET"), "Each log line should contain a valid HTTP method");
        }
    }
}

// Zero backup files: Verify rotation with maxBackupFiles=0 only keeps current file
@test:Config {
    serialExecution: true
}
function testZeroMaxBackupFiles() returns error? {
    string logFile = "./build/tmp/output/zero-backup-access.log";
    string configFile = "tests/resources/samples/config/zero-backup-rotation.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(10);

    http:Client 'client = check new("http://localhost:9797");
    foreach int i in 0...10 {
        record {}[] _= check 'client->get("/albums");
        runtime:sleep(1);
    }
    runtime:sleep(1);

    boolean hasTerminated = result.stop();
    runtime:sleep(1);
    test:assertTrue(hasTerminated, "Process should be stopped successfully");
    test:assertTrue(fileExists(logFile), "Main log file should exist");
    
    // Verify no backup files are kept (maxBackupFiles=0)
    int rotatedFileCount = check countRotatedFiles(ZERO_BACKUP_PREFIX);
    test:assertTrue(rotatedFileCount == 1, "Should only have main file when maxBackupFiles=0");
}

// Invalid config: Test behavior with invalid rotation configuration values
@test:Config {
    groups: ["invalid-config"],
    serialExecution: true
}
function testInvalidConfigBackupFile() returns error? {
    string configFile = "tests/resources/samples/config/invalid-backup-file-config.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, "UTF-8");
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    if logLines.length() > 5 {
        log:printInfo("Error message: " + logLines[5]);
    }

    // Verify service failed due to invalid config
    test:assertTrue(logLines.length() >= 1, "Should have error logs for invalid config");
    test:assertTrue(outText.includes("Invalid rotation configuration: maxBackupFiles cannot be negative, got: -6"),
        "Error output should indicate configuration validation failure");
}

@test:Config {
    groups: ["invalid-config"],
    serialExecution: true
}
function testInvalidConfigMaxAge() returns error? {
    string configFile = "tests/resources/samples/config/invalid-max-age-config.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, "UTF-8");
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    if logLines.length() > 5 {
        log:printInfo("Error message: " + logLines[5]);
    }
    
    // Verify service failed due to invalid config
    test:assertTrue(logLines.length() >= 1, "Should have error logs for invalid config");
    test:assertTrue(outText.includes("Invalid rotation configuration: maxAge must be positive, got: -100"), 
        "Error output should indicate configuration validation failure");
}

@test:Config {
    groups: ["invalid-config"],
    serialExecution: true
}
function testInvalidConfigMaxFileSize() returns error? {
    string configFile = "tests/resources/samples/config/invalid-max-file-size-config.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, "UTF-8");
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    if logLines.length() > 5 {
        log:printInfo("Error message: " + logLines[5]);
    }
    
    // Verify service failed due to invalid config
    test:assertTrue(logLines.length() >= 1, "Should have error logs for invalid config");
    test:assertTrue(outText.includes("Invalid rotation configuration: maxFileSize must be positive, got: -100"), 
        "Error output should indicate configuration validation failure");
}

@test:Config {
    groups: ["invalid-config"],
    serialExecution: true
}
function testInvalidFilePath() returns error? {
    string configFile = "tests/resources/samples/config/invalid-file-path-config.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, "UTF-8");
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    if logLines.length() > 5 {
        log:printInfo("Error message: " + logLines[5]);
    }

    // Verify service failed due to invalid config
    test:assertTrue(logLines.length() >= 1, "Should have error logs for invalid config");
    test:assertTrue(outText.includes("error: Path must include a file name, not just a directory."), 
        "Error output should indicate configuration validation failure");
}
