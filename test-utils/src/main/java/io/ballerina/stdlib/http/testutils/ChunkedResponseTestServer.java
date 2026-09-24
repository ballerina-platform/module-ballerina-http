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
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.HttpUtil;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.handler.codec.http.QueryStringDecoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static io.netty.handler.codec.http.HttpVersion.HTTP_1_1;

/**
 * A server replying with a chunked body whose chunk sizes and pacing come from the request, so a test can decide
 * how many pieces a client buffers and how long it waits between them, which a Ballerina service cannot control.
 * {@code /chunks/400,400,400?delay=50} sends three 400 byte chunks, each flushed 50 ms after the previous one.
 */
final class ChunkedResponseTestServer {

    private static final Logger log = LoggerFactory.getLogger(ChunkedResponseTestServer.class);

    private static final Map<Integer, RunningServer> SERVERS = new ConcurrentHashMap<>();

    private ChunkedResponseTestServer() {}

    static void start(int port) throws InterruptedException {
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Channel channel = new ServerBootstrap().group(group).channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) {
                            socketChannel.pipeline().addLast(new HttpServerCodec(), new HttpObjectAggregator(1024),
                                                             new ChunkedResponseHandler());
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

    private static final class ChunkedResponseHandler extends SimpleChannelInboundHandler<FullHttpRequest> {

        @Override
        protected void channelRead0(ChannelHandlerContext ctx, FullHttpRequest request) {
            QueryStringDecoder decoder = new QueryStringDecoder(request.uri());
            String path = decoder.path();
            int[] chunkSizes = Arrays.stream(path.substring(path.lastIndexOf('/') + 1).split(","))
                    .mapToInt(Integer::parseInt).toArray();
            List<String> delay = decoder.parameters().get("delay");
            long delayMillis = delay == null ? 0 : Long.parseLong(delay.get(0));

            HttpResponse response = new DefaultHttpResponse(HTTP_1_1, OK);
            HttpUtil.setTransferEncodingChunked(response, true);
            ctx.writeAndFlush(response);
            writeChunk(ctx, chunkSizes, 0, delayMillis);
        }

        private void writeChunk(ChannelHandlerContext ctx, int[] chunkSizes, int index, long delayMillis) {
            if (!ctx.channel().isActive()) {
                return;
            }
            if (index == chunkSizes.length) {
                ctx.writeAndFlush(LastHttpContent.EMPTY_LAST_CONTENT);
                return;
            }
            ctx.executor().schedule(() -> {
                byte[] chunk = new byte[chunkSizes[index]];
                Arrays.fill(chunk, (byte) 'x');
                ctx.writeAndFlush(new DefaultHttpContent(Unpooled.wrappedBuffer(chunk)));
                writeChunk(ctx, chunkSizes, index + 1, delayMillis);
            }, index == 0 ? 0 : delayMillis, TimeUnit.MILLISECONDS);
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
