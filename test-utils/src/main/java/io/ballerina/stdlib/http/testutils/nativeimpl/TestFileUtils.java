/*
 *  Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.testutils.nativeimpl;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BString;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.stream.Stream;

/**
 * Utility functions for file operations in tests.
 * This class provides file system operations without depending on ballerina/file module,
 * avoiding cyclic dependencies.
 *
 * @since 2.16.0
 */
public class TestFileUtils {

    private TestFileUtils() {
    }

    /**
     * Helper method to create a BError with a message.
     *
     * @param message The error message
     * @return BError with the message
     */
    private static BError createError(String message) {
        return ErrorCreator.createError(StringUtils.fromString(message));
    }

    /**
     * Check if a file or directory exists.
     *
     * @param path The file or directory path to check
     * @return true if exists, false otherwise
     */
    public static boolean fileExists(BString path) {
        return new File(path.getValue()).exists();
    }

    /**
     * Check if a path is a directory.
     *
     * @param path The path to check
     * @return true if directory, false otherwise
     */
    public static boolean isDirectory(BString path) {
        return new File(path.getValue()).isDirectory();
    }

    /**
     * List all files in a directory and return as JSON string.
     *
     * @param path The directory path
     * @return JSON string of file metadata, or error if operation fails
     */
    public static Object listFilesJson(BString path) {
        try {
            File dir = new File(path.getValue());
            if (!dir.exists() || !dir.isDirectory()) {
                return createError("Path does not exist or is not a directory: " + path.getValue());
            }

            File[] files = dir.listFiles();
            if (files == null) {
                return createError("Failed to list files in directory: " + path.getValue());
            }
            if (files.length == 0) {
                return StringUtils.fromString("[]");
            }

            StringBuilder json = new StringBuilder("[");
            boolean first = true;

            for (File file : files) {
                if (!first) {
                    json.append(",");
                }
                first = false;

                json.append("{")
                    .append("\"absPath\":\"").append(escapeJson(file.getAbsolutePath())).append("\",")
                    .append("\"name\":\"").append(escapeJson(file.getName())).append("\",")
                    .append("\"isDir\":").append(file.isDirectory()).append(",")
                    .append("\"size\":").append(file.length())
                    .append("}");
            }
            json.append("]");

            return StringUtils.fromString(json.toString());
        } catch (Exception e) {
            return createError("Failed to list files: " + e.getMessage());
        }
    }

    /**
     * Escape JSON special characters in a string.
     *
     * @param str The string to escape
     * @return Escaped string
     */
    private static String escapeJson(String str) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < str.length(); i++) {
            char ch = str.charAt(i);
            String escaped = getEscapedChar(ch);
            sb.append(escaped != null ? escaped : ch);
        }
        return sb.toString();
    }

    /**
     * Get the escaped representation of a character for JSON.
     *
     * @param ch The character to escape
     * @return Escaped string, or null if no escaping needed
     */
    private static String getEscapedChar(char ch) {
        switch (ch) {
            case '\\':
                return "\\\\";
            case '"':
                return "\\\"";
            case '/':
                return "\\/";
            case '\b':
                return "\\b";
            case '\f':
                return "\\f";
            case '\n':
                return "\\n";
            case '\r':
                return "\\r";
            case '\t':
                return "\\t";
            default:
                return ch <= 0x1F ? String.format("\\u%04x", (int) ch) : null;
        }
    }

    /**
     * Remove a file or directory.
     *
     * @param path The file or directory path to remove
     * @param recursive If true, remove directory recursively
     * @return null on success, error on failure
     */
    public static BError removeFile(BString path, boolean recursive) {
        try {
            Path filePath = Paths.get(path.getValue());
            if (!Files.exists(filePath)) {
                return null; // Already doesn't exist
            }

            if (Files.isDirectory(filePath) && recursive) {
                // Delete directory recursively
                try (Stream<Path> walk = Files.walk(filePath)) {
                    walk.sorted(Comparator.reverseOrder())
                        .forEach(p -> {
                            try {
                                Files.delete(p);
                            } catch (IOException e) {
                                // Continue with other files
                            }
                        });
                }
            } else {
                Files.delete(filePath);
            }
            return null;
        } catch (IOException e) {
            return createError("Failed to remove file: " + e.getMessage());
        }
    }

    /**
     * Create a directory including parent directories.
     *
     * @param path The directory path to create
     * @return null on success, error on failure
     */
    public static BError createDirectory(BString path) {
        try {
            Path dirPath = Paths.get(path.getValue());
            if (!Files.exists(dirPath)) {
                Files.createDirectories(dirPath);
            }
            return null;
        } catch (IOException e) {
            return createError("Failed to create directory: " + e.getMessage());
        }
    }
}
