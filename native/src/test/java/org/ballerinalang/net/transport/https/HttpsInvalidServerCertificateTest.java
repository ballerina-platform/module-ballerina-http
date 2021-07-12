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

package org.ballerinalang.net.transport.https;

import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpsServer;
import org.ballerinalang.net.transport.util.server.initializers.MockServerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.ballerinalang.net.transport.contract.Constants.HTTPS_SCHEME;
import static org.ballerinalang.net.transport.contract.Constants.TEXT_PLAIN;
import static org.testng.Assert.assertEquals;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * Tests a scenario where the http client not having the server certificate.
 */
public class HttpsInvalidServerCertificateTest {

    private static final Logger LOG = LoggerFactory.getLogger(HttpsInvalidServerCertificateTest.class);

    private HttpsServer httpsServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;
    private String testValue = "Test Message";

    @BeforeClass
    public void setup() {
        httpsServer = TestUtil.startHttpsServer(TestUtil.HTTPS_SERVER_PORT,
                                                new MockServerInitializer(testValue, TEXT_PLAIN, 200));

        SenderConfiguration senderConfiguration = new SenderConfiguration();
        String trustStoreFilePath = "/simple-test-config/cacerts.p12";
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(trustStoreFilePath));
        String trustStorePassword = "cacertspassword";
        senderConfiguration.setTrustStorePass(trustStorePassword);
        senderConfiguration.setHostNameVerificationEnabled(false);
        senderConfiguration.setScheme(HTTPS_SCHEME);
        connectorFactory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test
    public void testInvalidCertificate() {
        try {
            HttpCarbonMessage msg = TestUtil.createHttpsPostReq(TestUtil.HTTPS_SERVER_PORT, testValue, "");
            CountDownLatch latch = new CountDownLatch(1);
            SSLConnectorListener listener = new SSLConnectorListener(latch);
            HttpResponseFuture responseFuture = httpClientConnector.send(msg);
            responseFuture.setHttpConnectorListener(listener);
            latch.await(5, TimeUnit.SECONDS);
            assertNotNull(listener.getThrowables());
            assertEquals(listener.getThrowables().get(0).getMessage(),
                    "SSL connection failed:unable to find valid certification path to requested "
                            + "target localhost/127.0.0.1:9004");
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running HttpsCertificateInvalid test case", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            httpsServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Failed to shutdown the test server");
        }
    }
}
