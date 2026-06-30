/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.bootstrap.Bootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.Http2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2FrameAdapter;
import io.netty.handler.codec.http2.Http2Settings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.Http2Util.getTestHttp2Client;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Tests that the HTTP/2 server advertises a bounded maxConcurrentStreams value in its initial SETTINGS frame
 * and that the system property {@code http.http2.maxConcurrentStreams} can override the default.
 * Verifies the fix for CVE-2026-47244 (unbounded stream creation via DefaultHttp2Connection).
 */
public class Http2MaxConcurrentStreamsTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2MaxConcurrentStreamsTestCase.class);
    private static final int DEFAULT_MAX_CONCURRENT_STREAMS = 100;

    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory.createServerConnector(
                TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
    }

    @Test(description = "Server must advertise maxConcurrentStreams=100 in the initial SETTINGS frame by default "
            + "(CVE-2026-47244: prevents unbounded stream creation and heap exhaustion)")
    public void testDefaultMaxConcurrentStreamsAdvertisedViaPriorKnowledge() throws Exception {
        Long maxConcurrentStreams = captureMaxConcurrentStreamsFromSettings(TestUtil.HTTP_SERVER_PORT);
        assertNotNull(maxConcurrentStreams,
                "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, DEFAULT_MAX_CONCURRENT_STREAMS,
                "Server must advertise maxConcurrentStreams=100 by default to bound concurrent stream creation");
    }

    @Test(description = "ListenerConfiguration.http2MaxConcurrentStreams must override the default limit per listener, "
            + "allowing per-listener tuning of concurrent stream capacity")
    public void testListenerConfigOverridesMaxConcurrentStreams() throws Exception {
        int customLimit = 50;
        HttpWsConnectorFactory factory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration config = new ListenerConfiguration();
        config.setPort(TestUtil.SERVER_PORT2);
        config.setScheme(Constants.HTTP_SCHEME);
        config.setVersion(Constants.HTTP_2_0);
        config.setHttp2MaxConcurrentStreams(customLimit);
        ServerConnector connector = factory.createServerConnector(
                TestUtil.getDefaultServerBootstrapConfig(), config);
        ServerConnectorFuture future = connector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
        try {
            Long maxConcurrentStreams = captureMaxConcurrentStreamsFromSettings(TestUtil.SERVER_PORT2);
            assertNotNull(maxConcurrentStreams,
                    "maxConcurrentStreams must be present in server SETTINGS frame");
            assertEquals((long) maxConcurrentStreams, customLimit,
                    "ListenerConfiguration must override the default maxConcurrentStreams value");
        } finally {
            connector.stop();
            try {
                factory.shutdown();
            } catch (InterruptedException e) {
                LOG.warn("Interrupted while shutting down factory for listener config test");
            }
        }
    }

    @Test(description = "Normal HTTP/2 requests must succeed when the server enforces the default stream limit")
    public void testRequestsSucceedWithDefaultStreamLimit() {
        HttpClientConnector client = getTestHttp2Client(connectorFactory, true);
        String testValue = "Test Http2 Message";
        HttpCarbonMessage request = MessageGenerator.generateRequest(HttpMethod.POST, testValue);
        HttpCarbonMessage response = new MessageSender(client).sendMessage(request);
        assertNotNull(response, "Expected response not received");
        String result = TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        assertEquals(result, testValue, "Expected response payload not received");
        client.close();
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

    /**
     * Opens a raw HTTP/2 prior-knowledge connection to the server, waits for the server's initial SETTINGS frame,
     * and returns the advertised {@code maxConcurrentStreams} value.
     */
    private static Long captureMaxConcurrentStreamsFromSettings(int port) throws Exception {
        CompletableFuture<Long> maxStreamsFuture = new CompletableFuture<>();
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            DefaultHttp2Connection connection = new DefaultHttp2Connection(false);
                            ch.pipeline().addLast(new Http2ConnectionHandlerBuilder()
                                    .connection(connection)
                                    .frameListener(new Http2FrameAdapter() {
                                        @Override
                                        public void onSettingsRead(ChannelHandlerContext ctx, Http2Settings settings)
                                                throws Http2Exception {
                                            Long value = settings.maxConcurrentStreams();
                                            if (value != null && !maxStreamsFuture.isDone()) {
                                                maxStreamsFuture.complete(value);
                                            }
                                        }
                                    })
                                    .build());
                        }
                    });
            Channel channel = bootstrap.connect(TestUtil.TEST_HOST, port).syncUninterruptibly().channel();
            Long result = maxStreamsFuture.get(5, TimeUnit.SECONDS);
            channel.close().syncUninterruptibly();
            return result;
        } finally {
            group.shutdownGracefully();
        }
    }
}
