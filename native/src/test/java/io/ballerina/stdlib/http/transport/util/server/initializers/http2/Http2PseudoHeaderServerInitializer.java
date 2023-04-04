/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.util.server.initializers.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.channelidsender.H2ChannelIdHandler;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufUtil;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpServerUpgradeHandler;
import io.netty.handler.codec.http2.AbstractHttp2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.DefaultHttp2DataFrame;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.DefaultHttp2HeadersFrame;
import io.netty.handler.codec.http2.Http2ConnectionDecoder;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2Flags;
import io.netty.handler.codec.http2.Http2FrameListener;
import io.netty.handler.codec.http2.Http2FrameLogger;
import io.netty.handler.codec.http2.Http2FrameStream;
import io.netty.handler.codec.http2.Http2Headers;
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.handler.codec.http2.Http2Settings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;

import static io.ballerina.stdlib.http.transport.util.Http2Util.http1HeadersToHttp2Headers;
import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static io.netty.handler.logging.LogLevel.INFO;

/**
 * This will return the response with the pseudo header, scheme.
 */
public class Http2PseudoHeaderServerInitializer extends Http2ServerInitializer {

    private String scheme;

    public Http2PseudoHeaderServerInitializer(String scheme) {
        this.scheme = scheme;
    }

    @Override
    protected ChannelHandler getBusinessLogicHandler() {
        if (Constants.HTTPS_SCHEME.equals(scheme)) {
            return new HttpsPseudoHeaderHandlerBuilder().build();
        } else {
            return new HttpPseudoHeaderHandler();
        }
    }

    @Override
    protected Http2ConnectionHandler getBusinessLogicHandlerViaBuiler() {
        return null;
    }

    private class HttpPseudoHeaderHandler extends ChannelDuplexHandler {

        private final Logger log = LoggerFactory.getLogger(HttpPseudoHeaderHandler.class);
        private String schemeHeader = "";

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
            super.exceptionCaught(ctx, cause);
            log.error(cause.getMessage());
            ctx.close();
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
            if (msg instanceof Http2HeadersFrame) {
                onHeadersRead(ctx, (Http2HeadersFrame) msg);
            } else {
                super.channelRead(ctx, msg);
            }
        }

        @Override
        public void channelReadComplete(ChannelHandlerContext ctx) {
            ctx.flush();
        }

        private void onHeadersRead(ChannelHandlerContext ctx, Http2HeadersFrame headers) {
            schemeHeader = headers.headers().scheme().toString();
            if (headers.isEndStream()) {
                ByteBuf content = ctx.alloc().buffer();
                content.writeBytes(schemeHeader.getBytes(StandardCharsets.UTF_8));
                ByteBufUtil.writeAscii(content, " - via HTTP/2");
                sendResponse(ctx, headers.stream(), content);
            }
        }

