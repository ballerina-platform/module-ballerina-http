/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

package io.ballerina.stdlib.http.transport.pkcs;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;

/**
 * Test case for testing PKCS12 keystore and truststore.
 */
public class PKCSTest {

    private static final Logger LOG = LoggerFactory.getLogger(PKCSTest.class);

    private static HttpClientConnector httpClientConnector;
    private String password = "ballerina";
    private String tlsStoreType = "PKCS12";
    private HttpWsConnectorFactory httpConnectorFactory;
    private ServerConnector serverConnector;

    @BeforeClass
    public void setup() throws Exception {
        httpConnectorFactory = new DefaultHttpWsConnectorFactory();

        ListenerConfiguration listenerConfiguration = getListenerConfiguration();
        serverConnector = httpConnectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        httpClientConnector = httpConnectorFactory.createHttpsClientConnector(new HashMap<>(), getSenderConfigs());
    }

    private ListenerConfiguration getListenerConfiguration() {
        ListenerConfiguration listenerConfiguration = ListenerConfiguration.getDefault();
        listenerConfiguration.setPort(TestUtil.SERVER_PORT3);
        //set PKCS12 keystore to ballerina server.
        String keyStoreFile = "/simple-test-config/wso2carbon.p12";
        listenerConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(keyStoreFile));
        listenerConfiguration.setKeyStorePass(password);
        listenerConfiguration.setScheme(HTTPS_SCHEME);
        listenerConfiguration.setTLSStoreType(tlsStoreType);
        return listenerConfiguration;
    }

    private SenderConfiguration getSenderConfigs() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        String trustStoreFile = "/simple-test-config/client-truststore.p12";
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(trustStoreFile));
        senderConfiguration.setTrustStorePass(password);
        senderConfiguration.setTLSStoreType(tlsStoreType);
        senderConfiguration.setScheme(HTTPS_SCHEME);
        return senderConfiguration;
    }

    @Test
    public void testPKCS12() {
        TestUtil.testHttpsPost(httpClientConnector, TestUtil.SERVER_PORT3);
    }
    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        serverConnector.stop();
        httpClientConnector.close();
        try {
            httpConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
