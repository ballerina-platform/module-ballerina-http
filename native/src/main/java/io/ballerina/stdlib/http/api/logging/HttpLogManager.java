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

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogConfig;
import io.ballerina.stdlib.http.api.logging.formatters.HttpAccessLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.HttpTraceLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.JsonLogFormatter;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;
import java.util.logging.SocketHandler;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_ACCESS_LOG;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_ACCESS_LOG_ENABLED;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_CONSOLE;
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
                FileHandler fileHandler = new FileHandler(filePath.getValue(), true);
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
        if (!(logFormat.getValue().equals(HTTP_LOG_FORMAT_JSON) || logFormat.getValue().equals(HTTP_LOG_FORMAT_FLAT))) {
            stdErr.println("WARNING: Unsupported log format '" + logFormat.getValue() + "'. Defaulting to 'flat'.");
        }

        if (accessLogsEnabled) {
            System.setProperty(HTTP_ACCESS_LOG_ENABLED, "true");
            stdErr.println("ballerina: " + protocol + " access log enabled");
        }
    }
}
