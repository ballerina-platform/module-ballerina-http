/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.http2.connectionpool;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.passthrough.PassthroughMessageProcessorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.channelidsender.Http2SendChannelIDInitializer;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static io.ballerina.stdlib.http.transport.util.Http2Util.assertResult;
import static io.ballerina.stdlib.http.transport.util.Http2Util.getTestHttp2Client;
import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.SERVER_CONNECTOR_PORT;
import static org.testng.Assert.assertNotNull;

/**
 * Test case for H2C client connection pool with prior knowledge.
 *
 * @since 6.0.273
 */
public class H2ConnectionPoolWithPriorKnowledge {
    private static final Logger LOG = LoggerFactory.getLogger(H2ConnectionPoolWithPriorKnowledge.class);

    private HttpWsConnectorFactory httpWsConnectorFactory;
    private ServerConnector serverConnector;
    private HttpServer http2Server;

    @BeforeClass
    public void setup() {
        http2Server = TestUtil
            .startHTTPServer(TestUtil.HTTP_SERVER_PORT, new Http2SendChannelIDInitializer(), 1, 2);

        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory(1, 2, 2);
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(SERVER_CONNECTOR_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = httpWsConnectorFactory
            .createServerConnector(new ServerBootstrapConfiguration(new HashMap<>()), listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration h2cSenderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                                                                                              Constants.HTTP_SCHEME);
        h2cSenderConfiguration.setForceHttp2(true);
        h2cSenderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        serverConnectorFuture.setHttpConnectorListener(
            new PassthroughMessageProcessorListener(h2cSenderConfiguration, true));
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }
    }

    @Test (enabled = false)
    public void testPriorKnowledgeWithPool() {
        //Since we have only two eventloops, upstream will have two different pools.
        HttpClientConnector client1 = getTestHttp2Client(httpWsConnectorFactory, true); //Upstream uses eventloop1 pool
        String response1 = getResponse(client1);
        HttpClientConnector client2 = getTestHttp2Client(httpWsConnectorFactory, true); //Upstream uses eventloop2 pool
        String response2 = getResponse(client2);
        HttpClientConnector client3 = getTestHttp2Client(httpWsConnectorFactory, true); //Upstream uses eventloop1 pool
        String response3 = getResponse(client3);
        HttpClientConnector client4 = getTestHttp2Client(httpWsConnectorFactory, true); //Upstream uses eventloop2 pool
        String response4 = getResponse(client4);

        assertResult(response1, response2, response3, response4);
    }

    private String getResponse(HttpClientConnector client1) {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, null,
                                                                               SERVER_CONNECTOR_PORT, HTTP_SCHEME);
        HttpCarbonMessage response = new MessageSender(client1).sendMessage(httpCarbonMessage);
        assertNotNull(response);
        return TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            http2Server.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (Exception e) {
            LOG.warn("Resource clean up is interrupted", e);
        }
    }
}
