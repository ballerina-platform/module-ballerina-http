/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.Parameter;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contract.exceptions.SslException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * Tests for SSL protocols with certs and Keys.
 */
public class SSLProtocolsWithCertsTest {
    private static final Logger LOG = LoggerFactory.getLogger(SSLProtocolsTest.class);

    private static HttpClientConnector httpClientConnector;
    private static HttpWsConnectorFactory httpWsConnectorFactory;
    private static ServerConnector serverConnector;
    private List<Parameter> clientParams = new ArrayList<>(1);

    @DataProvider(name = "protocols")

    public static Object[][] cipherSuites() {
        // true = expecting a SSL hand shake failure.
        // false = expecting no errors.
        return new Object[][] { { "TLSv1.2", "TLSv1.2", false, TestUtil.SERVER_PORT1 },
                { "TLSv1.1", "TLSv1.2", true, TestUtil.SERVER_PORT2 } };
    }

    /**
     * Set up the client and the server.
     *
     * @param clientProtocol SSL enabled protocol of client
     * @param serverProtocol SSL enabled protocol of server
     * @param hasException expecting an exception true/false
     * @param serverPort port
     */
    @Test(dataProvider = "protocols")
    public void setup(String clientProtocol, String serverProtocol, boolean hasException, int serverPort)
            throws Exception {

        Parameter clientprotocols = new Parameter("sslEnabledProtocols", clientProtocol);
        clientParams.add(clientprotocols);

        Parameter serverProtocols = new Parameter("sslEnabledProtocols", serverProtocol);
        List<Parameter> severParams = new ArrayList<>(1);
        severParams.add(serverProtocols);

        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = getListenerConfiguration(serverPort, severParams);

        serverConnector = httpWsConnectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        httpClientConnector = httpWsConnectorFactory.createHttpsClientConnector(new HashMap<>(), getSenderConfigs());

        testSSLProtocols(hasException, serverPort);
        serverConnector.stop();
    }

    private ListenerConfiguration getListenerConfiguration(int serverPort, List<Parameter> severParams) {
        ListenerConfiguration listenerConfiguration = ListenerConfiguration.getDefault();
        listenerConfiguration.setPort(serverPort);
        String verifyClient = "require";
        listenerConfiguration.setVerifyClient(verifyClient);
        listenerConfiguration.setServerKeyFile(TestUtil.getAbsolutePath(TestUtil.KEY_FILE));
        listenerConfiguration.setServerCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        listenerConfiguration.setServerTrustCertificates(TestUtil.getAbsolutePath(TestUtil.TRUST_CERT_CHAIN));
        listenerConfiguration.setScheme(HTTPS_SCHEME);
        listenerConfiguration.setParameters(severParams);
        return listenerConfiguration;
    }

    private SenderConfiguration getSenderConfigs() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setClientKeyFile(TestUtil.getAbsolutePath(TestUtil.KEY_FILE));
        senderConfiguration.setClientCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        senderConfiguration.setClientTrustCertificates(TestUtil.getAbsolutePath(TestUtil.TRUST_CERT_CHAIN));
        senderConfiguration.setParameters(clientParams);
        senderConfiguration.setScheme(HTTPS_SCHEME);
        senderConfiguration.setHostNameVerificationEnabled(false);
        return senderConfiguration;
    }

    private void testSSLProtocols(boolean hasException, int serverPort) {
        try {
            String testValue = "Test";
            HttpCarbonMessage msg = TestUtil.createHttpsPostReq(serverPort, testValue, "");

            CountDownLatch latch = new CountDownLatch(1);
            SSLConnectorListener listener = new SSLConnectorListener(latch);
            HttpResponseFuture responseFuture = httpClientConnector.send(msg);
            responseFuture.setHttpConnectorListener(listener);

            latch.await(5, TimeUnit.SECONDS);
            HttpCarbonMessage response = listener.getHttpResponseMessage();
            if (hasException) {
                assertNotNull(listener.getThrowables());
                boolean hasSSLException = false;
                for (Throwable throwable : listener.getThrowables()) {
                    // The exception message is java version dependent, hence asserting the exception class
                    if (throwable instanceof SslException) {
                        hasSSLException = true;
                        break;
                    }
                }
                assertTrue(hasSSLException);
            } else {
                assertNotNull(response);
                String result = new BufferedReader(
                        new InputStreamReader(new HttpMessageDataStreamer(response).getInputStream())).lines()
                        .collect(Collectors.joining("\n"));
                assertEquals(testValue, result);
            }
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running testSSLProtocols", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            httpClientConnector.close();
            httpWsConnectorFactory.shutdown();
        } catch (Exception e) {
            LOG.warn("Interrupted while waiting for response two", e);
        }
    }
}

