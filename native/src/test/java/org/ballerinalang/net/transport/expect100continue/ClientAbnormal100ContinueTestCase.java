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

import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpServer;
import org.ballerinalang.net.transport.util.server.initializers.Abnormal100ContinueServerInitializer;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;

import static org.ballerinalang.net.transport.contract.Constants.TEXT_PLAIN;
import static org.ballerinalang.net.transport.util.TestUtil.sendRequestAsync;
import static org.testng.Assert.assertEquals;

/**
 * This class is responsible for testing 100 continue response scenario. Ideally 100 continue response should only
 * receive when request headers contain expect continue header. In this case, testcase is testing for scenario in which
 * no such header is sent in the request but back-end is responding with 100 continue response. This is an abnormal
 * scenario.
 */
public class ClientAbnormal100ContinueTestCase {

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;
    private String responseContent = "Test Message";

    @BeforeClass
    public void setup() {
        givenAbnormal100ContinueServer();
        givenNormalHttpClient();
    }

    @Test
    public void testAbnormal100continueResponse() {
        try {
            String responseOne = whenRequestSentWithoutExpectContinue();
            assertEquals(responseOne, responseContent);
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running testConnectionReuseForMain", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        TestUtil.cleanUp(new ArrayList<>(), httpServer, connectorFactory);
    }

    private void givenNormalHttpClient() {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    private void givenAbnormal100ContinueServer() {
        httpServer = TestUtil.startHTTPServer(
                TestUtil.HTTP_SERVER_PORT, new Abnormal100ContinueServerInitializer(responseContent, TEXT_PLAIN, 200));
    }

    private String whenRequestSentWithoutExpectContinue() throws InterruptedException {
        CountDownLatch waitForResponseLatch = new CountDownLatch(1);
        DefaultHttpConnectorListener responseListener = sendRequestAsync(waitForResponseLatch, httpClientConnector);
        return TestUtil.waitAndGetStringEntity(waitForResponseLatch, responseListener);
    }
}
