/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
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
 *
 */

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoStreamingMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ResetContent;
import io.ballerina.stdlib.http.transport.contractimpl.sender.states.http2.RequestCompleted;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.EmptyByteBuf;
import io.netty.buffer.UnpooledByteBufAllocator;
import io.netty.handler.codec.http.CombinedHttpHeaders;
import io.netty.handler.codec.http.DefaultHttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * This contains test case for sending a Http2ResetContent content to initiate a stream reset.
 */
public class Http2WithHttp2ResetContent {
    private static final Logger LOG = LoggerFactory.getLogger(Http2WithHttp2ResetContent.class);

    private HttpClientConnector httpClientConnector;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private ConnectionManager connectionManager;
    private EchoStreamingMessageListener echoStreamingMessageListener;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        echoStreamingMessageListener = new EchoStreamingMessageListener();
        future.setHttpConnectorListener(echoStreamingMessageListener);
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);       // Force to use HTTP/2 without an upgrade
        connectionManager = new ConnectionManager(senderConfiguration.getPoolConfiguration());
        httpClientConnector = connectorFactory.createHttpClientConnector(HttpConnectorUtil.getTransportProperties(
                transportsConfiguration), senderConfiguration, connectionManager);
    }

    @Test(description = "Sends a request with reset content such that the stream will be reset")
    public void testHttp2ResetContent() {
        HttpCarbonMessage resetMessage = MessageGenerator.getHttp2CarbonMessageWithResetContent(HttpMethod.POST);
        HttpCarbonMessage resetResponse = new MessageSender(httpClientConnector).sendMessage(resetMessage);

        assertTrue(resetMessage.getHttp2MessageStateContext().getSenderState() instanceof RequestCompleted);
        assertEquals(echoStreamingMessageListener.getReceivedException().getMessage(),
                Constants.REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY);
    }

    @Test(description = "Checks the overridden equals method")
    public void testHttp2ResetContentEqualsMethod() {

        DefaultHttpHeaders defaultHttpHeaders = new DefaultHttpHeaders();
        defaultHttpHeaders.add(TestUtil.HOST, TestUtil.TEST_HOST);
        ByteBuf emptyByteBuf = new EmptyByteBuf(UnpooledByteBufAllocator.DEFAULT);

        Http2ResetContent http2ResetContent = new Http2ResetContent(emptyByteBuf, defaultHttpHeaders);
        assertFalse(http2ResetContent.equals(null));
        Object resetContentWithCombinedHeaders = new Http2ResetContent(emptyByteBuf, new CombinedHttpHeaders(false));
        assertFalse(http2ResetContent.equals(resetContentWithCombinedHeaders));
        Object resetContentWithDefaultHeaders = new Http2ResetContent(emptyByteBuf, defaultHttpHeaders);
        assertTrue(http2ResetContent.equals(resetContentWithDefaultHeaders));
    }

    @AfterClass
    public void cleanUp() {
        httpClientConnector.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
