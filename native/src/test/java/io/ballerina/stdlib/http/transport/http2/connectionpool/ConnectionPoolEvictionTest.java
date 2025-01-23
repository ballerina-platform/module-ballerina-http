/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
package io.ballerina.stdlib.http.transport.http2.connectionpool;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static io.ballerina.stdlib.http.transport.contract.Constants.CHNL_HNDLR_CTX;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_2_0;
import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.SERVER_CONNECTOR_PORT;
import static org.testng.Assert.assertNotNull;

public class ConnectionPoolEvictionTest {

    private static final Logger LOG = LoggerFactory.getLogger(ConnectionPoolEvictionTest.class);

    private HttpWsConnectorFactory httpWsConnectorFactory;
    private ServerConnector serverConnector;

    @BeforeClass
    public void setup() {
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
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
        h2cSenderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        serverConnectorFuture.setHttpConnectorListener(new Listener());
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }
    }

    @Test
    public void testConnectionEvictionWithUpgrade() throws InterruptedException {
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        senderConfiguration.getPoolConfiguration().setMinEvictableIdleTime(2000);
        senderConfiguration.getPoolConfiguration().setTimeBetweenEvictionRuns(1000);
        senderConfiguration.setHttpVersion(HTTP_2_0);
        HttpClientConnector client = httpWsConnectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
        String firstId = getResponse(client);

        Thread.sleep(500);
        String secondId = getResponse(client);
        Assert.assertEquals(firstId, secondId);

        Thread.sleep(5000);
        String thirdId = getResponse(client);
        Assert.assertNotEquals(firstId, thirdId);
    }

    @Test
    public void testConnectionEvictionWithPriorKnowledge() throws InterruptedException {
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        senderConfiguration.getPoolConfiguration().setMinEvictableIdleTime(2000);
        senderConfiguration.getPoolConfiguration().setTimeBetweenEvictionRuns(1000);
        senderConfiguration.setHttpVersion(HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        HttpClientConnector client = httpWsConnectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
        String firstId = getResponse(client);

        Thread.sleep(500);
        String secondId = getResponse(client);
        Assert.assertEquals(firstId, secondId);

        Thread.sleep(5000);
        String thirdId = getResponse(client);
        Assert.assertNotEquals(firstId, thirdId);
    }

    private String getResponse(HttpClientConnector client) {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, null,
                SERVER_CONNECTOR_PORT, HTTP_SCHEME);
        HttpCarbonMessage response = new MessageSender(client).sendMessage(httpCarbonMessage);
        assertNotNull(response);
        return TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            httpWsConnectorFactory.shutdown();
        } catch (Exception e) {
            LOG.warn("Resource clean up is interrupted", e);
        }
    }

    static class Listener implements HttpConnectorListener {
        private final ExecutorService executor = Executors.newSingleThreadExecutor();

        @Override
        public void onMessage(HttpCarbonMessage httpRequest) {
            executor.execute(() -> {
                try {
                    HttpVersion httpVersion = new HttpVersion(Constants.HTTP_VERSION_2_0, true);
                    HttpCarbonMessage httpResponse = new HttpCarbonResponse(new DefaultHttpResponse(httpVersion,
                            HttpResponseStatus.OK));
                    httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
                    httpResponse.setHttpStatusCode(HttpResponseStatus.OK.code());
                    String id = ((Http2SourceHandler) ((ChannelHandlerContext) httpRequest
                            .getProperty(CHNL_HNDLR_CTX)).handler()).getChannelHandlerContext()
                            .channel().id().asLongText();

                    do {
                        HttpContent httpContent = httpRequest.getHttpContent();
                        if (httpContent instanceof LastHttpContent) {
                            break;
                        }
                    } while (true);

                    HttpContent httpContent = new DefaultLastHttpContent(Unpooled.wrappedBuffer(id.getBytes()));
                    httpResponse.addHttpContent(httpContent);
                    httpRequest.respond(httpResponse);
                } catch (ServerConnectorException e) {
                    LOG.error("Error occurred during message notification: {}", e.getMessage());
                }
            });
        }

        @Override
        public void onError(Throwable throwable) {}
    }
}
