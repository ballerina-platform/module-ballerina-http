/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.http2.connectionpool;

import io.netty.handler.codec.http.HttpMethod;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contract.config.TransportsConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpConnectorUtil;
import org.ballerinalang.net.transport.message.HttpMessageDataStreamer;
import org.ballerinalang.net.transport.passthrough.PassthroughHttpsMessageProcessorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.client.http2.MessageGenerator;
import org.ballerinalang.net.transport.util.client.http2.MessageSender;
import org.ballerinalang.net.transport.util.server.HttpsServer;
import org.ballerinalang.net.transport.util.server.initializers.http2.channelidsender.Http2SendChannelIDInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static org.ballerinalang.net.transport.contract.Constants.HTTP_2_0;
import static org.ballerinalang.net.transport.util.Http2Util.assertResult;
import static org.ballerinalang.net.transport.util.Http2Util.getH2ListenerConfigs;
import static org.ballerinalang.net.transport.util.Http2Util.getSenderConfigs;
import static org.ballerinalang.net.transport.util.TestUtil.SERVER_PORT1;
import static org.testng.Assert.assertNotNull;

/**
 * Test case for H2 client connection pool.
 *
 * @since 6.0.273
 */
public class H2ConnectionPoolWithALPN {
    private static final Logger LOG = LoggerFactory.getLogger(H2ConnectionPoolWithALPN.class);

    private HttpWsConnectorFactory httpWsConnectorFactory;
    private ServerConnector serverConnector;
    private HttpsServer http2Server;
    private static final String HTTP2_VERSION = "2.0";

    @BeforeClass
    public void setup() {
        http2Server = TestUtil
            .startHttpsServer(TestUtil.HTTP_SERVER_PORT, new Http2SendChannelIDInitializer(), 1, 2, HTTP2_VERSION);

        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory(1, 2, 2);
        serverConnector = httpWsConnectorFactory
            .createServerConnector(new ServerBootstrapConfiguration(new HashMap<>()), getH2ListenerConfigs());
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(
            new PassthroughHttpsMessageProcessorListener(getSenderConfigs(HTTP_2_0), true));
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }
    }

    @Test
    public void testH2ConnectionPool() {
        //Since we have only two eventloops, upstream will have two different pools.
        HttpClientConnector client1 = getTestClient(); //Upstream uses eventloop1 pool
        String response1 = getResponse(client1);
        HttpClientConnector client2 = getTestClient(); //Upstream uses eventloop2 pool
        String response2 = getResponse(client2);
        HttpClientConnector client3 = getTestClient(); //Upstream uses eventloop1 pool
        String response3 = getResponse(client3);
        HttpClientConnector client4 = getTestClient(); //Upstream uses eventloop2 pool
        String response4 = getResponse(client4);

        assertResult(response1, response2, response3, response4);
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            http2Server.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (Exception e) {
            LOG.warn("Resource clean up is interrupted", e);
        }
    }

    /**
     * Get the test client. Each test client has their own connection manager and does not use source pools.
     *
     * @return HttpClientConnector
     */
    private HttpClientConnector getTestClient() {
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        return httpWsConnectorFactory.createHttpClientConnector(
            HttpConnectorUtil.getTransportProperties(transportsConfiguration),
            getSenderConfigs(HTTP_2_0));
    }

    private String getResponse(HttpClientConnector client1) {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, null,
                                                                               SERVER_PORT1, "https://");
        HttpCarbonMessage response = new MessageSender(client1).sendMessage(httpCarbonMessage);
        assertNotNull(response);
        return TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
    }
}
