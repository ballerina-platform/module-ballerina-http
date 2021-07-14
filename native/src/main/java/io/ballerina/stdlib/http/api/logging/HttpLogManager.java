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
import io.ballerina.stdlib.http.api.logging.formatters.HttpAccessLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.HttpTraceLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.JsonLogFormatter;

import java.io.IOException;
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

    protected Logger httpTraceLogger;
    protected Logger httpAccessLogger;

    public HttpLogManager(BMap traceLogConfig, BMap accessLogConfig) {
        this.setHttpTraceLogHandler(traceLogConfig);
        this.setHttpAccessLogHandler(accessLogConfig);
    }

    /**
     * Initializes the HTTP trace logger.
     */
    public void setHttpTraceLogHandler(BMap traceLogConfig) {
        if (httpTraceLogger == null) {
            // keep a reference to prevent this logger from being garbage collected
            httpTraceLogger = Logger.getLogger(HTTP_TRACE_LOG);
        }
        PrintStream stdErr = System.err;
        boolean traceLogsEnabled = false;

        Boolean consoleLogEnabled = traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE);
        if (consoleLogEnabled) {
            ConsoleHandler consoleHandler = new ConsoleHandler();
            consoleHandler.setFormatter(new HttpTraceLogFormatter());
            consoleHandler.setLevel(Level.FINEST);
            httpTraceLogger.addHandler(consoleHandler);
            traceLogsEnabled = true;
        }

        String logFilePath = traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH).getValue();
        if (!logFilePath.trim().isEmpty()) {
            try {
                FileHandler fileHandler = new FileHandler(logFilePath, true);
                fileHandler.setFormatter(new HttpTraceLogFormatter());
                fileHandler.setLevel(Level.FINEST);
                httpTraceLogger.addHandler(fileHandler);
                traceLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to setup HTTP trace log file: " + logFilePath, e);
            }
        }

        String host = traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST).getValue();
        int port = traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT).intValue();
        if (!host.trim().isEmpty() && port != 0) {
            try {
                SocketHandler socketHandler = new SocketHandler(host, port);
                socketHandler.setFormatter(new JsonLogFormatter());
                socketHandler.setLevel(Level.FINEST);
                httpTraceLogger.addHandler(socketHandler);
                traceLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to connect to " + host + ":" + port, e);
            }
        }

        if (traceLogsEnabled) {
            httpTraceLogger.setLevel(Level.FINEST);
            System.setProperty(HTTP_TRACE_LOG_ENABLED, "true");
            stdErr.println("ballerina: HTTP trace log enabled");
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

        String filePath = accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH).getValue();
        if (!filePath.trim().isEmpty()) {
            try {
                FileHandler fileHandler = new FileHandler(filePath, true);
                fileHandler.setFormatter(new HttpAccessLogFormatter());
                fileHandler.setLevel(Level.INFO);
                httpAccessLogger.addHandler(fileHandler);
                httpAccessLogger.setLevel(Level.INFO);
                accessLogsEnabled = true;
            } catch (IOException e) {
                throw new RuntimeException("failed to setup HTTP access log file: " + filePath, e);
            }
        }

        if (accessLogsEnabled) {
            System.setProperty(HTTP_ACCESS_LOG_ENABLED, "true");
            stdErr.println("ballerina: HTTP access log enabled");
        }
    }

}
