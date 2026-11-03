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
import io.ballerina.stdlib.http.transport.message.FullHttpMessageListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.Test;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertNull;

/**
 * Verifies that {@link Http2ClientTimeoutHandler} fails the message of the stream that idled out.
 */
public class Http2ClientTimeoutHandlerPushStreamTest {

    private static final int PUSH_STREAM_ID = 2;

    @Test(description = "A push stream that idles out must fail its push response, not the completed primary one")
    public void testIdlePushStreamFailsThePushResponse() {
        OutboundMsgHolder msgHolder = new OutboundMsgHolder(
                new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/")));
        HttpCarbonResponse response = newResponse();
        response.addHttpContent(new DefaultLastHttpContent());
        response.setLastHttpContentArrived();
        msgHolder.setResponse(response);
        HttpCarbonResponse pushResponse = newResponse();
        msgHolder.addPushResponse(PUSH_STREAM_ID, pushResponse);

        Http2ClientChannel http2ClientChannel = mock(Http2ClientChannel.class);
        when(http2ClientChannel.getPromisedMessage(PUSH_STREAM_ID)).thenReturn(msgHolder);

        ChannelInboundHandlerAdapter marker = new ChannelInboundHandlerAdapter();
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(Constants.HTTP2_TARGET_HANDLER, mock(Http2TargetHandler.class));
        channel.pipeline().addLast("marker", marker);
        ChannelHandlerContext ctx = channel.pipeline().context(marker);
        try {
            new Http2ClientTimeoutHandler(1, http2ClientChannel).onStreamInit(ctx, PUSH_STREAM_ID);
            // Idleness is measured on the system clock, which advancing the channel's clock does not move
            msgHolder.setLastReadWriteTime(System.nanoTime() - TimeUnit.SECONDS.toNanos(1));
            channel.advanceTimeBy(1, TimeUnit.MILLISECONDS);
            channel.runScheduledPendingTasks();

            assertNotNull(getContentFailure(pushResponse), "The push response should fail");
            assertNull(getContentFailure(response), "The completed primary response should not fail");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    private static HttpCarbonResponse newResponse() {
        return new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
    }

    private static Exception getContentFailure(HttpCarbonMessage message) {
        AtomicReference<Exception> failure = new AtomicReference<>();
        message.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage httpCarbonMessage) {
                // Only a failure is recorded
            }

            @Override
            public void onError(Exception error) {
                failure.set(error);
            }
        });
        return failure.get();
    }
}
