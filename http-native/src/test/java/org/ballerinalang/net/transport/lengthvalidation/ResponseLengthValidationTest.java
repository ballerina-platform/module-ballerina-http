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

package org.ballerinalang.net.transport.lengthvalidation;

import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;
import com.mashape.unirest.http.exceptions.UnirestException;
import com.mashape.unirest.http.options.Options;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.passthrough.PassthroughMessageProcessorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpServer;
import org.ballerinalang.net.transport.util.server.initializers.EchoServerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.Test;

import java.io.IOException;
import java.net.URI;
import java.util.HashMap;

import static org.testng.AssertJUnit.assertEquals;

/**
 * This class tests inbound response status line, headers and entity body validations.
 * <p>
 * Test setup uses the PassthroughMessageProcessorListener with a configurable client. The EchoServerInitializer is used
 * as the backend echo server. Each test changes the client sender config based on testing objective.
 */
public class ResponseLengthValidationTest {

    private static final Logger LOG = LoggerFactory.getLogger(ResponseLengthValidationTest.class);

    private HttpServer httpServer;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory httpWsConnectorFactory;
    static final String TEST_VALUE = "Test Message";
    URI baseURI = URI.create(String.format("http://%s:%d", "localhost", TestUtil.SERVER_CONNECTOR_PORT));


    private void setUp(SenderConfiguration senderConfiguration) {
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        serverConnector = httpWsConnectorFactory
                .createServerConnector(new ServerBootstrapConfiguration(new HashMap<>()), listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(
                new PassthroughMessageProcessorListener(senderConfiguration));
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }

        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new EchoServerInitializer());
    }

    @Test(description = "Configure setMaxInitialLineLength to 100 and test smaller status line")
    public void statusLineValidationSuccessTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxInitialLineLength(100);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).body(TEST_VALUE).asString();
            assertEquals(TEST_VALUE, response.getBody());
            assertEquals(200, response.getStatus());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running shortHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    @Test(description = "Configure setMaxInitialLineLength to 5 and test larger status line")
    public void statusLineValidationNegativeTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxInitialLineLength(5);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).asString();
            assertEquals("Response max status line length exceeds: An HTTP line is larger than 5 bytes.",
                         response.getBody());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running longHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    @Test(description = "Configure setMaxHeaderSize to 100 and test smaller total header size")
    public void headerValidationSuccessTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxHeaderSize(100);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).body(TEST_VALUE).asString();
            assertEquals(TEST_VALUE, response.getBody());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running shortHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    @Test(description = "Configure setMaxHeaderSize to 10 and test larger total header size")
    public void headerValidationNegativeTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxHeaderSize(10);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).asString();
            assertEquals("Response max header size exceeds: HTTP header is larger than 10 bytes.", response.getBody());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running longHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    @Test(description = "Configure setMaxEntityBodySize to 100 and test smaller payload")
    public void entityBodyValidationSuccessTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxEntityBodySize(100);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).body(TEST_VALUE).asString();
            assertEquals(TEST_VALUE, response.getBody());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running shortHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    @Test(description = "Configure setMaxEntityBodySize to 7 and test larger payload")
    public void entityBodyValidationNegativeTest() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getMsgSizeValidationConfig().setMaxEntityBodySize(7);
        setUp(senderConfiguration);

        try {
            HttpResponse<String> response = Unirest.post(baseURI.resolve("/").toString()).body(TEST_VALUE).asString();
            assertEquals("Response max entity body size exceeds: Entity body is larger than 7 bytes. ",
                         response.getBody());
        } catch (UnirestException e) {
            TestUtil.handleException("IOException occurred while running longHeaderTest", e);
        } finally {
            cleanUp();
        }
    }

    private void cleanUp() {
        try {
            Unirest.shutdown();
            Options.refresh();
            serverConnector.stop();
            httpServer.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (IOException e) {
            LOG.warn("IOException occurred while waiting for Unirest connection to shutdown", e);
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to shutdown", e);
        }
    }
}
