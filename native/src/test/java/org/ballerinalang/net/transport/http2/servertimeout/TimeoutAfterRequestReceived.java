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

package org.ballerinalang.net.transport.http2.servertimeout;

import io.netty.handler.codec.http.HttpMethod;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.config.TransportsConfiguration;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.http2.listeners.Http2NoResponseListener;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpConnectorUtil;
import org.ballerinalang.net.transport.message.HttpMessageDataStreamer;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.client.http2.MessageGenerator;
import org.ballerinalang.net.transport.util.client.http2.MessageSender;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.ballerinalang.net.transport.contract.Constants.HTTP2_SERVER_TIMEOUT_ERROR_MESSAGE;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * {@code TimeoutAfterRequestReceived} tests server timeout once the request has been received but before
 * sending the outbound response.
 */
public class TimeoutAfterRequestReceived {
    private static final Logger LOG = LoggerFactory.getLogger(TimeoutAfterRequestReceived.class);

    private HttpClientConnector h2ClientWithPriorKnowledge;
    private HttpClientConnector h2ClientWithoutPriorKnowledge;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setSocketIdleTimeout(100);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new Http2NoResponseListener());
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration1 = getSenderConfiguration();
        senderConfiguration1.setForceHttp2(true);
        h2ClientWithPriorKnowledge = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration1);

        SenderConfiguration senderConfiguration2 = getSenderConfiguration();
        senderConfiguration2.setForceHttp2(false);
        h2ClientWithoutPriorKnowledge = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration2);
    }

    private SenderConfiguration getSenderConfiguration() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        //Set this to a value larger than server socket timeout value, to make sure that the server times out first
        senderConfiguration.setSocketIdleTimeout(500000);
        return senderConfiguration;
    }

    @Test
    public void testServerTimeout() {
        String testValue = "Test Http2 Message";
        HttpCarbonMessage httpMsg1 = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        HttpCarbonMessage httpMsg2 = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        verifyResult(httpMsg1, h2ClientWithoutPriorKnowledge);
        verifyResult(httpMsg2, h2ClientWithPriorKnowledge);
    }

    private void verifyResult(HttpCarbonMessage httpCarbonMessage, HttpClientConnector http2ClientConnector) {
        HttpCarbonMessage response = new MessageSender(http2ClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response);
        String result = TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        assertEquals(result, HTTP2_SERVER_TIMEOUT_ERROR_MESSAGE, "Expected response not received");
    }

    @AfterClass
    public void cleanUp() {
        h2ClientWithPriorKnowledge.close();
        h2ClientWithoutPriorKnowledge.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
