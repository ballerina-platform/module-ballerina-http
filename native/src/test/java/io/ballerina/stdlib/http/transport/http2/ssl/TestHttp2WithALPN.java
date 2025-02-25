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

package io.ballerina.stdlib.http.transport.http2.ssl;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_1_1;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_2_0;
import static io.ballerina.stdlib.http.transport.util.Http2Util.getH2ListenerConfigs;
import static io.ballerina.stdlib.http.transport.util.Http2Util.getSenderConfigs;

/**
 * A test case consisting of a http2 client and server communicating over TLS.
 */
public class TestHttp2WithALPN {

    private static final Logger LOG = LoggerFactory.getLogger(TestHttp2WithALPN.class);
    private ServerConnector serverConnector;
    private HttpClientConnector http1ClientConnector;
    private HttpClientConnector http2ClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws Exception {

        HttpWsConnectorFactory factory = new DefaultHttpWsConnectorFactory();
        serverConnector = factory
            .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), getH2ListenerConfigs());
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        connectorFactory = new DefaultHttpWsConnectorFactory();
        http2ClientConnector = connectorFactory
            .createHttpsClientConnector(new HashMap<>(), getSenderConfigs(HTTP_2_0));
        http1ClientConnector = connectorFactory
            .createHttpsClientConnector(new HashMap<>(), getSenderConfigs(String.valueOf(HTTP_1_1)));
    }

    /**
     * This test case will have ALPN negotiation for HTTP/2 request.
     */
    @Test
    public void testHttp2Post() {
        TestUtil.testHttpsPost(http2ClientConnector, TestUtil.SERVER_PORT1);
    }

    /**
     * This test case will have ALPN negotiation for HTTP/1.1 request.
     */
    @Test
    public void testHttp1_1Post() {
        TestUtil.testHttpsPost(http1ClientConnector, TestUtil.SERVER_PORT1);
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        http2ClientConnector.close();
        http1ClientConnector.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Interrupted while waiting for HttpWsFactory to shutdown", e);
        }
    }
}
