/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.logging;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogConfig;
import io.ballerina.stdlib.http.api.logging.accesslog.HttpRollingFileHandler;
import io.ballerina.stdlib.http.api.logging.formatters.HttpAccessLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.HttpTraceLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.JsonLogFormatter;
import io.ballerina.stdlib.http.api.logging.util.RotationPolicy;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;
import java.util.logging.SocketHandler;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_ACCESS_LOG;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_ACCESS_LOG_ENABLED;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_ATTRIBUTES;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FILE_PATH;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT_FLAT;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT_JSON;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_ENABLED;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_HOST;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_PORT;
import static io.ballerina.stdlib.http.api.logging.util.RotationPolicy.BOTH;

/**
 * Java util logging manager for ballerina which overrides the readConfiguration method to replace placeholders
 * having system or environment variables.
 *
 * @since 0.8.0
 */
public class HttpLogManager extends LogManager {

    static final BString HTTP_LOG_CONSOLE  = StringUtils.fromString("console");
    static final BString HTTP_LOG_ROTATION = StringUtils.fromString("rotation");

    // Rotation config keys
    static final BString ROTATION_POLICY = StringUtils.fromString("policy");
    static final BString ROTATION_MAX_FILE_SIZE = StringUtils.fromString("maxFileSize");
    static final BString ROTATION_MAX_AGE = StringUtils.fromString("maxAge");
    static final BString ROTATION_MAX_BACKUP_FILES = StringUtils.fromString("maxBackupFiles");


    static {
        // loads logging.properties from the classpath
        try (InputStream is = HttpLogManager.class.getClassLoader().
                getResourceAsStream("logging.properties")) {
            LogManager.getLogManager().readConfiguration(is);
        } catch (IOException e) {
            throw new RuntimeException("failed to read logging.properties file from the classpath", e);
        }
    }

    protected Logger httpTraceLogger;
    protected Logger httpAccessLogger;
    private String protocol;

    public HttpLogManager(boolean traceLogConsole, BMap traceLogAdvancedConfig, BMap accessLogConfig,
                          BString protocol) {
        this.protocol = protocol.getValue();
        this.setHttpTraceLogHandler(traceLogConsole, traceLogAdvancedConfig);
        this.setHttpAccessLogHandler(accessLogConfig);
        HttpAccessLogConfig.getInstance().initializeHttpAccessLogConfig(accessLogConfig);
    }

    /**
     * Initializes the HTTP trace logger.
     */
    public void setHttpTraceLogHandler(boolean traceLogConsole, BMap traceLogAdvancedConfig) {
        if (httpTraceLogger == null) {
            // keep a reference to prevent this logger from being garbage collected
            httpTraceLogger = Logger.getLogger(HTTP_TRACE_LOG);
        }
        PrintStream stdErr = System.err;
        boolean traceLogsEnabled = false;

        Boolean consoleLogEnabled = traceLogAdvancedConfig.getBooleanValue(HTTP_LOG_CONSOLE);
        if (traceLogConsole || consoleLogEnabled) {
            ConsoleHandler consoleHandler = new ConsoleHandler();
            consoleHandler.setFormatter(new HttpTraceLogFormatter());
            consoleHandler.setLevel(Level.FINEST);
            httpTraceLogger.addHandler(consoleHandler);
            traceLogsEnabled = true;
        }

        BString logFilePath = traceLogAdvancedConfig.getStringValue(HTTP_LOG_FILE_PATH);
        if (logFilePath != null && !logFilePath.getValue().trim().isEmpty()) {
            try {
                FileHandler fileHandler = new FileHandler(logFilePath.getValue(), true);
                fileHandler.setFormatter(new HttpTraceLogFormatter());
                fileHandler.setLevel(Level.FINEST);
                httpTraceLogger.addHandler(fileHandler);
                traceLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to setup HTTP trace log file: " + logFilePath.getValue(), e);
            }
        }

        BString host = traceLogAdvancedConfig.getStringValue(HTTP_TRACE_LOG_HOST);
        Long port = traceLogAdvancedConfig.getIntValue(HTTP_TRACE_LOG_PORT);
        if ((host != null && !host.getValue().trim().isEmpty()) && (port != null && port != 0)) {
            try {
                SocketHandler socketHandler = new SocketHandler(host.getValue(), port.intValue());
                socketHandler.setFormatter(new JsonLogFormatter());
                socketHandler.setLevel(Level.FINEST);
                httpTraceLogger.addHandler(socketHandler);
                traceLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to connect to " + host.getValue() + ":" + port.intValue(), e);
            }
        }

        if (traceLogsEnabled) {
            httpTraceLogger.setLevel(Level.FINEST);
            System.setProperty(HTTP_TRACE_LOG_ENABLED, "true");
            stdErr.println("ballerina: " + protocol + " trace log enabled");
        }
    }

