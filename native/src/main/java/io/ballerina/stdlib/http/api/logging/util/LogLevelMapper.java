/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.api.logging.util;

import java.util.logging.Level;

/**
 * A mapper class to map log levels from JDK logging to Ballerina log levels.
 *
 * @since 0.89
 */
public final class LogLevelMapper {

    private LogLevelMapper() {}

    public static String getBallerinaLogLevel(Level level) {
        switch (level.getName()) {
            case "SEVERE":
                return "ERROR";
            case "WARNING":
                return "WARN";
            case "INFO":
                return "INFO";
            case "CONFIG":
                return "INFO";
            case "FINE":
                return "DEBUG";
            case "FINER":
                return "DEBUG";
            case "FINEST":
                return "TRACE";
            default:
                return "<UNDEFINED>";
        }
    }

    public static Level getLoggerLevel(LogLevel level) {
        switch (level) {
            case OFF:
                return Level.OFF;
            case ERROR:
                return Level.SEVERE;
            case WARN:
                return Level.WARNING;
            case INFO:
                return Level.INFO;
            case DEBUG:
                return Level.FINER;
            case TRACE:
                return Level.FINEST;
            case ALL:
                return Level.ALL;
        }
        return Level.INFO;
    }
}
