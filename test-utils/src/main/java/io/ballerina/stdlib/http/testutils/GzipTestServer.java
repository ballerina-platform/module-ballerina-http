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

package io.ballerina.stdlib.http.testutils;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.http.DefaultFullHttpResponse;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.zip.GZIPOutputStream;

import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_ENCODING;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_LENGTH;
import static io.netty.handler.codec.http.HttpHeaderValues.GZIP;
import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static io.netty.handler.codec.http.HttpVersion.HTTP_1_1;

/**
 * Servers that reply with a {@code content-encoding: gzip} header over either a valid or a malformed body.
 * Kept apart from the extern functions so that validating those does not need the Netty transport classes.
 */
final class GzipTestServer {

    private static final Logger log = LoggerFactory.getLogger(GzipTestServer.class);

    static final String PATH_VALID = "/gzip/valid";
    static final String PATH_MALFORMED = "/gzip/malformed";
    static final String PATH_PUSH = "/gzip/push";
    static final String VALID_CONTENT = "{\"greeting\":\"Hello from a gzip encoded response\"}";

    private static final Map<Integer, RunningServer> SERVERS = new ConcurrentHashMap<>();

    private GzipTestServer() {}

    static void start(int port, boolean http2) throws InterruptedException {
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Channel channel = new ServerBootstrap().group(group).channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) {
                            if (http2) {
                                socketChannel.pipeline().addLast(new GzipHttp2ConnectionHandler.Builder().build());
                            } else {
                                socketChannel.pipeline().addLast(new HttpServerCodec(),
                                        new HttpObjectAggregator(1024), new Http1Handler());
                            }
                        }
                    }).bind(port).sync().channel();
            SERVERS.put(port, new RunningServer(channel, group));
        } catch (InterruptedException | RuntimeException e) {
            group.shutdownGracefully();
            throw e;
        }
    }

    static void stop(int port) throws InterruptedException {
        RunningServer server = SERVERS.remove(port);
        if (server != null) {
            server.channel.close().sync();
            server.group.shutdownGracefully(0, 1, TimeUnit.SECONDS).sync();
        }
    }

    static byte[] payloadFor(String path) {
        return path != null && path.contains(PATH_MALFORMED) ? malformedGzip() : validGzip();
    }

    // Plain bytes under a gzip content encoding, so decoding fails on the very first chunk.
    static byte[] malformedGzip() {
        return "not-a-gzip-stream".getBytes(StandardCharsets.UTF_8);
    }

    private static byte[] validGzip() {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            try (GZIPOutputStream gzip = new GZIPOutputStream(out)) {
                gzip.write(VALID_CONTENT.getBytes(StandardCharsets.UTF_8));
            }
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static final class Http1Handler extends SimpleChannelInboundHandler<FullHttpRequest> {

        @Override
        protected void channelRead0(ChannelHandlerContext ctx, FullHttpRequest request) {
            byte[] body = payloadFor(request.uri());
            FullHttpResponse response = new DefaultFullHttpResponse(HTTP_1_1, OK, Unpooled.wrappedBuffer(body));
            response.headers().set(CONTENT_ENCODING, GZIP).setInt(CONTENT_LENGTH, body.length);
            ctx.writeAndFlush(response);
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
            log.debug("Closing the connection after an error", cause);
            ctx.close();
        }
    }

    private static final class RunningServer {

        private final Channel channel;
        private final EventLoopGroup group;

        private RunningServer(Channel channel, EventLoopGroup group) {
            this.channel = channel;
            this.group = group;
        }
    }
}
