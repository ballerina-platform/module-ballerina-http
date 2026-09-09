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
import io.ballerina.stdlib.http.transport.util.Http2Util;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.bootstrap.Bootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http.DefaultFullHttpRequest;
import io.netty.handler.codec.http.HttpClientCodec;
import io.netty.handler.codec.http.HttpClientUpgradeHandler;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.Http2ClientUpgradeCodec;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2FrameAdapter;
import io.netty.handler.codec.http2.Http2Settings;
import io.netty.handler.ssl.ApplicationProtocolConfig;
import io.netty.handler.ssl.ApplicationProtocolNames;
import io.netty.handler.ssl.ApplicationProtocolNegotiationHandler;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import io.netty.handler.ssl.SslHandler;
import io.netty.handler.ssl.SslProvider;
import io.netty.handler.ssl.util.InsecureTrustManagerFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.net.InetSocketAddress;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Tests that the HTTP/2 server advertises {@code SETTINGS_MAX_CONCURRENT_STREAMS=100} in the
 * initial SETTINGS frame on every server-side HTTP/2 connection path: prior-knowledge H2C,
 * H2C upgrade, and TLS with ALPN. The fixed limit of 100 prevents unbounded stream creation
 * and heap exhaustion.
 */
public class Http2MaxConcurrentStreamsTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2MaxConcurrentStreamsTestCase.class);
    private static final long DEFAULT_MAX_CONCURRENT_STREAMS = 100L;

    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    private void startServer(ListenerConfiguration listenerConfiguration) throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        serverConnector = connectorFactory.createServerConnector(
                TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
    }

    private void startH2cServer(int port) throws InterruptedException {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(port);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        startServer(listenerConfiguration);
    }

    @Test(description = "Server must advertise 100 concurrent streams in the initial SETTINGS frame "
            + "on a prior-knowledge H2C connection")
    public void testPriorKnowledgeAdvertisesDefaultMaxConcurrentStreams() throws Exception {
        startH2cServer(TestUtil.HTTP_SERVER_PORT);
        Long maxConcurrentStreams = captureViaPriorKnowledge(TestUtil.HTTP_SERVER_PORT);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, DEFAULT_MAX_CONCURRENT_STREAMS,
                "Server must advertise SETTINGS_MAX_CONCURRENT_STREAMS=100 by default on prior-knowledge H2C");
    }

    @Test(description = "Server must advertise 100 concurrent streams in the initial SETTINGS frame "
            + "on an H2C upgrade connection")
    public void testH2cUpgradeAdvertisesDefaultMaxConcurrentStreams() throws Exception {
        startH2cServer(TestUtil.SERVER_PORT2);
        Long maxConcurrentStreams = captureViaH2cUpgrade(TestUtil.SERVER_PORT2);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, DEFAULT_MAX_CONCURRENT_STREAMS,
                "Server must advertise SETTINGS_MAX_CONCURRENT_STREAMS=100 by default on H2C upgrade");
    }

    @Test(description = "Server must advertise 100 concurrent streams in the initial SETTINGS frame "
            + "on a TLS connection negotiated via ALPN")
    public void testAlpnAdvertisesDefaultMaxConcurrentStreams() throws Exception {
        startServer(Http2Util.getH2ListenerConfigs());
        Long maxConcurrentStreams = captureViaAlpn(TestUtil.SERVER_PORT1);
        assertNotNull(maxConcurrentStreams, "maxConcurrentStreams must be present in server SETTINGS frame");
        assertEquals((long) maxConcurrentStreams, DEFAULT_MAX_CONCURRENT_STREAMS,
                "Server must advertise SETTINGS_MAX_CONCURRENT_STREAMS=100 by default over TLS+ALPN");
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

    private static Http2ConnectionHandler settingsCapturingHandler(CompletableFuture<Long> maxStreamsFuture) {
        return new Http2ConnectionHandlerBuilder()
                .connection(new DefaultHttp2Connection(false))
                .frameListener(new Http2FrameAdapter() {
                    @Override
                    public void onSettingsRead(ChannelHandlerContext ctx, Http2Settings settings) {
                        Long value = settings.maxConcurrentStreams();
                        if (value != null && !maxStreamsFuture.isDone()) {
                            maxStreamsFuture.complete(value);
                        }
                    }
                })
                .build();
    }

    private static Long captureViaPriorKnowledge(int port) throws Exception {
        CompletableFuture<Long> maxStreamsFuture = new CompletableFuture<>();
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            ch.pipeline().addLast(settingsCapturingHandler(maxStreamsFuture));
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

    private static Long captureViaH2cUpgrade(int port) throws Exception {
        CompletableFuture<Long> maxStreamsFuture = new CompletableFuture<>();
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            HttpClientCodec sourceCodec = new HttpClientCodec();
                            Http2ClientUpgradeCodec upgradeCodec =
                                    new Http2ClientUpgradeCodec(settingsCapturingHandler(maxStreamsFuture));
                            HttpClientUpgradeHandler upgradeHandler =
                                    new HttpClientUpgradeHandler(sourceCodec, upgradeCodec, 65536);
                            ch.pipeline().addLast(sourceCodec, upgradeHandler, new UpgradeRequestHandler());
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

    private static Long captureViaAlpn(int port) throws Exception {
        CompletableFuture<Long> maxStreamsFuture = new CompletableFuture<>();
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            SslContext sslContext = SslContextBuilder.forClient()
                    .sslProvider(SslProvider.JDK)
                    .trustManager(InsecureTrustManagerFactory.INSTANCE)
                    .applicationProtocolConfig(new ApplicationProtocolConfig(
                            ApplicationProtocolConfig.Protocol.ALPN,
                            ApplicationProtocolConfig.SelectorFailureBehavior.NO_ADVERTISE,
                            ApplicationProtocolConfig.SelectedListenerFailureBehavior.ACCEPT,
                            ApplicationProtocolNames.HTTP_2))
                    .build();
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            SslHandler sslHandler = sslContext.newHandler(ch.alloc(), TestUtil.TEST_HOST, port);
                            ch.pipeline().addLast(sslHandler,
                                    new ApplicationProtocolNegotiationHandler(ApplicationProtocolNames.HTTP_1_1) {
                                        @Override
                                        protected void configurePipeline(ChannelHandlerContext ctx, String protocol) {
                                            if (ApplicationProtocolNames.HTTP_2.equals(protocol)) {
                                                ctx.pipeline().addLast(settingsCapturingHandler(maxStreamsFuture));
                                            } else {
                                                maxStreamsFuture.completeExceptionally(new IllegalStateException(
                                                        "Expected ALPN to negotiate h2 but got " + protocol));
                                            }
                                        }
                                    });
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

    /**
     * Triggers the H2C cleartext upgrade by sending an initial HTTP/1.1 request.
     */
    private static final class UpgradeRequestHandler extends ChannelInboundHandlerAdapter {
        @Override
        public void channelActive(ChannelHandlerContext ctx) {
            DefaultFullHttpRequest upgradeRequest =
                    new DefaultFullHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/");
            InetSocketAddress remote = (InetSocketAddress) ctx.channel().remoteAddress();
            String hostString = remote.getHostString();
            if (hostString == null) {
                hostString = remote.getAddress().getHostAddress();
            }
            upgradeRequest.headers().set(HttpHeaderNames.HOST, hostString + ':' + remote.getPort());
            ctx.writeAndFlush(upgradeRequest);
            ctx.fireChannelActive();
            ctx.pipeline().remove(this);
        }
    }
}
