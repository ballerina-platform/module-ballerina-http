/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.transport.expect100continue;

import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ChunkConfig;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpMessageDataStreamer;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.listeners.Continue100AfterRespReceivedListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * This test is responsible for testing the listener side implementation of Expect Continue request. In this case,
 * Listener is being tested for the scenario in which 100-continue response is executed while receiving inbound request
 * payload. In other words, this test is for an abnormal 100-Continue scenario.
 */
public class ListenerContinue100AfterRespReceivedTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(ListenerContinue100AfterRespReceivedTestCase.class);

    private ServerConnector serverConnector;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory httpWsConnectorFactory;
    private DefaultHttpConnectorListener listener;

    @BeforeClass
    public void setup() throws InterruptedException {
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        givenServerWithVeryLate100Response();
        givenNormalClient();
    }

    @Test
    public void test100Continue() {
        try {
            whenReqSentWithExpectContinue();
            thenRespShouldBeNormal();
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running httpsGetTest", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        serverConnector.stop();
        try {
            httpWsConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Interrupted while waiting for HttpWsFactory to shutdown", e);
        }
    }

    private void givenServerWithVeryLate100Response() throws InterruptedException {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setServerHeader(TestUtil.TEST_SERVER);
        ServerBootstrapConfiguration serverBootstrapConfig = new ServerBootstrapConfiguration(new HashMap<>());
        serverConnector = httpWsConnectorFactory.createServerConnector(serverBootstrapConfig, listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new Continue100AfterRespReceivedListener());
        serverConnectorFuture.sync();
    }

    private void givenNormalClient() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setChunkingConfig(ChunkConfig.NEVER);
        senderConfiguration.setSocketIdleTimeout(15000);
        httpClientConnector = httpWsConnectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    private void thenRespShouldBeNormal() {
        String responseBody = TestUtil.getStringFromInputStream(
                new HttpMessageDataStreamer(listener.getHttpResponseMessage()).getInputStream());
        assertEquals(responseBody, TestUtil.largeEntity);
    }

    private void whenReqSentWithExpectContinue() throws IOException, InterruptedException {
        HttpCarbonMessage requestMsg = new HttpCarbonMessage(new DefaultHttpRequest(HttpVersion.HTTP_1_1,
                                                                                    HttpMethod.POST, ""));

        requestMsg.setProperty(Constants.HTTP_PORT, TestUtil.SERVER_CONNECTOR_PORT);
        requestMsg.setProperty(Constants.PROTOCOL, Constants.HTTP_SCHEME);
        requestMsg.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        requestMsg.setHttpMethod(Constants.HTTP_POST_METHOD);
        requestMsg.setHeader(HttpHeaderNames.EXPECT.toString(), HttpHeaderValues.CONTINUE);
        requestMsg.setHeader("X-Status", "Positive");

        CountDownLatch latch = new CountDownLatch(1);
        listener = new DefaultHttpConnectorListener(latch);
        httpClientConnector.send(requestMsg).setHttpConnectorListener(listener);

        HttpMessageDataStreamer httpMessageDataStreamer = new HttpMessageDataStreamer(requestMsg);
        httpMessageDataStreamer.getOutputStream().write(TestUtil.largeEntity.getBytes());
        httpMessageDataStreamer.getOutputStream().close();

        latch.await(30, TimeUnit.SECONDS);
    }
}
