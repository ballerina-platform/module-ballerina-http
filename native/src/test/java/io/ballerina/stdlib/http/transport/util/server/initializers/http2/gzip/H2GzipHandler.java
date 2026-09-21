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

package io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpServerUpgradeHandler;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.Http2ConnectionDecoder;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2Flags;
import io.netty.handler.codec.http2.Http2FrameListener;
import io.netty.handler.codec.http2.Http2Headers;
import io.netty.handler.codec.http2.Http2Settings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static io.ballerina.stdlib.http.transport.util.Http2Util.http1HeadersToHttp2Headers;
import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static io.ballerina.stdlib.http.transport.util.TestUtil.TEST_HOST;
import static io.netty.handler.codec.http.HttpHeaderNames.CONTENT_ENCODING;
import static io.netty.handler.codec.http.HttpHeaderValues.GZIP;
import static io.netty.handler.codec.http.HttpMethod.GET;
import static io.netty.handler.codec.http.HttpResponseStatus.OK;

/**
 * Responds with a body declared as {@code content-encoding: gzip}, which the requested path decides is valid or
 * malformed. A request for {@link GzipPayloads#PATH_PUSH} additionally pushes a malformed response.
 */
public final class H2GzipHandler extends Http2ConnectionHandler implements Http2FrameListener {

    private static final Logger LOG = LoggerFactory.getLogger(H2GzipHandler.class);

    private final Map<Integer, String> requestedPaths = new ConcurrentHashMap<>();

    H2GzipHandler(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder, Http2Settings initialSettings) {
        super(decoder, encoder, initialSettings);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof HttpServerUpgradeHandler.UpgradeEvent) {
            HttpServerUpgradeHandler.UpgradeEvent upgradeEvent = (HttpServerUpgradeHandler.UpgradeEvent) evt;
            onHeadersRead(ctx, 1, http1HeadersToHttp2Headers(upgradeEvent.upgradeRequest()), 0, true);
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        LOG.error("Exception occurred in H2GzipHandler : {}", cause.getMessage());
        super.exceptionCaught(ctx, cause);
        ctx.close();
    }

    private void sendResponse(ChannelHandlerContext ctx, int streamId) {
        String path = requestedPaths.remove(streamId);
        boolean push = path != null && path.contains(GzipPayloads.PATH_PUSH);
        int promisedStreamId = push ? writePushPromise(ctx, streamId) : -1;
        writeGzipResponse(ctx, streamId, GzipPayloads.payloadFor(path));
        if (push) {
            writeGzipResponse(ctx, promisedStreamId, GzipPayloads.malformedGzip());
        }
        ctx.flush();
    }

    private int writePushPromise(ChannelHandlerContext ctx, int streamId) {
        int promisedStreamId = connection().local().incrementAndGetNextStreamId();
        Http2Headers promiseHeaders = new DefaultHttp2Headers().method(GET.asciiName())
                .scheme("http").authority(TEST_HOST + ":" + HTTP_SERVER_PORT)
                .path(GzipPayloads.PATH_MALFORMED_GZIP);
        encoder().writePushPromise(ctx, streamId, promisedStreamId, promiseHeaders, 0, ctx.newPromise());
        return promisedStreamId;
    }

    private void writeGzipResponse(ChannelHandlerContext ctx, int streamId, byte[] body) {
        Http2Headers headers = new DefaultHttp2Headers().status(OK.codeAsText());
        headers.set(CONTENT_ENCODING, GZIP);
        encoder().writeHeaders(ctx, streamId, headers, 0, false, ctx.newPromise());
        encoder().writeData(ctx, streamId, Unpooled.wrappedBuffer(body), 0, true, ctx.newPromise());
    }

    @Override
    public int onDataRead(ChannelHandlerContext ctx, int streamId, ByteBuf data, int padding, boolean endOfStream) {
        int processed = data.readableBytes() + padding;
        if (endOfStream) {
            sendResponse(ctx, streamId);
        }
        return processed;
    }

    @Override
    public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int padding,
                              boolean endOfStream) {
        if (headers.path() != null) {
            requestedPaths.put(streamId, headers.path().toString());
        }
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
    public void onPriorityRead(ChannelHandlerContext ctx, int streamId, int streamDependency, short weight,
                               boolean exclusive) {
        LOG.debug("onPriorityRead {}", streamId);
    }

    @Override
    public void onRstStreamRead(ChannelHandlerContext ctx, int streamId, long errorCode) {
        requestedPaths.remove(streamId);
        LOG.debug("onRstStreamRead {}", streamId);
    }

    @Override
    public void onSettingsAckRead(ChannelHandlerContext ctx) {
        LOG.debug("onSettingsAckRead");
    }

    @Override
    public void onSettingsRead(ChannelHandlerContext ctx, Http2Settings settings) {
        LOG.debug("onSettingsRead");
    }

    @Override
    public void onPingRead(ChannelHandlerContext ctx, long data) {
        LOG.debug("onPingRead");
    }

    @Override
    public void onPingAckRead(ChannelHandlerContext ctx, long data) {
        LOG.debug("onPingAckRead");
    }

    @Override
    public void onPushPromiseRead(ChannelHandlerContext ctx, int streamId, int promisedStreamId, Http2Headers headers,
                                  int padding) {
        LOG.debug("onPushPromiseRead {}", streamId);
    }

    @Override
    public void onGoAwayRead(ChannelHandlerContext ctx, int lastStreamId, long errorCode, ByteBuf debugData) {
        LOG.debug("onGoAwayRead {}", lastStreamId);
    }

    @Override
    public void onWindowUpdateRead(ChannelHandlerContext ctx, int streamId, int windowSizeIncrement) {
        LOG.debug("onWindowUpdateRead {}", streamId);
    }

    @Override
    public void onUnknownFrame(ChannelHandlerContext ctx, byte frameType, int streamId, Http2Flags flags,
                               ByteBuf payload) {
        LOG.debug("onUnknownFrame {}", streamId);
    }
}
