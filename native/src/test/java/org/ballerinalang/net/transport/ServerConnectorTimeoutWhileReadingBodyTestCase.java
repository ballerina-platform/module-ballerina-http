/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultFullHttpRequest;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contentaware.listeners.DumbMessageListener;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.client.http.HttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static io.netty.handler.codec.http.HttpResponseStatus.REQUEST_TIMEOUT;
import static org.ballerinalang.net.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_REQUEST_BODY;
import static org.testng.AssertJUnit.assertEquals;
import static org.testng.AssertJUnit.assertTrue;

/**
 * This class tests server-connector timeout implementation. In this case, it tests if the server-connector returns
 * the correct response when server-connector time-out while reading the entity body of inbound request.
 */
public class ServerConnectorTimeoutWhileReadingBodyTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(ServerConnectorTimeoutWhileReadingBodyTestCase.class);

    protected ServerConnector serverConnector;
    protected ListenerConfiguration listenerConfiguration;
    protected HttpWsConnectorFactory httpWsConnectorFactory;

    ServerConnectorTimeoutWhileReadingBodyTestCase() {
        this.listenerConfiguration = new ListenerConfiguration();
    }

    @BeforeClass
    private void setUp() {
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setServerHeader(TestUtil.TEST_SERVER);
        listenerConfiguration.setSocketIdleTimeout(3000);

        ServerBootstrapConfiguration serverBootstrapConfig = new ServerBootstrapConfiguration(new HashMap<>());
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        serverConnector = httpWsConnectorFactory.createServerConnector(serverBootstrapConfig, listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new DumbMessageListener());
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.error("Thread Interrupted while sleeping ", e);
        }
    }

    @Test
    public void testHttpPost() {
        try {
            HttpClient httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);

            FullHttpRequest httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(TestUtil.smallEntity.getBytes()));
            FullHttpResponse httpResponse = httpClient.sendHalfRequest(httpRequest);

            assertTrue(httpClient.waitForChannelClose());
            assertEquals(REQUEST_TIMEOUT.code(), httpResponse.status().code());
            assertEquals(IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_REQUEST_BODY,
                         TestUtil.getEntityBodyFrom(httpResponse));
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running testHttpPost test", e);
        }
    }

    @AfterClass
    public void cleanup() throws InterruptedException {
        serverConnector.stop();
        httpWsConnectorFactory.shutdown();
    }
}
