/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.util.server.initializers;

import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.LastHttpContent;

import static io.ballerina.stdlib.http.transport.contract.Constants.TEXT_PLAIN;
import static io.netty.handler.codec.http.HttpHeaderNames.CONNECTION;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_LENGTH;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_TYPE;
import static io.netty.handler.codec.http.HttpVersion.HTTP_1_1;

/**
 * An initializer which responds with a complete, content-length delimited body that is large enough to make
 * the client throttle its inbound reads. Used to verify that a client which consumes such a body slowly is not
 * disconnected by the socket idle timeout.
 */
public class LargeResponseServerInitializer extends HttpServerInitializer {

    private static final int CHUNK_SIZE = 8192;

    private final int responseSize;

    public LargeResponseServerInitializer(int responseSize) {
        this.responseSize = responseSize;
    }

    protected void addBusinessLogicHandler(Channel channel) {
        channel.pipeline().addLast("handler", new LargeResponseServerHandler());
    }

    public static byte[] buildExpectedPayload(int size) {
        byte[] payload = new byte[size];
        for (int i = 0; i < size; i++) {
            payload[i] = (byte) ('A' + (i % 26));
        }
        return payload;
    }

    private class LargeResponseServerHandler extends ChannelInboundHandlerAdapter {

        private HttpRequest req;

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof HttpRequest) {
                req = (HttpRequest) msg;
            } else if (msg instanceof LastHttpContent) {
                respond(ctx);
            }
        }

        private void respond(ChannelHandlerContext ctx) {
            HttpResponse response = new DefaultHttpResponse(HTTP_1_1, HttpResponseStatus.OK);
            response.headers().set(CONTENT_TYPE, TEXT_PLAIN);
            response.headers().set(CONTENT_LENGTH, responseSize);
            response.headers().set(CONNECTION, HttpHeaderValues.KEEP_ALIVE);
            ctx.write(response);

            byte[] payload = buildExpectedPayload(responseSize);
            for (int offset = 0; offset < responseSize; offset += CHUNK_SIZE) {
                int length = Math.min(CHUNK_SIZE, responseSize - offset);
                ctx.write(new DefaultHttpContent(Unpooled.copiedBuffer(payload, offset, length)));
            }
            ctx.writeAndFlush(LastHttpContent.EMPTY_LAST_CONTENT);
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
            ctx.close();
        }
    }
}
