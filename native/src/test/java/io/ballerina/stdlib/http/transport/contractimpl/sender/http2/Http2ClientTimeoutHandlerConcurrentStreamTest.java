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

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.Http2Error;
import org.testng.annotations.Test;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verifies that {@link Http2ClientTimeoutHandler} keeps a separate idle budget per stream. Streams share one
 * handler instance per connection, and {@code createTimerTask} - used for the much shorter
 * {@code Expect: 100-continue} wait - must not corrupt the budget an unrelated, concurrently in-flight and
 * otherwise healthy stream on the same connection is judged against.
 */
public class Http2ClientTimeoutHandlerConcurrentStreamTest {

    private static final int STREAM_A = 1;
    private static final int STREAM_B = 3;

    // Stream A's real budget. Comfortably longer than the gap between the simulated progress updates below, so
    // a healthy stream fed progress every PROGRESS_INTERVAL_MILLIS never legitimately goes idle.
    private static final long STREAM_A_IDLE_MILLIS = 300;
    // What a concurrent Expect: 100-continue wait installs for stream B - much shorter than stream A's own
    // budget, mirroring socketIdleTimeout / 5 in WaitingFor100Continue.
    private static final long STREAM_B_CONTINUE_BUDGET_MILLIS = 50;
    private static final long PROGRESS_INTERVAL_MILLIS = 100;
    private static final int PROGRESS_UPDATES = 8;

    @Test(description = "A healthy stream fed regular progress must not be reset just because another stream "
            + "on the same connection is concurrently waiting on a much shorter Expect: 100-continue budget")
    public void testConcurrentExpectContinueStreamDoesNotShortenAnotherStreamsBudget() throws Exception {
        Http2ClientChannel http2ClientChannel = mock(Http2ClientChannel.class);

        OutboundMsgHolder msgHolderA = new OutboundMsgHolder(
                new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/a")));
        // Headers have already arrived for stream A - it is genuinely mid-transfer, not merely just sent.
        msgHolderA.setResponse(
                new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK)));

        when(http2ClientChannel.getInFlightMessage(STREAM_A)).thenReturn(msgHolderA);
        when(http2ClientChannel.getPromisedMessage(anyInt())).thenReturn(null);

        Http2TargetHandler targetHandler = mock(Http2TargetHandler.class);
        ChannelInboundHandlerAdapter marker = new ChannelInboundHandlerAdapter();
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(Constants.HTTP2_TARGET_HANDLER, targetHandler);
        channel.pipeline().addLast("marker", marker);
        ChannelHandlerContext ctx = channel.pipeline().context(marker);

        try {
            Http2ClientTimeoutHandler timeoutHandler = new Http2ClientTimeoutHandler(STREAM_A_IDLE_MILLIS,
                                                                                      http2ClientChannel);
            timeoutHandler.onStreamInit(ctx, STREAM_A);

            // Stream B starts waiting on Expect: 100-continue - the moment this happens is what corrupted the
            // shared idle budget pre-fix.
            timeoutHandler.createTimerTask(ctx, STREAM_B, STREAM_B_CONTINUE_BUDGET_MILLIS, true);

            // Feed stream A regular progress, comfortably within its own real budget but far apart relative to
            // stream B's much shorter one. Due timers are run against the *previous* progress update before a
            // fresh one is recorded, so a check that lands mid-gap sees the gap rather than an instant refresh.
            for (int i = 0; i < PROGRESS_UPDATES; i++) {
                Thread.sleep(PROGRESS_INTERVAL_MILLIS);
                channel.runScheduledPendingTasks();
                msgHolderA.setLastReadWriteTime(System.nanoTime());
            }

            verify(targetHandler, never()).resetStream(eq(ctx), eq(STREAM_A), any(Http2Error.class));
        } finally {
            channel.finishAndReleaseAll();
        }
    }
}