        private void sendResponse(ChannelHandlerContext ctx, Http2FrameStream stream, ByteBuf payload) {
            Http2Headers headers = new DefaultHttp2Headers().status(OK.codeAsText());
            ctx.write(new DefaultHttp2HeadersFrame(headers).stream(stream));
            ctx.write(new DefaultHttp2DataFrame(payload, true).stream(stream));
        }
    }

    private class HttpsPseudoHeaderHandlerBuilder
            extends AbstractHttp2ConnectionHandlerBuilder<HttpsPseudoHeaderHandler, HttpsPseudoHeaderHandlerBuilder> {

        private final Http2FrameLogger logger = new Http2FrameLogger(INFO, H2ChannelIdHandler.class);

        public HttpsPseudoHeaderHandlerBuilder() {
            frameLogger(logger);
        }

        @Override
        public HttpsPseudoHeaderHandler build() {
            return super.build();
        }

        @Override
        protected HttpsPseudoHeaderHandler build(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder,
                                                 Http2Settings initialSettings) {
            HttpsPseudoHeaderHandler handler = new HttpsPseudoHeaderHandler(decoder, encoder, initialSettings);
            frameListener(handler);
            return handler;
        }
    }

    class HttpsPseudoHeaderHandler extends Http2ConnectionHandler implements Http2FrameListener {
        private final Logger logger = LoggerFactory.getLogger(HttpsPseudoHeaderHandler.class);
        private String schemeHeader = "";

        public HttpsPseudoHeaderHandler(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder,
                                        Http2Settings initialSettings) {
            super(decoder, encoder, initialSettings);
        }

        @Override
        public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
            if (evt instanceof HttpServerUpgradeHandler.UpgradeEvent) {
                HttpServerUpgradeHandler.UpgradeEvent upgradeEvent =
                        (HttpServerUpgradeHandler.UpgradeEvent) evt;
                onHeadersRead(ctx, 1, http1HeadersToHttp2Headers(upgradeEvent.upgradeRequest()), 0, true);
            }
            super.userEventTriggered(ctx, evt);
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
            logger.error("Exception occurred in H2ChannelIdHandler : {}", cause.getMessage());
            super.exceptionCaught(ctx, cause);
            ctx.close();
        }

        private void sendResponse(ChannelHandlerContext ctx, int streamId) {
            Http2Headers headers = new DefaultHttp2Headers().status(OK.codeAsText());
            encoder().writeHeaders(ctx, streamId, headers, 0, false, ctx.newPromise());
            ByteBuf content = Unpooled.wrappedBuffer((schemeHeader + " - via HTTP/2").getBytes());
            encoder().writeData(ctx, streamId, content, 0, true, ctx.newPromise());
        }

        @Override
        public int onDataRead(ChannelHandlerContext ctx, int streamId, ByteBuf data, int padding, boolean endOfStream) {
            int processed = data.readableBytes() + padding;
            if (endOfStream) {
                sendResponse(ctx, streamId);
            }
            return processed + padding;
        }

        @Override
        public void onHeadersRead(ChannelHandlerContext ctx, int streamId,
                                  Http2Headers headers, int padding, boolean endOfStream) {
            schemeHeader = headers.scheme().toString();
            if (endOfStream) {
                sendResponse(ctx, streamId);
            }
        }

        @Override
        public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int streamDependency,
                                  short weight, boolean exclusive, int padding, boolean endOfStream) {
            onHeadersRead(ctx, streamId, headers, padding, endOfStream);
        }

        @Override
        public void onPriorityRead(ChannelHandlerContext ctx, int streamId, int streamDependency,
                                   short weight, boolean exclusive) {
            logger.debug("onPriorityRead {}", streamId);
        }

        @Override
        public void onRstStreamRead(ChannelHandlerContext ctx, int streamId, long errorCode) {
            logger.debug("onRstStreamRead {}", streamId);
        }

        @Override
        public void onSettingsAckRead(ChannelHandlerContext ctx) {
            logger.debug("onSettingsAckRead");
        }

        @Override
        public void onSettingsRead(ChannelHandlerContext ctx, Http2Settings settings) {
            logger.debug("onSettingsRead");
        }

        @Override
        public void onPingRead(ChannelHandlerContext ctx, long data) {
            logger.debug("onPingRead");
        }

        @Override
        public void onPingAckRead(ChannelHandlerContext ctx, long data) {
            logger.debug("onPingAckRead");
        }

        @Override
        public void onPushPromiseRead(ChannelHandlerContext ctx, int streamId, int promisedStreamId,
                                      Http2Headers headers, int padding) {
            logger.debug("onPushPromiseRead {}", streamId);
        }

        @Override
        public void onGoAwayRead(ChannelHandlerContext ctx, int lastStreamId, long errorCode, ByteBuf debugData) {
            logger.debug("onGoAwayRead {}", lastStreamId);
        }

        @Override
        public void onWindowUpdateRead(ChannelHandlerContext ctx, int streamId, int windowSizeIncrement) {
            logger.debug("onWindowUpdateRead {}", streamId);
        }

        @Override
        public void onUnknownFrame(ChannelHandlerContext ctx, byte frameType, int streamId,
                                   Http2Flags flags, ByteBuf payload) {
            logger.debug("onUnknownFrame {}", streamId);
        }
    }
}
