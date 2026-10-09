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
import io.netty.buffer.ByteBufUtil;
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
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.HttpUtil;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.handler.codec.http.QueryStringDecoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static io.netty.handler.codec.http.HttpVersion.HTTP_1_1;

/**
 * Replies to {@code /chunks/400,400,400?delay=50} with those chunk sizes flushed 50 ms apart, to
 * {@code /sse/3,1,5?delay=50} with the request body sent back as {@code text/event-stream} in chunks of those sizes
 * (the last chunk carries whatever is left), and to {@code /malformed} with a response the client cannot decode.
 */
final class ChunkedResponseTestServer {

    private static final Logger log = LoggerFactory.getLogger(ChunkedResponseTestServer.class);

    private static final String PATH_MALFORMED = "/malformed";
    private static final String PATH_SSE_PREFIX = "/sse/";
    private static final int MAX_REQUEST_BODY_SIZE = 1024 * 1024;
    private static final String MALFORMED_RESPONSE = "HTTP/1.1 200 OK\r\nContent-Length: abc\r\n\r\n";
    private static final Map<Integer, RunningServer> SERVERS = new ConcurrentHashMap<>();

    private ChunkedResponseTestServer() {}

    static void start(int port) throws InterruptedException {
        EventLoopGroup group = new NioEventLoopGroup(1);
        try {
            Channel channel = new ServerBootstrap().group(group).channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) {
                            socketChannel.pipeline().addLast(new HttpServerCodec(),
                                                             new HttpObjectAggregator(MAX_REQUEST_BODY_SIZE),
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
            if (PATH_MALFORMED.equals(path)) {
                // Written below the codec, whose encoder rejects raw bytes in place of a response.
                ctx.pipeline().firstContext()
                        .writeAndFlush(Unpooled.copiedBuffer(MALFORMED_RESPONSE, StandardCharsets.US_ASCII));
                return;
            }
            int[] chunkSizes = Arrays.stream(path.substring(path.lastIndexOf('/') + 1).split(","))
                    .mapToInt(Integer::parseInt).toArray();
            List<String> delay = decoder.parameters().get("delay");
            long delayMillis = delay == null ? 0 : Long.parseLong(delay.get(0));

            HttpResponse response = new DefaultHttpResponse(HTTP_1_1, OK);
            HttpUtil.setTransferEncodingChunked(response, true);
            byte[] body;
            if (path.startsWith(PATH_SSE_PREFIX)) {
                response.headers().set(HttpHeaderNames.CONTENT_TYPE, "text/event-stream");
                body = ByteBufUtil.getBytes(request.content());
                chunkSizes = splitInto(body.length, chunkSizes);
            } else {
                body = new byte[Arrays.stream(chunkSizes).sum()];
                Arrays.fill(body, (byte) 'x');
            }
            ctx.writeAndFlush(response);
            writeChunk(ctx, body, 0, chunkSizes, 0, delayMillis);
        }

        // Applies the requested sizes in turn and sends whatever is left of the body as the final chunk.
        private static int[] splitInto(int bodyLength, int[] chunkSizes) {
            List<Integer> sizes = new ArrayList<>();
            int remaining = bodyLength;
            for (int size : chunkSizes) {
                if (remaining == 0) {
                    break;
                }
                int chunkSize = Math.min(size, remaining);
                sizes.add(chunkSize);
                remaining -= chunkSize;
            }
            if (remaining > 0) {
                sizes.add(remaining);
            }
            return sizes.stream().mapToInt(Integer::intValue).toArray();
        }

        private void writeChunk(ChannelHandlerContext ctx, byte[] body, int offset, int[] chunkSizes, int index,
                                long delayMillis) {
            if (!ctx.channel().isActive()) {
                return;
            }
            if (index == chunkSizes.length) {
                ctx.writeAndFlush(LastHttpContent.EMPTY_LAST_CONTENT);
                return;
            }
            ctx.executor().schedule(() -> {
                ctx.writeAndFlush(new DefaultHttpContent(Unpooled.wrappedBuffer(body, offset, chunkSizes[index])));
                writeChunk(ctx, body, offset + chunkSizes[index], chunkSizes, index + 1, delayMillis);
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