    /**
     * Initializes the HTTP access logger.
     */
    public void setHttpAccessLogHandler(BMap accessLogConfig) {
        if (httpAccessLogger == null) {
            // keep a reference to prevent this logger from being garbage collected
            httpAccessLogger = Logger.getLogger(HTTP_ACCESS_LOG);
        }
        PrintStream stdErr = System.err;
        boolean accessLogsEnabled = false;

        Boolean consoleLogEnabled = accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE);
        if (consoleLogEnabled) {
            ConsoleHandler consoleHandler = new ConsoleHandler();
            consoleHandler.setFormatter(new HttpAccessLogFormatter());
            consoleHandler.setLevel(Level.INFO);
            httpAccessLogger.addHandler(consoleHandler);
            httpAccessLogger.setLevel(Level.INFO);
            accessLogsEnabled = true;
        }

        BString filePath = accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH);
        if (filePath != null && !filePath.getValue().trim().isEmpty()) {
            try {
                Handler fileHandler;
                BMap rotationMap = accessLogConfig.getMapValue(HTTP_LOG_ROTATION);
                if (rotationMap != null) {
                    fileHandler = createRollingHandler(filePath.getValue(), rotationMap);
                } else {
                    fileHandler = new FileHandler(filePath.getValue(), true);
                }
                fileHandler.setFormatter(new HttpAccessLogFormatter());
                fileHandler.setLevel(Level.INFO);
                httpAccessLogger.addHandler(fileHandler);
                httpAccessLogger.setLevel(Level.INFO);
                accessLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to setup HTTP access log file: " + filePath.getValue(), e);
            }
        }

        BString logFormat = accessLogConfig.getStringValue(HTTP_LOG_FORMAT);
        if (logFormat != null &&
                !(logFormat.getValue().equals(HTTP_LOG_FORMAT_JSON) ||
                        logFormat.getValue().equals(HTTP_LOG_FORMAT_FLAT))) {
            stdErr.println("WARNING: Unsupported log format '" + logFormat.getValue() +
                    "'. Defaulting to 'flat' format.");
        }

        BArray logAttributes = accessLogConfig.getArrayValue(HTTP_LOG_ATTRIBUTES);
        if (logAttributes != null && logAttributes.getLength() == 0) {
            accessLogsEnabled = false;
        }

        if (accessLogsEnabled) {
            System.setProperty(HTTP_ACCESS_LOG_ENABLED, "true");
            stdErr.println("ballerina: " + protocol + " access log enabled");
        }
    }

    /**
     * Creates a HttpRollingFileHandler with config parsed from BMap.
     */
    private Handler createRollingHandler(String path, BMap<BString, Object> rotationConfig) throws IOException {
        // Parse rotation config
        String policyStr = String.valueOf(rotationConfig.getStringValue(ROTATION_POLICY));
        long maxSize = rotationConfig.getIntValue(ROTATION_MAX_FILE_SIZE);
        long maxAge = rotationConfig.getIntValue(ROTATION_MAX_AGE);
        int maxBackup = rotationConfig.getIntValue(ROTATION_MAX_BACKUP_FILES).intValue();

        RotationPolicy policy;
        try {
            policy = RotationPolicy.valueOf(policyStr.toUpperCase(java.util.Locale.ENGLISH));
        } catch (IllegalArgumentException e) {
            // Unknown policy string — fallback to BOTH
            policy = BOTH;
        }
        validateRotationConfig(path, policy, maxSize, maxAge, maxBackup);
        return new HttpRollingFileHandler(path, policy, maxSize, maxAge, maxBackup, true);
    }

    /**
     * Validates the rotation configuration parameters.
     *
     * @param policy         rotation policy string — SIZE_BASED, TIME_BASED, or BOTH
     * @param maxFileSize    must be > 0 when policy is SIZE_BASED or BOTH
     * @param maxAgeSeconds  must be > 0 when policy is TIME_BASED or BOTH
     * @param maxBackupFiles must be >= 1
     *
     * @throws IllegalArgumentException if any parameter is invalid
     */
    private static void validateRotationConfig(String filePath, RotationPolicy policy, long maxFileSize,
                                               long maxAgeSeconds,
                                               int maxBackupFiles) {
        // Todo: Format errors similar to Ballerina errors
        if (filePath == null || filePath.trim().isEmpty()) {
            throw new RuntimeException("Log file path must not be null or empty");
        }
        if ((policy == RotationPolicy.SIZE_BASED || policy == RotationPolicy.BOTH)
                && maxFileSize <= 0) {
            throw new RuntimeException("Invalid rotation configuration: maxFileSize must be positive," +
                    "got: " + maxFileSize);
        }

        if ((policy == RotationPolicy.TIME_BASED || policy == RotationPolicy.BOTH)
                && maxAgeSeconds <= 0) {
            throw new RuntimeException("Invalid rotation configuration: maxAge must be positive," +
                    "got: " + maxAgeSeconds);
        }

        if (maxBackupFiles < 0) {
            throw new RuntimeException("Invalid rotation configuration: maxBackupFiles cannot be negative, " +
                    "got: " + maxBackupFiles);
        }
    }
}
