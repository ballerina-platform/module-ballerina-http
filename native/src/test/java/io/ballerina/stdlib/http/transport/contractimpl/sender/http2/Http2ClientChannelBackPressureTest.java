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

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.message.DefaultListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.PassthroughBackPressureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that a passthrough request which suspended reads on its inbound connection, because its HTTP/2 stream
 * was unwritable, does not leave them suspended once the stream finishes.
 */
public class Http2ClientChannelBackPressureTest {

    private static final HttpRoute ROUTE = new HttpRoute("http", "localhost", 9090, 0);
    private static final int STREAM_ID = 3;

    private EmbeddedChannel inboundChannel;
    private Http2ClientChannel http2ClientChannel;
    private OutboundMsgHolder outboundMsgHolder;

    @BeforeMethod
    public void setUp() {
        ChannelInboundHandlerAdapter marker = new ChannelInboundHandlerAdapter();
        inboundChannel = new EmbeddedChannel(marker);
        ChannelHandlerContext inboundContext = inboundChannel.pipeline().context(marker);

        PoolConfiguration poolConfiguration = new PoolConfiguration();
        http2ClientChannel = new Http2ClientChannel(new Http2ConnectionManager(poolConfiguration),
                                                    new DefaultHttp2Connection(false), ROUTE,
                                                    new EmbeddedChannel(), null);
        outboundMsgHolder = new OutboundMsgHolder(
                new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/")));
        outboundMsgHolder.getBackPressureObservable().setListener(
                new PassthroughBackPressureListener(inboundContext, new DefaultListener(inboundContext)));
        http2ClientChannel.putInFlightMessage(STREAM_ID, outboundMsgHolder);
    }

    @AfterMethod
    public void tearDown() {
        inboundChannel.finishAndReleaseAll();
    }

    @Test(description = "Reads suspended by an unwritable stream resume when the stream completes")
    public void testCompletedStreamResumesSuspendedInboundReads() {
        outboundMsgHolder.getBackPressureObservable().notifyUnWritable();
        assertFalse(inboundChannel.config().isAutoRead());

        http2ClientChannel.removeInFlightMessage(STREAM_ID);

        assertTrue(inboundChannel.config().isAutoRead(),
                   "The inbound connection was left with reads suspended after its request completed");
    }

    @Test(description = "A request chunk written after the stream completed does not suspend reads again")
    public void testCompletedStreamIsNotReportedUnwritable() {
        outboundMsgHolder.setStreamWritable(false);
        outboundMsgHolder.getBackPressureObservable().notifyUnWritable();

        http2ClientChannel.removeInFlightMessage(STREAM_ID);

        assertTrue(outboundMsgHolder.isStreamWritable(),
                   "A completed stream still reports unwritable, so the next request chunk suspends reads again");
        assertTrue(inboundChannel.config().isAutoRead());
    }

    @Test(description = "Completing a stream does not resume reads that something else suspended")
    public void testCompletedStreamLeavesReadsItDidNotSuspend() {
        outboundMsgHolder.getBackPressureObservable().notifyUnWritable();
        outboundMsgHolder.getBackPressureObservable().notifyWritable();
        inboundChannel.config().setAutoRead(false);

        http2ClientChannel.removeInFlightMessage(STREAM_ID);

        assertFalse(inboundChannel.config().isAutoRead());
    }
}
