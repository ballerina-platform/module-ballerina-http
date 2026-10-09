/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
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
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.MultiThreadIoEventLoopGroup;
import io.netty.channel.nio.NioIoHandler;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http2.Http2CodecUtil;
import io.netty.handler.codec.http2.Http2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2FrameAdapter;
import io.netty.handler.codec.http2.Http2Headers;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;

/**
 * Tests that the HTTP/2 client and listener raise their connection-level receive window to the configured
 * {@code http2InitialWindowSize}, which SETTINGS_INITIAL_WINDOW_SIZE alone only applies to streams.
 */
public class Http2ConnectionWindowTest {

    private static final int WINDOW_SIZE = 1024 * 1024;

    private EventLoopGroup peerGroup;
    private Channel peerChannel;
    private HttpWsConnectorFactory connectorFactory;
    private HttpClientConnector client;
    private ServerConnector serverConnector;

    @Test(timeOut = 30000)
    public void testClientRaisesItsConnectionWindow() throws Exception {
        CompletableFuture<Integer> connectionWindowUpdate = new CompletableFuture<>();
        peerGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        peerChannel = new ServerBootstrap()
                .group(peerGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ch.pipeline().addLast(new Http2ConnectionHandlerBuilder().server(true)
                                .frameListener(new ConnectionWindowUpdateRecorder(connectionWindowUpdate)).build());
                    }
                })
                .bind(HTTP_SERVER_PORT).sync().channel();

        connectorFactory = new DefaultHttpWsConnectorFactory();
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                                                                                           Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        senderConfiguration.setHttp2InitialWindowSize(WINDOW_SIZE);
        client = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
        client.send(TestUtil.createHttpsPostReq(HTTP_SERVER_PORT, "hello", "/"));

        assertEquals(connectionWindowUpdate.get(10, TimeUnit.SECONDS).intValue(),
                     WINDOW_SIZE - Http2CodecUtil.DEFAULT_WINDOW_SIZE);
    }

    @Test(timeOut = 30000)
    public void testListenerRaisesItsConnectionWindow() throws Exception {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setHttp2InitialWindowSize(WINDOW_SIZE);
        serverConnector = connectorFactory.createServerConnector(TestUtil.getDefaultServerBootstrapConfig(),
                                                                 listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new EchoMessageListener());
        serverConnectorFuture.sync();

        CompletableFuture<Integer> connectionWindowUpdate = new CompletableFuture<>();
        peerGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        peerChannel = new Bootstrap()
                .group(peerGroup)
                .channel(NioSocketChannel.class)
                .handler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ch.pipeline().addLast(new Http2ConnectionHandlerBuilder().server(false)
                                .frameListener(new ConnectionWindowUpdateRecorder(connectionWindowUpdate)).build());
                    }
                })
                .connect(TestUtil.TEST_HOST, HTTP_SERVER_PORT).sync().channel();

        assertEquals(connectionWindowUpdate.get(10, TimeUnit.SECONDS).intValue(),
                     WINDOW_SIZE - Http2CodecUtil.DEFAULT_WINDOW_SIZE);
    }

    @AfterMethod(alwaysRun = true)
    public void cleanUp() throws InterruptedException {
        if (client != null) {
            client.close();
            client = null;
        }
        if (serverConnector != null) {
            serverConnector.stop();
            serverConnector = null;
        }
        if (connectorFactory != null) {
            connectorFactory.shutdown();
            connectorFactory = null;
        }
        if (peerChannel != null) {
            peerChannel.close().sync();
            peerChannel = null;
        }
        if (peerGroup != null) {
            peerGroup.shutdownGracefully(0, 1, TimeUnit.SECONDS).sync();
            peerGroup = null;
        }
    }

    /**
     * Records the increment of the first WINDOW_UPDATE the peer receives on the connection stream.
     */
    private static final class ConnectionWindowUpdateRecorder extends Http2FrameAdapter {
        private final CompletableFuture<Integer> connectionWindowUpdate;

        ConnectionWindowUpdateRecorder(CompletableFuture<Integer> connectionWindowUpdate) {
            this.connectionWindowUpdate = connectionWindowUpdate;
        }

        @Override
        public void onWindowUpdateRead(ChannelHandlerContext ctx, int streamId, int windowSizeIncrement) {
            if (streamId == Http2CodecUtil.CONNECTION_STREAM_ID) {
                connectionWindowUpdate.complete(windowSizeIncrement);
            }
        }

        @Override
        public int onDataRead(ChannelHandlerContext ctx, int streamId, ByteBuf data, int padding,
                              boolean endOfStream) {
            return data.readableBytes() + padding;
        }

        @Override
        public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int padding,
                                  boolean endStream) {
        }
    }
}
