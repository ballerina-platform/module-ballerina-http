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

package io.ballerina.stdlib.http.transport.https;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.ServerCloseTcpConnectionInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * A test case for testing the scenario of server closing the tcp connection during the SSL handshake.
 */
public class ServerCloseConnectionDuringSslTest {

    private HttpClientConnector httpClientConnector;
    private HttpServer httpServer;
    private HttpWsConnectorFactory factory;
    private static final Logger LOG = LoggerFactory.getLogger(ServerCloseConnectionDuringSslTest.class);
    private DefaultHttpConnectorListener listener;

    @BeforeClass
    public void setup() throws Exception {
        givenServerThatClosesConnection();
        givenANormalHttpsClient();
    }

    @Test
    public void testServerCloseChannelDuringSslHandshake() {
        try {
            whenANormalHttpsRequestSent();
            thenRespShouldBeAServerCloseException();
        } catch (Exception ex) {
            TestUtil.handleException("Exception occurred while running testServerCloseChannelDuringSslHandshake", ex);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            httpServer.shutdown();
            httpClientConnector.close();
            factory.shutdown();
        } catch (Exception e) {
            LOG.warn("Interrupted while waiting for response", e);
        }
    }

    private void thenRespShouldBeAServerCloseException() {
        Throwable response = listener.getHttpErrorMessage();
        assertNotNull(response);
        assertTrue(response instanceof ClientConnectorException,
                "Exception is not an instance of ClientConnectorException");
        String result = response.getMessage();
        assertEquals("Remote host: localhost/127.0.0.1:9000 closed the connection while SSL handshake", result);
    }

    private void whenANormalHttpsRequestSent() throws InterruptedException {
        HttpCarbonMessage msg = TestUtil.createHttpsPostReq(TestUtil.HTTP_SERVER_PORT, "", "");

        CountDownLatch latch = new CountDownLatch(1);
        listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = httpClientConnector.send(msg);
        responseFuture.setHttpConnectorListener(listener);

        latch.await(5, TimeUnit.SECONDS);
    }

    private SenderConfiguration getSenderConfigs() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        String trustStoreFile = "/simple-test-config/client-truststore.p12";
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(trustStoreFile));
        String password = "ballerina";
        senderConfiguration.setTrustStorePass(password);
        String tlsStoreType = "PKCS12";
        senderConfiguration.setTLSStoreType(tlsStoreType);
        senderConfiguration.setScheme(HTTPS_SCHEME);
        return senderConfiguration;
    }

    private void givenANormalHttpsClient() throws Exception {
        factory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = factory.createHttpsClientConnector(new HashMap<>(), getSenderConfigs());
    }

    private void givenServerThatClosesConnection() {
        httpServer = TestUtil
                .startHTTPServer(TestUtil.HTTP_SERVER_PORT, new ServerCloseTcpConnectionInitializer());
    }
}
