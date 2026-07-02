/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.bootstrap.Bootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.Http2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2FrameAdapter;
import io.netty.handler.codec.http2.Http2Settings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Tests that the HTTP/2 server advertises {@code SETTINGS_MAX_CONCURRENT_STREAMS=100} in the
 * initial SETTINGS frame. The fixed limit of 100 prevents unbounded stream
 * creation and heap exhaustion.
 */
public class Http2MaxConcurrentStreamsTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2MaxConcurrentStreamsTestCase.class);

    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    private void startServer(int port) throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(port);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory.createServerConnector(
                TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
    }

    @Test(description = "Server must advertise 100 concurrent streams in the initial SETTINGS frame")
    public void testServerAdvertisesDefaultMaxConcurrentStreams() throws Exception {
        startServer(TestUtil.HTTP_SERVER_PORT);
        Long maxConcurrentStreams = captureMaxConcurrentStreamsFromSettings(TestUtil.HTTP_SERVER_PORT);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, 100L,
                "Server must advertise SETTINGS_MAX_CONCURRENT_STREAMS=100 by default");
    }

    @AfterMethod
    public void cleanUp() {
        if (serverConnector != null) {
            serverConnector.stop();
        }
        if (connectorFactory != null) {
            try {
                connectorFactory.shutdown();
            } catch (InterruptedException e) {
                LOG.warn("Interrupted while waiting for HttpWsFactory to close");
            }
        }
    }

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
