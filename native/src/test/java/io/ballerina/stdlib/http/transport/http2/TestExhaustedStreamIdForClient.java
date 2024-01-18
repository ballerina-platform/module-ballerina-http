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

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http2.Http2Exception;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.ballerina.stdlib.http.transport.contract.Constants.LOCALHOST;
import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Test case for exhausted stream id for client.
 */
public class TestExhaustedStreamIdForClient {
    private static final Logger LOG = LoggerFactory.getLogger(TestExhaustedStreamIdForClient.class);

    private HttpClientConnector httpClientConnector;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private ConnectionManager connectionManager;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory
            .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                                                                                           Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);       // Force to use HTTP/2 without an upgrade
        connectionManager = new ConnectionManager(senderConfiguration.getPoolConfiguration());
        httpClientConnector = connectorFactory.createHttpClientConnector(
            HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration, connectionManager);
    }

    @Test(description = "Once the stream ids are exhausted for a connection, the next request issued by the same " +
        "client should not fail")
    public void testExhaustedStreamId() throws Http2Exception {
        String testValue = "Test Message";

        //NOTE: Same pool is used for all three requests
        //First request will create a pool and a new connection
        HttpCarbonMessage firstMessage = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        HttpCarbonMessage firstResponse = new MessageSender(httpClientConnector).sendMessage(firstMessage);
        assertNotNull(firstResponse, "Expected response not received");
        String firstResult = TestUtil.getStringFromInputStream(
            new HttpMessageDataStreamer(firstResponse).getInputStream());
        assertEquals(firstResult, testValue, "Expected response not received");

        Http2ClientChannel http2ClientChannel = connectionManager.getHttp2ConnectionManager()
            .fetchChannel(new HttpRoute(Constants.HTTP_SCHEME, LOCALHOST,
                                               HTTP_SERVER_PORT, 0));

        //Simulate the stream id to have reached its max value for the connection.
        http2ClientChannel.getConnection().local().createStream(Integer.MAX_VALUE, false);

        //Once the stream ids are exhausted for a connection, that connection is removed from the pool.
        HttpCarbonMessage secondMessage = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        Throwable firstError = new MessageSender(httpClientConnector).sendMessageAndExpectError(secondMessage);
        assertNotNull(firstError, "Expected error not received");
        assertEquals(firstError.getMessage(), "No more streams can be created on this connection",
                "Expected error response not received");

        //Send another request using the same client and it should not fail
        HttpCarbonMessage thirdMessage = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        HttpCarbonMessage thirdResponse = new MessageSender(httpClientConnector).sendMessage(thirdMessage);
        assertNotNull(thirdResponse, "Expected response not received");
        String thirdResult = TestUtil.getStringFromInputStream(
            new HttpMessageDataStreamer(thirdResponse).getInputStream());
        assertEquals(thirdResult, testValue, "Expected response not received");
    }

    @AfterClass
    public void cleanUp() {
        httpClientConnector.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
