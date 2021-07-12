/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.connectionpool;

import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpServer;
import org.ballerinalang.net.transport.util.server.initializers.SendChannelIDServerInitializer;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;

import static org.testng.Assert.assertNotEquals;

/**
 * Tests for connection pool implementation.
 */
public class ConnectionPoolEvictionTestCase {

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new SendChannelIDServerInitializer(0));

        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getPoolConfiguration().setMinEvictableIdleTime(2000);
        senderConfiguration.getPoolConfiguration().setTimeBetweenEvictionRuns(1000);
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test
    public void testConnectionEviction() {
        try {
            CountDownLatch requestLatchOne = new CountDownLatch(1);
            CountDownLatch requestLatchTwo = new CountDownLatch(1);

            DefaultHttpConnectorListener responseListener;

            responseListener = TestUtil.sendRequestAsync(requestLatchOne, httpClientConnector);
            String responseOne = TestUtil.waitAndGetStringEntity(requestLatchOne, responseListener);

            // wait till the eviction occurs
            Thread.sleep(5000);
            responseListener = TestUtil.sendRequestAsync(requestLatchTwo, httpClientConnector);
            String responseTwo = TestUtil.waitAndGetStringEntity(requestLatchTwo, responseListener);

            assertNotEquals(responseOne, responseTwo);
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running testConnectionReuseForMain", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        TestUtil.cleanUp(new ArrayList<>(), httpServer, connectorFactory);
    }
}
