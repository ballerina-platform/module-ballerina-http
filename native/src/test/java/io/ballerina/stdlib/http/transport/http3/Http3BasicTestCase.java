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

package io.ballerina.stdlib.http.transport.http3;

import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.transport.contentaware.listeners.Http3EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http3.Http3Client;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.testng.AssertJUnit.assertEquals;

/**
 * This contains basic test cases for HTTP3 Listener.
 */
public class Http3BasicTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http3BasicTestCase.class);
    private static final String testValue = "TEST VALUE";

    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();

        listenerConfiguration.setServerHeader(TestUtil.TEST_SERVER);
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(TestUtil.KEY_STORE_FILE_PATH));
        listenerConfiguration.setKeyStorePass(TestUtil.KEY_STORE_PASSWORD);
        listenerConfiguration.setScheme(Constants.HTTPS_SCHEME);
        listenerConfiguration.setServerCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        listenerConfiguration.setServerKeyFile(TestUtil.getAbsolutePath(TestUtil.KEY_FILE));
        listenerConfiguration.setServerKeyPassword(String.valueOf(HttpConstants.
                SECURESOCKET_CONFIG_CERTKEY_KEY_PASSWORD));
        listenerConfiguration.setVersion(Constants.HTTP3_VERSION);


        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new Http3EchoMessageListener());
        future.sync();

    }

    @Test
    public void http3BasicTest() throws Exception {
        //tested using an external client written in netty
        String[] res = Http3Client.start(8490, "get", "/hello", null);
        String content = res[0];
        assertEquals(testValue, content);

    }

    @AfterClass
    public void cleanUp() {

        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
