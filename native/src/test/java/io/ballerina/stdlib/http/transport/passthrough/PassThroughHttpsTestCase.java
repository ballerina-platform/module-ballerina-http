/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.passthrough;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpsServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.MockServerInitializer;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.util.Properties;

import static org.testng.AssertJUnit.assertEquals;

/**
 * A test case for https pass-through transport.
 */
public class PassThroughHttpsTestCase {
    private static final Logger LOG = LoggerFactory.getLogger(PassThroughHttpsTestCase.class);

    private static final String testValue = "Test Message";
    private HttpsServer httpsServer;
    private HttpWsConnectorFactory httpWsConnectorFactory;
    private ServerConnector serverConnector;
    private URI baseURI = URI.create(String.format("https://%s:%d", "localhost", TestUtil.SERVER_CONNECTOR_PORT));

    @BeforeClass
    public void setUp() {
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        ListenerConfiguration listenerConfiguration = ListenerConfiguration.getDefault();
        listenerConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(TestUtil.KEY_STORE_FILE_PATH));
        listenerConfiguration.setKeyStorePass(TestUtil.KEY_STORE_PASSWORD);
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setScheme(Constants.HTTPS_SCHEME);
        serverConnector = httpWsConnectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);

        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(TestUtil.TRUST_STORE_FILE_PATH));
        senderConfiguration.setTrustStorePass(TestUtil.KEY_STORE_PASSWORD);
        senderConfiguration.setScheme(Constants.HTTPS_SCHEME);

        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture
                .setHttpConnectorListener(new PassthroughHttpsMessageProcessorListener(senderConfiguration));
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }

        httpsServer = TestUtil.startHttpsServer(TestUtil.HTTP_SERVER_PORT,
                new MockServerInitializer(testValue, Constants.TEXT_PLAIN, 200));
    }

    @Test
    public void passthroughTest() {
        try {
            setSslSystemProperties();
            HttpURLConnection urlConn = TestUtil.httpsRequest(baseURI, "/", HttpMethod.GET.name(), true);
            String content = TestUtil.getContent(urlConn);
            assertEquals(testValue, content);
            urlConn.disconnect();
        } catch (IOException e) {
            TestUtil.handleException("IOException occurred while running passthroughGetTest", e);
        }
    }

    private static void setSslSystemProperties() {
        Properties systemProps = System.getProperties();
        systemProps.put("javax.net.ssl.trustStore", TestUtil.getAbsolutePath(TestUtil.TRUST_STORE_FILE_PATH));
        systemProps.put("javax.net.ssl.trustStorePassword", TestUtil.KEY_STORE_PASSWORD);
        System.setProperties(systemProps);
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            httpsServer.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for clean up");
        }
    }
}

