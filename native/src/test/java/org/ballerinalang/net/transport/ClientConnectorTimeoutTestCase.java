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

package org.ballerinalang.net.transport;

import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.EndpointTimeOutException;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpServer;
import org.ballerinalang.net.transport.util.server.initializers.DumbServerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * Tests for HTTP client connector timeout.
 */
public class ClientConnectorTimeoutTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(ClientConnectorTimeoutTestCase.class);

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new DumbServerInitializer());

        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setSocketIdleTimeout(3000);
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test
    public void testHttpGet() {
        try {
            HttpCarbonMessage msg = TestUtil.createHttpsPostReq(TestUtil.HTTP_SERVER_PORT, "", "");

            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = httpClientConnector.send(msg);
            responseFuture.setHttpConnectorListener(listener);

            latch.await(6, TimeUnit.SECONDS);

            Throwable response = listener.getHttpErrorMessage();
            assertNotNull(response);
            assertTrue(response instanceof EndpointTimeOutException,
                    "Exception is not an instance of EndpointTimeOutException");
            String result = response.getMessage();

            assertEquals(Constants.IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_INBOUND_RESPONSE, result);
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running httpsGetTest", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            httpServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Failed to shutdown the test server");
        }
    }
}
