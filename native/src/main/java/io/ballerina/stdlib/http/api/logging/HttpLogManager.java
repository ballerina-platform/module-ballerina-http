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
import io.ballerina.stdlib.http.api.HttpUtil;
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
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FILE_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FILE_PATH;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT_FLAT;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT_JSON;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_ENABLED;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_HOST;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_PORT;

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

    HttpLogManager(boolean traceLogConsole, BMap traceLogAdvancedConfig,
                   BMap accessLogConfig, BString protocol) throws IOException {
        this.protocol = protocol.getValue();
        this.setHttpTraceLogHandler(traceLogConsole, traceLogAdvancedConfig);
        this.setHttpAccessLogHandler(accessLogConfig);
        HttpAccessLogConfig.getInstance().initializeHttpAccessLogConfig(accessLogConfig);
    }

    /**
     * Factory method that creates an HttpLogManager.
     *
     * @return the new HttpLogManager instance, or a BError if
     *         initialization failed (e.g., the access-log file could not be opened).
     */
    public static Object getInstance(boolean traceLogConsole, BMap traceLogAdvancedConfig,
                                     BMap accessLogConfig, BString protocol) {
        try {
            return new HttpLogManager(traceLogConsole, traceLogAdvancedConfig, accessLogConfig, protocol);
        } catch (IOException e) {
            return HttpUtil.getError(e);
        }
    }

    /**
     * Initializes the HTTP trace logger.
     */
    public void setHttpTraceLogHandler(boolean traceLogConsole, BMap traceLogAdvancedConfig) throws IOException {
        if (httpTraceLogger == null) {
            // keep a reference to prevent this logger from being garbage collected
            httpTraceLogger = Logger.getLogger(HTTP_TRACE_LOG);
        }
        PrintStream stdErr = System.err;
        boolean traceLogsEnabled = false;

        traceLogsEnabled |= setupTraceConsoleLogging(traceLogConsole, traceLogAdvancedConfig);
        traceLogsEnabled |= setupTraceFileLogging(traceLogAdvancedConfig);
        traceLogsEnabled |= setupTraceSocketLogging(traceLogAdvancedConfig);

        if (traceLogsEnabled) {
            httpTraceLogger.setLevel(Level.FINEST);
            System.setProperty(HTTP_TRACE_LOG_ENABLED, "true");
            stdErr.println("ballerina: " + protocol + " trace log enabled");
        }
    }

    /**
     * Initializes the HTTP access logger.
     */
    public void setHttpAccessLogHandler(BMap accessLogConfig) throws IOException {
        if (httpAccessLogger == null) {
            // keep a reference to prevent this logger from being garbage collected
            httpAccessLogger = Logger.getLogger(HTTP_ACCESS_LOG);
        }
        PrintStream stdErr = System.err;
        boolean accessLogsEnabled = false;

        accessLogsEnabled |= setupConsoleLogging(accessLogConfig);
        accessLogsEnabled |= setupFileLogging(accessLogConfig);
        validateLogFormat(accessLogConfig, stdErr);

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
    private HttpRollingFileHandler createRollingHandler(String path, BMap<BString, Object> rotationConfig)
            throws IOException {
        String policyStr = String.valueOf(rotationConfig.getStringValue(ROTATION_POLICY));
        long maxSize = rotationConfig.getIntValue(ROTATION_MAX_FILE_SIZE);
        long maxAge = rotationConfig.getIntValue(ROTATION_MAX_AGE);
        int maxBackup = rotationConfig.getIntValue(ROTATION_MAX_BACKUP_FILES).intValue();
        RotationPolicy rotationPolicy = RotationPolicy.valueOf(policyStr.toUpperCase(java.util.Locale.ENGLISH));
        return new HttpRollingFileHandler(path, rotationPolicy, maxSize, maxAge, maxBackup, true, "UTF-8");
    }

    private boolean setupConsoleLogging(BMap accessLogConfig) {
        Boolean consoleEnabled = accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE);
        if (!consoleEnabled) {
            return false;
        }
        ConsoleHandler handler = new ConsoleHandler();
        configureHandler(handler);
        return true;
    }

    private boolean setupFileLogging(BMap accessLogConfig) throws IOException {
        BMap fileConfig = accessLogConfig.getMapValue(HTTP_LOG_FILE_CONFIG);
        BString filePath = accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH);
        BMap rotationConfig = null;
        if (fileConfig != null) {
            filePath = fileConfig.getStringValue(HTTP_LOG_FILE_PATH);
            rotationConfig = fileConfig.getMapValue(HTTP_LOG_ROTATION);
        }
        if (filePath == null) {
            return false;
        }
        try {
            Handler handler = (rotationConfig != null)
                    ? createRollingHandler(filePath.getValue(), rotationConfig)
                    : new FileHandler(filePath.getValue(), true);

            configureHandler(handler);
            return true;
        } catch (IOException e) {
            throw new IOException("Failed to setup HTTP access log file handler: " + e.getMessage(), e);
        }
    }

    private void configureHandler(Handler handler) {
        handler.setFormatter(new HttpAccessLogFormatter());
        handler.setLevel(Level.INFO);
        httpAccessLogger.addHandler(handler);
        httpAccessLogger.setLevel(Level.INFO);
    }

    private void validateLogFormat(BMap accessLogConfig, PrintStream stdErr) {
        BString logFormat = accessLogConfig.getStringValue(HTTP_LOG_FORMAT);
        if (logFormat != null &&
                !(HTTP_LOG_FORMAT_JSON.equals(logFormat.getValue()) ||
                        HTTP_LOG_FORMAT_FLAT.equals(logFormat.getValue()))) {

            stdErr.println("WARNING: Unsupported log format '" + logFormat.getValue()
                    + "'. Defaulting to 'flat' format.");
        }
    }

    private boolean setupTraceSocketLogging(BMap config) throws IOException {
        BString host = config.getStringValue(HTTP_TRACE_LOG_HOST);
        Long port = config.getIntValue(HTTP_TRACE_LOG_PORT);

        if (host == null || host.getValue().trim().isEmpty() || port == null || port == 0) {
            return false;
        }
        try {
            SocketHandler socketHandler = new SocketHandler(host.getValue(), port.intValue());
            socketHandler.setFormatter(new JsonLogFormatter());
            socketHandler.setLevel(Level.FINEST);
            httpTraceLogger.addHandler(socketHandler);
            return true;

        } catch (IOException e) {
            throw new IOException("Failed to connect to " + host.getValue() + ":" + port.intValue(), e);
        }
    }

    private boolean setupTraceFileLogging(BMap config) throws IOException {
        BMap fileConfig = config.getMapValue(HTTP_LOG_FILE_CONFIG);
        BString filePath = config.getStringValue(HTTP_LOG_FILE_PATH);
        BMap rotationConfig = null;

        if (fileConfig != null) {
            filePath = fileConfig.getStringValue(HTTP_LOG_FILE_PATH);
            rotationConfig = fileConfig.getMapValue(HTTP_LOG_ROTATION);
        }
        if (filePath == null) {
            return false;
        }
        try {
            Handler handler = (rotationConfig != null)
                    ? createRollingHandler(filePath.getValue(), rotationConfig)
                    : new FileHandler(filePath.getValue(), true);

            configureTraceHandler(handler);
            return true;
        } catch (IOException e) {
            throw new IOException("Failed to setup HTTP trace log file handler: " + e.getMessage(), e);
        }
    }

    private boolean setupTraceConsoleLogging(boolean traceLogConsole, BMap config) {
        Boolean consoleEnabled = config.getBooleanValue(HTTP_LOG_CONSOLE);
        if (!(traceLogConsole || Boolean.TRUE.equals(consoleEnabled))) {
            return false;
        }
        ConsoleHandler consoleHandler = new ConsoleHandler();
        configureTraceHandler(consoleHandler);
        return true;
    }

    private void configureTraceHandler(Handler handler) {
        handler.setFormatter(new HttpTraceLogFormatter());
        handler.setLevel(Level.FINEST);
        httpTraceLogger.addHandler(handler);
    }
}
