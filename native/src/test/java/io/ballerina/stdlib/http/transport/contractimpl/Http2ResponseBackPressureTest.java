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

package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.message.DefaultListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.PassthroughBackPressureListener;
import io.ballerina.stdlib.http.transport.message.ServerRemoteFlowControlListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.Http2RemoteFlowController;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that a passthrough response which suspended reads on its backend connection, because its HTTP/2 response
 * stream was unwritable, does not leave them suspended once the stream finishes.
 */
public class Http2ResponseBackPressureTest {

    private static final int STREAM_ID = 3;

    private EmbeddedChannel backendChannel;
    private ServerRemoteFlowControlListener flowControlListener;
    private Http2OutboundRespListener.ResponseWriter writer;

    @BeforeMethod
    public void setUp() {
        ChannelInboundHandlerAdapter marker = new ChannelInboundHandlerAdapter();
        backendChannel = new EmbeddedChannel(marker);
        ChannelHandlerContext backendContext = backendChannel.pipeline().context(marker);

        flowControlListener = new ServerRemoteFlowControlListener(mock(Http2RemoteFlowController.class));
        Http2OutboundRespListener respListener = new Http2OutboundRespListener(
                null, new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/")),
                backendContext, null, null, STREAM_ID, "test", null, flowControlListener, null);
        writer = respListener.new ResponseWriter(STREAM_ID);
        writer.getBackPressureObservable().setListener(
                new PassthroughBackPressureListener(backendContext, new DefaultListener(backendContext)));
        flowControlListener.addResponseWriter(writer);
    }

    @AfterMethod
    public void tearDown() {
        backendChannel.finishAndReleaseAll();
    }

    @Test(description = "Reads suspended by an unwritable response stream resume when the stream completes")
    public void testCompletedResponseStreamResumesSuspendedReads() {
        writer.setStreamWritable(false);
        writer.getBackPressureObservable().notifyUnWritable();
        assertFalse(backendChannel.config().isAutoRead());

        flowControlListener.removeResponseWriter(writer);

        assertTrue(backendChannel.config().isAutoRead(),
                   "The backend connection was left with reads suspended after the response completed");
        assertTrue(writer.isStreamWritable(), "A response chunk still on its way would suspend reads again");
    }

    @Test(description = "Completing a response stream does not resume reads that something else suspended")
    public void testCompletedResponseStreamLeavesReadsItDidNotSuspend() {
        backendChannel.config().setAutoRead(false);

        flowControlListener.removeResponseWriter(writer);

        assertFalse(backendChannel.config().isAutoRead());
    }
}
