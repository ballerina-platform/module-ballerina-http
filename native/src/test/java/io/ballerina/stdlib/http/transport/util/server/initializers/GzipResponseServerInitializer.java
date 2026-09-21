/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.util.server.initializers;

import io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip.GzipPayloads;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.DefaultFullHttpResponse;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.LastHttpContent;

import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_ENCODING;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_LENGTH;
import static io.netty.handler.codec.http.HttpHeaderValues.GZIP;
import static io.netty.handler.codec.http.HttpVersion.HTTP_1_1;

/**
 * An HTTP/1.1 server which always declares a gzip content encoding, with the requested path deciding whether the
 * body is valid, malformed or truncated.
 */
public class GzipResponseServerInitializer extends HttpServerInitializer {

    @Override
    protected void addBusinessLogicHandler(Channel channel) {
        channel.pipeline().addLast("handler", new GzipResponseHandler());
    }

    private static class GzipResponseHandler extends ChannelInboundHandlerAdapter {

        private String path;

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof HttpRequest) {
                path = ((HttpRequest) msg).uri();
            } else if (msg instanceof LastHttpContent) {
                byte[] payload = GzipPayloads.payloadFor(path);
                FullHttpResponse response = new DefaultFullHttpResponse(HTTP_1_1, HttpResponseStatus.OK,
                        Unpooled.wrappedBuffer(payload));
                response.headers().set(CONTENT_ENCODING, GZIP);
                response.headers().set(CONTENT_LENGTH, payload.length);
                ctx.writeAndFlush(response).addListener(ChannelFutureListener.CLOSE);
            }
        }
    }
}
