/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.AbstractHttp2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.Http2ConnectionDecoder;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2FrameAdapter;
import io.netty.handler.codec.http2.Http2Headers;
import io.netty.handler.codec.http2.Http2Settings;

import java.net.InetSocketAddress;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static io.ballerina.stdlib.http.testutils.GzipTestServer.PATH_MALFORMED;
import static io.ballerina.stdlib.http.testutils.GzipTestServer.PATH_PUSH;
import static io.ballerina.stdlib.http.testutils.GzipTestServer.malformedGzip;
import static io.ballerina.stdlib.http.testutils.GzipTestServer.payloadFor;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_ENCODING;
import static io.netty.handler.codec.http.HttpHeaderValues.GZIP;
import static io.netty.handler.codec.http.HttpMethod.GET;
import static io.netty.handler.codec.http.HttpResponseStatus.OK;

/**
 * HTTP/2 (prior knowledge) counterpart of the gzip test server. A request for the push path additionally pushes a
 * response whose body is malformed.
 */
final class GzipHttp2ConnectionHandler extends Http2ConnectionHandler {

    private final RequestListener requestListener = new RequestListener();

    private GzipHttp2ConnectionHandler(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder,
                                       Http2Settings initialSettings) {
        super(decoder, encoder, initialSettings);
    }

    private void respond(ChannelHandlerContext ctx, int streamId, String path) {
        boolean push = path.contains(PATH_PUSH);
        int promisedStreamId = push ? writePushPromise(ctx, streamId) : -1;
        writeGzipResponse(ctx, streamId, payloadFor(path));
        if (push) {
            writeGzipResponse(ctx, promisedStreamId, malformedGzip());
        }
        ctx.flush();
    }

    private int writePushPromise(ChannelHandlerContext ctx, int streamId) {
        int promisedStreamId = connection().local().incrementAndGetNextStreamId();
        int port = ((InetSocketAddress) ctx.channel().localAddress()).getPort();
        Http2Headers promiseHeaders = new DefaultHttp2Headers().method(GET.asciiName()).scheme("http")
                .authority("localhost:" + port).path(PATH_MALFORMED);
        encoder().writePushPromise(ctx, streamId, promisedStreamId, promiseHeaders, 0, ctx.newPromise());
        return promisedStreamId;
    }

    private void writeGzipResponse(ChannelHandlerContext ctx, int streamId, byte[] body) {
        Http2Headers headers = new DefaultHttp2Headers().status(OK.codeAsText());
        headers.set(CONTENT_ENCODING, GZIP);
        encoder().writeHeaders(ctx, streamId, headers, 0, false, ctx.newPromise());
        encoder().writeData(ctx, streamId, Unpooled.wrappedBuffer(body), 0, true, ctx.newPromise());
    }

    // A request may end on its headers frame or on a trailing empty data frame, so both paths reply.
    private final class RequestListener extends Http2FrameAdapter {

        private final Map<Integer, String> requestedPaths = new ConcurrentHashMap<>();

        @Override
        public int onDataRead(ChannelHandlerContext ctx, int streamId, ByteBuf data, int padding,
                              boolean endOfStream) {
            if (endOfStream) {
                respond(ctx, streamId, requestedPaths.remove(streamId));
            }
            return data.readableBytes() + padding;
        }

        @Override
        public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int padding,
                                  boolean endOfStream) {
            String path = String.valueOf(headers.path());
            if (endOfStream) {
                respond(ctx, streamId, path);
            } else {
                requestedPaths.put(streamId, path);
            }
        }

        @Override
        public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers,
                                  int streamDependency, short weight, boolean exclusive, int padding,
                                  boolean endOfStream) {
            onHeadersRead(ctx, streamId, headers, padding, endOfStream);
        }
    }

    /**
     * Builds {@link GzipHttp2ConnectionHandler}.
     */
    static final class Builder extends AbstractHttp2ConnectionHandlerBuilder<GzipHttp2ConnectionHandler, Builder> {

        @Override
        public GzipHttp2ConnectionHandler build() {
            return super.build();
        }

        @Override
        protected GzipHttp2ConnectionHandler build(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder,
                                                   Http2Settings initialSettings) {
            GzipHttp2ConnectionHandler handler = new GzipHttp2ConnectionHandler(decoder, encoder, initialSettings);
            frameListener(handler.requestListener);
            return handler;
        }
    }
}
