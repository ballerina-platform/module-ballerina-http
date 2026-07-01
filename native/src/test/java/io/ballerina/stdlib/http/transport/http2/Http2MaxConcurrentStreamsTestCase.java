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
 * Tests that the HTTP/2 server advertises the configured {@code SETTINGS_MAX_CONCURRENT_STREAMS}
 * value (CVE-2026-47244). A finite limit (default 100, sourced from maxActiveStreamsPerConnection)
 * prevents unbounded stream creation; the unlimited case (Integer.MAX_VALUE) preserves legacy
 * behaviour for deployments that configured {@code maxActiveStreamsPerConnection = -1}.
 */
public class Http2MaxConcurrentStreamsTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2MaxConcurrentStreamsTestCase.class);

    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    private void startServer(int port, int maxActiveStreams) throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(port);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setHttp2MaxActiveStreams(maxActiveStreams);
        serverConnector = connectorFactory.createServerConnector(
                TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
    }

    @Test(description = "Server must advertise the configured finite limit in the initial SETTINGS frame "
            + "(CVE-2026-47244: prevents unbounded stream creation and heap exhaustion)")
    public void testServerAdvertisesConfiguredMaxConcurrentStreams() throws Exception {
        startServer(TestUtil.HTTP_SERVER_PORT, 100);
        Long maxConcurrentStreams = captureMaxConcurrentStreamsFromSettings(TestUtil.HTTP_SERVER_PORT);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, 100L,
                "Server must advertise the configured SETTINGS_MAX_CONCURRENT_STREAMS");
    }

    @Test(description = "Unlimited (Integer.MAX_VALUE) advertises an effectively unbounded limit, "
            + "overriding Netty's default of 100 to preserve legacy behaviour")
    public void testServerAdvertisesUnlimitedMaxConcurrentStreams() throws Exception {
        startServer(TestUtil.SERVER_PORT2, Integer.MAX_VALUE);
        Long maxConcurrentStreams = captureMaxConcurrentStreamsFromSettings(TestUtil.SERVER_PORT2);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, (long) Integer.MAX_VALUE,
                "Server must advertise an effectively unbounded limit when configured as unlimited");
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
