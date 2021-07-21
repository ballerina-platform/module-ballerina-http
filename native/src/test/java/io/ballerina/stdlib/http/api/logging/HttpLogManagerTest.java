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

package io.ballerina.stdlib.http.api.logging;

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.TestUtils;
import io.ballerina.stdlib.http.api.logging.formatters.HttpAccessLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.HttpTraceLogFormatter;
import io.ballerina.stdlib.http.api.logging.formatters.JsonLogFormatter;
import org.junit.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.File;
import java.io.IOException;
import java.net.ServerSocket;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.SocketHandler;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_CONSOLE;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FILE_PATH;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_HOST;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRACE_LOG_PORT;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Http module HttpLogManager class functions.
 */
public class HttpLogManagerTest {

    File tempLogTestFile;

    @BeforeClass
    public void setup() throws IOException {
        tempLogTestFile = File.createTempFile("logTestFile", ".txt");
    }

    @Test
    public void testHttpLogManagerWithTraceLogConsole() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(true);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        long port = 0;
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("testHost");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
        Handler[] handlers = httpLogManager.httpTraceLogger.getHandlers();
        Assert.assertTrue(handlers.length > 0);
        Handler handler = handlers[handlers.length - 1];
        Assert.assertTrue(handler instanceof ConsoleHandler);
        Assert.assertTrue(handler.getFormatter() instanceof HttpTraceLogFormatter);
        Assert.assertEquals(Level.FINEST, handler.getLevel());
    }

    @Test
    public void testHttpLogManagerWithTraceLogFile() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        String path = tempLogTestFile.getPath();
        long port = TestUtils.SOCKET_SERVER_PORT;
        when(traceFilePath.getValue()).thenReturn(path);
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
        Handler[] handlers = httpLogManager.httpTraceLogger.getHandlers();
        Assert.assertTrue(handlers.length > 0);
        Handler handler = handlers[handlers.length - 1];
        Assert.assertTrue(handler instanceof FileHandler);
        Assert.assertTrue(handler.getFormatter() instanceof HttpTraceLogFormatter);
        Assert.assertEquals(Level.FINEST, handler.getLevel());
    }

    @Test
    public void testHttpLogManagerWithTraceLogSocket() throws IOException {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        long port = TestUtils.SOCKET_SERVER_PORT;
        ServerSocket serverSocket = new ServerSocket(TestUtils.SOCKET_SERVER_PORT);
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("localhost");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
        Handler[] handlers = httpLogManager.httpTraceLogger.getHandlers();
        Assert.assertTrue(handlers.length > 0);
        Handler handler = handlers[handlers.length - 1];
        Assert.assertTrue(handler instanceof SocketHandler);
        Assert.assertTrue(handler.getFormatter() instanceof JsonLogFormatter);
        Assert.assertEquals(Level.FINEST, handler.getLevel());
        serverSocket.close();
    }

    @Test
    public void testHttpLogManagerWithAccessLogConsole() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        long port = 0;
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(true);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
        Assert.assertEquals(httpLogManager.httpAccessLogger.getLevel(), Level.INFO);
        Handler[] handlers = httpLogManager.httpAccessLogger.getHandlers();
        Assert.assertTrue(handlers.length > 0);
        Handler handler = handlers[handlers.length - 1];
        Assert.assertTrue(handler instanceof ConsoleHandler);
        Assert.assertTrue(handler.getFormatter() instanceof HttpAccessLogFormatter);
        Assert.assertEquals(Level.INFO, handler.getLevel());
    }

    @Test
    public void testHttpLogManagerWithAccessLogFile() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        String path = tempLogTestFile.getPath();
        long port = 0;
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn(path);
        when(host.getValue()).thenReturn("");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
        Assert.assertEquals(httpLogManager.httpAccessLogger.getLevel(), Level.INFO);
        Handler[] handlers = httpLogManager.httpAccessLogger.getHandlers();
        Assert.assertTrue(handlers.length > 0);
        Handler handler = handlers[handlers.length - 1];
        Assert.assertTrue(handler instanceof FileHandler);
        Assert.assertTrue(handler.getFormatter() instanceof HttpAccessLogFormatter);
        Assert.assertEquals(Level.INFO, handler.getLevel());
    }

    @Test (expectedExceptions = RuntimeException.class,
            expectedExceptionsMessageRegExp = "failed to setup HTTP trace log file: /test/logTestFile.txt")
    public void testHttpLogManagerWithInvalidTraceLogFilePath() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        String path = "/test/logTestFile.txt";
        long port = 0;
        when(traceFilePath.getValue()).thenReturn(path);
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
    }

    @Test (expectedExceptions = RuntimeException.class,
            expectedExceptionsMessageRegExp = "failed to connect to testHost:8080")
    public void testHttpLogManagerWithNonExistingSocket() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        long port = 8080;
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn("");
        when(host.getValue()).thenReturn("testHost");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
    }

    @Test (expectedExceptions = RuntimeException.class,
            expectedExceptionsMessageRegExp = "failed to setup HTTP access log file: /test/logTestFile.txt")
    public void testHttpLogManagerWithInvalidAccessLogPath() {
        BMap traceLogConfig = mock(BMap.class);
        when(traceLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        BString traceFilePath = mock(BString.class);
        BString host = mock(BString.class);
        BString accessFilePath = mock(BString.class);
        String path = "/test/logTestFile.txt";
        long port = 0;
        when(traceFilePath.getValue()).thenReturn("");
        when(accessFilePath.getValue()).thenReturn(path);
        when(host.getValue()).thenReturn("");
        when(traceLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(traceFilePath);
        when(traceLogConfig.getStringValue(HTTP_TRACE_LOG_HOST)).thenReturn(host);
        when(traceLogConfig.getIntValue(HTTP_TRACE_LOG_PORT)).thenReturn(port);

        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getBooleanValue(HTTP_LOG_CONSOLE)).thenReturn(false);
        when(accessLogConfig.getStringValue(HTTP_LOG_FILE_PATH)).thenReturn(accessFilePath);

        HttpLogManager httpLogManager = new HttpLogManager(false, traceLogConfig, accessLogConfig);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        tempLogTestFile.deleteOnExit();
    }

}
