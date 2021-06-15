/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package org.ballerinalang.net.transport.contractimpl.listener;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelId;
import io.netty.handler.logging.LogLevel;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.net.SocketAddress;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module HttpTraceLoggingHandler class functions.
 */
public class HttpTraceLoggingHandlerTest {

    @Test
    public void testHttpTraceLoggingHandler() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        Assert.assertNotNull(httpTraceLoggingHandler);

        httpTraceLoggingHandler = new HttpTraceLoggingHandler(String.class);
        Assert.assertNotNull(httpTraceLoggingHandler);

        httpTraceLoggingHandler = new HttpTraceLoggingHandler(String.class, LogLevel.INFO);
        Assert.assertNotNull(httpTraceLoggingHandler);

        httpTraceLoggingHandler = new HttpTraceLoggingHandler("name");
        Assert.assertNotNull(httpTraceLoggingHandler);

        httpTraceLoggingHandler = new HttpTraceLoggingHandler("name", LogLevel.INFO);
        Assert.assertNotNull(httpTraceLoggingHandler);
    }

    @Test
    public void testSetCorrelatedSourceId() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        httpTraceLoggingHandler.setCorrelatedSourceId("testId");
    }

    @Test
    public void testChannelRead() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        SocketAddress localAddress = mock(SocketAddress.class);
        SocketAddress remoteAddress = mock(SocketAddress.class);
        ChannelId channelId = mock(ChannelId.class);
        Object msg = new Object();
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("channelId");
        httpTraceLoggingHandler.channelRead(ctx, msg);
        when(channel.localAddress()).thenReturn(localAddress);
        when(localAddress.toString()).thenReturn("localAddress");
        when(channel.remoteAddress()).thenReturn(remoteAddress);
        when(remoteAddress.toString()).thenReturn("remoteAddress");
        httpTraceLoggingHandler.channelRead(ctx, msg);
        verify(ctx, times(2)).fireChannelRead(msg);
    }

}
