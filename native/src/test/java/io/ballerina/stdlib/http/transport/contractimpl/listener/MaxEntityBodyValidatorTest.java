/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultFullHttpResponse;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that {@link MaxEntityBodyValidator} applies its limit to each request on its own, so a keep-alive
 * connection does not turn it into a budget shared by every request sent on it.
 */
public class MaxEntityBodyValidatorTest {

    private static final long MAX_ENTITY_BODY_SIZE = 1000;

    @Test(description = "Requests on a keep-alive connection are each checked against the limit on their own")
    public void testLimitIsNotCarriedOverToNextRequestOnSameConnection() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);

        for (int i = 0; i < 5; i++) {
            channel.writeInbound(chunkedRequest(), content(231), new DefaultLastHttpContent());
        }

        assertEquals(recorder.messages.size(), 15, "Every request should have been passed on in full");
        assertTrue(channel.outboundMessages().isEmpty(), "An under-limit request was rejected");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "Crossing the limit with three or more buffered pieces sends 413 and releases them")
    public void testOverflowWithManyBufferedPiecesSendsEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        List<HttpContent> pieces = List.of(content(400), content(400), content(400));

        channel.writeInbound(chunkedRequest());
        pieces.forEach(channel::writeInbound);
        channel.checkException();

        HttpResponse response = channel.readOutbound();
        assertEquals(response.status(), HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE);
        pieces.forEach(piece -> assertEquals(piece.refCnt(), 0, "Buffered piece was not released"));
        assertTrue(recorder.messages.isEmpty(), "A rejected request reached the source handler");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A request declaring a body over the limit is rejected without reading its body")
    public void testOversizedContentLengthSendsEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        HttpRequest request = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/");
        request.headers().set(HttpHeaderNames.CONTENT_LENGTH, 1001);

        channel.writeInbound(request);

        HttpResponse response = channel.readOutbound();
        assertEquals(response.status(), HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE);
        assertTrue(recorder.messages.isEmpty(), "A rejected request reached the source handler");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A message read after the connection went inactive is released rather than leaked")
    public void testMessageOnInactiveChannelIsReleased() {
        RecordingHandler recorder = new RecordingHandler();
        AtomicBoolean active = new AtomicBoolean(true);
        EmbeddedChannel channel = new EmbeddedChannel(new MaxEntityBodyValidator("test-server", MAX_ENTITY_BODY_SIZE),
                                                      recorder) {
            @Override
            public boolean isActive() {
                return active.get() && super.isActive();
            }
        };
        HttpContent content = content(100);

        channel.writeInbound(chunkedRequest());
        active.set(false);
        channel.writeInbound(content);

        assertEquals(content.refCnt(), 0, "Content read on an inactive channel was not released");
        assertTrue(recorder.messages.isEmpty(), "Content read on an inactive channel was passed on");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A malformed request, which no body follows, is passed on as soon as it arrives")
    public void testMalformedRequestIsPassedOn() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        HttpRequest malformed = chunkedRequest();
        malformed.setDecoderResult(DecoderResult.failure(new IllegalArgumentException("invalid header")));

        channel.writeInbound(malformed);

        assertEquals(recorder.messages, List.of(malformed), "The malformed request was held back");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A 100-continue request is passed on as it arrives, since its body waits for the service")
    public void testContinueRequestIsPassedOnAsItArrives() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        HttpRequest request = continueRequest();
        HttpContent piece = content(600);

        channel.writeInbound(request);
        assertEquals(recorder.messages, List.of(request), "The 100-continue request was held back");
        channel.writeInbound(piece);
        assertEquals(recorder.messages, List.of(request, piece), "A body piece of the request was held back");

        assertTrue(channel.outboundMessages().isEmpty(), "An under-limit request was rejected");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "A 100-continue request whose body crosses the limit is still rejected with 413")
    public void testContinueRequestCrossingLimitSendsEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        HttpContent crossingPiece = content(600);

        channel.writeInbound(continueRequest(), content(600), crossingPiece);

        HttpResponse response = channel.readOutbound();
        assertEquals(response.status(), HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE);
        assertEquals(crossingPiece.refCnt(), 0, "The rejected piece was not released");
        assertEquals(recorder.messages.size(), 2, "Only the pieces within the limit should have been passed on");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "A body crossing the limit after the service has responded closes without a late 413")
    public void testCrossingLimitAfterResponseClosesWithoutEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);

        channel.writeInbound(continueRequest());
        channel.writeOutbound(response(HttpResponseStatus.OK));
        channel.writeInbound(content(600), content(600));

        assertEquals(((HttpResponse) channel.readOutbound()).status(), HttpResponseStatus.OK);
        assertTrue(channel.outboundMessages().isEmpty(), "A 413 was sent after the service's response");
        assertFalse(channel.isOpen(), "The connection was left open after the body crossed the limit");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "A 100 Continue sent by the service does not stop a body crossing the limit getting a 413")
    public void testCrossingLimitAfterContinueSendsEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);

        channel.writeInbound(continueRequest());
        channel.writeOutbound(response(HttpResponseStatus.CONTINUE));
        channel.writeInbound(content(600), content(600));

        assertEquals(((HttpResponse) channel.readOutbound()).status(), HttpResponseStatus.CONTINUE);
        assertEquals(((HttpResponse) channel.readOutbound()).status(), HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE);
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "The response to an earlier pipelined request is not taken as a response to the current one")
    public void testResponseToEarlierRequestDoesNotSuppressEntityTooLarge() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);

        channel.writeInbound(chunkedRequest(), content(100), new DefaultLastHttpContent());
        channel.writeInbound(continueRequest());
        channel.writeOutbound(response(HttpResponseStatus.OK));
        channel.writeInbound(content(600), content(600));

        assertEquals(((HttpResponse) channel.readOutbound()).status(), HttpResponseStatus.OK);
        assertEquals(((HttpResponse) channel.readOutbound()).status(), HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE);
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "An idle timeout while a request is held hands the request over before the timeout event")
    public void testIdleTimeoutHandsHeldRequestOver() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);
        HttpRequest request = chunkedRequest();
        HttpContent piece = content(400);
        HttpContent laterPiece = content(100);

        channel.writeInbound(request, piece);
        channel.pipeline().fireUserEventTriggered(IdleStateEvent.ALL_IDLE_STATE_EVENT);
        channel.writeInbound(laterPiece);

        assertEquals(recorder.messages, List.of(request, piece, IdleStateEvent.ALL_IDLE_STATE_EVENT, laterPiece));
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "An idle timeout with no request held is passed on untouched")
    public void testIdleTimeoutWithoutHeldRequestIsPassedOn() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = newChannel(recorder);

        channel.pipeline().fireUserEventTriggered(IdleStateEvent.ALL_IDLE_STATE_EVENT);

        assertEquals(recorder.messages, List.of(IdleStateEvent.ALL_IDLE_STATE_EVENT));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Pieces buffered when the connection closes mid-body are released")
    public void testBufferedContentIsReleasedOnClose() {
        EmbeddedChannel channel = new EmbeddedChannel(new MaxEntityBodyValidator("test-server", MAX_ENTITY_BODY_SIZE));
        List<HttpContent> pieces = List.of(content(400), content(400));

        channel.writeInbound(chunkedRequest(), pieces.get(0), pieces.get(1));
        channel.close();

        pieces.forEach(piece -> assertEquals(piece.refCnt(), 0, "Buffered piece was not released"));
        channel.finishAndReleaseAll();
    }

    private static EmbeddedChannel newChannel(RecordingHandler recorder) {
        return new EmbeddedChannel(new MaxEntityBodyValidator("test-server", MAX_ENTITY_BODY_SIZE), recorder);
    }

    private static HttpRequest chunkedRequest() {
        HttpRequest request = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/");
        request.headers().set(HttpHeaderNames.TRANSFER_ENCODING, "chunked");
        return request;
    }

    private static HttpRequest continueRequest() {
        HttpRequest request = chunkedRequest();
        request.headers().set(HttpHeaderNames.EXPECT, "100-continue");
        return request;
    }

    private static HttpResponse response(HttpResponseStatus status) {
        return new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, status);
    }

    private static HttpContent content(int size) {
        return new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[size]));
    }

    private static final class RecordingHandler extends ChannelInboundHandlerAdapter {

        private final List<Object> messages = new ArrayList<>();

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            messages.add(msg);
        }

        @Override
        public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
            messages.add(evt);
        }

        void releaseAll() {
            messages.forEach(ReferenceCountUtil::release);
        }
    }
}
