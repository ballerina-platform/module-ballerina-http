/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.logging.util;

import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.logging.Level;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Http module LogLevelMapper class functions.
 */
public class LogUtilTest {

    @Test
    public void testLogLevelMapperGetBLogLevel() {
        Level level = mock(Level.class);
        when(level.getName()).thenReturn("SEVERE");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "ERROR");
        when(level.getName()).thenReturn("WARNING");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "WARN");
        when(level.getName()).thenReturn("INFO");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "INFO");
        when(level.getName()).thenReturn("CONFIG");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "INFO");
        when(level.getName()).thenReturn("FINE");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "DEBUG");
        when(level.getName()).thenReturn("FINER");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "DEBUG");
        when(level.getName()).thenReturn("FINEST");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "TRACE");
        when(level.getName()).thenReturn("TEST");
        Assert.assertEquals(LogLevelMapper.getBallerinaLogLevel(level), "<UNDEFINED>");
    }

    @Test
    public void testLogLevelMapperGetLoggerLevel() {
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.OFF), Level.OFF);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.ERROR), Level.SEVERE);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.WARN), Level.WARNING);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.INFO), Level.INFO);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.DEBUG), Level.FINER);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.TRACE), Level.FINEST);
        Assert.assertEquals(LogLevelMapper.getLoggerLevel(LogLevel.ALL), Level.ALL);
    }

    @Test
    public void testLogLevelGetValue() {
        LogLevel logLevel = LogLevel.ALL;
        Assert.assertEquals(logLevel.value(), Integer.MIN_VALUE);
        logLevel = LogLevel.TRACE;
        Assert.assertEquals(logLevel.value(), 600);
        logLevel = LogLevel.DEBUG;
        Assert.assertEquals(logLevel.value(), 700);
        logLevel = LogLevel.INFO;
        Assert.assertEquals(logLevel.value(), 800);
        logLevel = LogLevel.WARN;
        Assert.assertEquals(logLevel.value(), 900);
        logLevel = LogLevel.ERROR;
        Assert.assertEquals(logLevel.value(), 1000);
        logLevel = LogLevel.OFF;
        Assert.assertEquals(logLevel.value(), Integer.MAX_VALUE);
    }

    @Test
    public void testToLogLevel() {
        LogLevel logLevel = LogLevel.toLogLevel("ALL");
        Assert.assertEquals(logLevel.value(), Integer.MIN_VALUE);
        logLevel = LogLevel.toLogLevel("TRACE");
        Assert.assertEquals(logLevel.value(), 600);
        logLevel = LogLevel.toLogLevel("DEBUG");
        Assert.assertEquals(logLevel.value(), 700);
        logLevel = LogLevel.toLogLevel("INFO");
        Assert.assertEquals(logLevel.value(), 800);
        logLevel = LogLevel.toLogLevel("WARN");
        Assert.assertEquals(logLevel.value(), 900);
        logLevel = LogLevel.toLogLevel("ERROR");
        Assert.assertEquals(logLevel.value(), 1000);
        logLevel = LogLevel.toLogLevel("OFF");
        Assert.assertEquals(logLevel.value(), Integer.MAX_VALUE);
    }

    @Test (expectedExceptions = RuntimeException.class, expectedExceptionsMessageRegExp = "invalid log level: TEST")
    public void testToLogLevelWithInvalidLogLevel() {
        LogLevel level = LogLevel.toLogLevel("TEST");
    }

}
