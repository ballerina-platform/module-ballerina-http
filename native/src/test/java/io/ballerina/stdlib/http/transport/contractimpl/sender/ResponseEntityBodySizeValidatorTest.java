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

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;

/**
 * Verifies that {@link ResponseEntityBodySizeValidator} applies its limit to each response on its own and reports
 * an exceeded limit as such, however many body pieces were buffered when it was crossed.
 */
public class ResponseEntityBodySizeValidatorTest {

    private static final long MAX_ENTITY_BODY_SIZE = 1024;

    @Test(description = "Crossing the limit with three or more buffered pieces reports the limit and releases them")
    public void testOverflowWithManyBufferedPiecesReportsLimit() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);
        List<HttpContent> pieces = List.of(content(400), content(400), content(400));

        channel.writeInbound(chunkedResponse());
        channel.writeInbound(pieces.get(0));
        channel.writeInbound(pieces.get(1));
        IllegalStateException exception = expectThrows(IllegalStateException.class,
                                                       () -> channel.writeInbound(pieces.get(2)));

        assertEquals(exception.getMessage(),
                     "Response max entity body size exceeds: Entity body is larger than 1024 bytes. ");
        pieces.forEach(piece -> assertEquals(piece.refCnt(), 0, "Buffered piece was not released"));
        assertTrue(recorder.messages.isEmpty(), "A rejected response reached the target handler");
        channel.finishAndReleaseAll();
    }

    @Test(description = "Responses on a reused connection are each checked against the limit on their own")
    public void testLimitIsNotCarriedOverToNextResponseOnSameConnection() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);

        channel.writeInbound(chunkedResponse(), content(900), new DefaultLastHttpContent());
        channel.writeInbound(chunkedResponse(), content(200), new DefaultLastHttpContent());

        assertEquals(recorder.messages.size(), 6, "Both responses should have been passed on in full");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "A response under the limit still fails once its own body crosses it on a reused connection")
    public void testLimitStillAppliesToLaterResponseOnSameConnection() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);

        channel.writeInbound(chunkedResponse(), content(200), new DefaultLastHttpContent());
        channel.writeInbound(chunkedResponse(), content(1000));
        expectThrows(IllegalStateException.class, () -> channel.writeInbound(content(100)));

        assertEquals(recorder.messages.size(), 3, "Only the first response should have been passed on");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    @Test(description = "A response declaring a body over the limit is rejected on its headers")
    public void testOversizedContentLengthReportsLimit() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);
        HttpResponse response = new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
        response.headers().set(HttpHeaderNames.CONTENT_LENGTH, 1025);

        IllegalStateException exception = expectThrows(IllegalStateException.class,
                                                       () -> channel.writeInbound(response));

        assertEquals(exception.getMessage(),
                     "Response max entity body size exceeds: Entity body is larger than 1024 bytes. ");
        assertTrue(recorder.messages.isEmpty(), "A rejected response reached the target handler");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A message read after the connection went inactive is released rather than leaked")
    public void testMessageOnInactiveChannelIsReleased() {
        RecordingHandler recorder = new RecordingHandler();
        AtomicBoolean active = new AtomicBoolean(true);
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder) {
            @Override
            public boolean isActive() {
                return active.get() && super.isActive();
            }
        };
        HttpContent content = content(100);

        channel.writeInbound(chunkedResponse());
        active.set(false);
        channel.writeInbound(content);

        assertEquals(content.refCnt(), 0, "Content read on an inactive channel was not released");
        assertTrue(recorder.messages.isEmpty(), "Content read on an inactive channel was passed on");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A malformed response, which no body follows, is passed on for the target handler to fail")
    public void testMalformedResponseIsPassedOn() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);
        HttpResponse malformed = new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
        malformed.setDecoderResult(DecoderResult.failure(new IllegalArgumentException("invalid content length")));

        channel.writeInbound(malformed);

        assertEquals(recorder.messages, List.of(malformed), "The malformed response was held back");
        channel.finishAndReleaseAll();
    }

    @Test(description = "Pieces buffered when the connection closes mid-body are released")
    public void testBufferedContentIsReleasedOnClose() {
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE));
        List<HttpContent> pieces = List.of(content(400), content(400));

        channel.writeInbound(chunkedResponse(), pieces.get(0), pieces.get(1));
        channel.close();

        pieces.forEach(piece -> assertEquals(piece.refCnt(), 0, "Buffered piece was not released"));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Pieces buffered when the validator is removed from the pipeline are released")
    public void testBufferedContentIsReleasedWhenValidatorIsRemoved() {
        ResponseEntityBodySizeValidator validator = new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE);
        EmbeddedChannel channel = new EmbeddedChannel(validator);
        HttpContent piece = content(400);

        channel.writeInbound(chunkedResponse(), piece);
        channel.pipeline().remove(validator);

        assertEquals(piece.refCnt(), 0, "Buffered piece was not released");
        channel.finishAndReleaseAll();
    }

    @Test(description = "A content length that cannot be parsed leaves the body itself to be checked against the limit")
    public void testUnparsableContentLengthIsNotRejectedOnHeaders() {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(new ResponseEntityBodySizeValidator(MAX_ENTITY_BODY_SIZE),
                                                      recorder);
        HttpResponse response = new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
        response.headers().set(HttpHeaderNames.CONTENT_LENGTH, "abc");

        channel.writeInbound(response, content(100), new DefaultLastHttpContent());

        assertEquals(recorder.messages.size(), 3, "The response should have been passed on in full");
        recorder.releaseAll();
        channel.finishAndReleaseAll();
    }

    private static HttpResponse chunkedResponse() {
        HttpResponse response = new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
        response.headers().set(HttpHeaderNames.TRANSFER_ENCODING, "chunked");
        return response;
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

        void releaseAll() {
            messages.forEach(ReferenceCountUtil::release);
        }
    }
}
