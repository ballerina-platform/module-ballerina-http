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

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufHolder;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelId;
import io.netty.channel.ChannelPromise;
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
    public void testWrite() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        ChannelPromise promise = mock(ChannelPromise.class);
        SocketAddress localAddress = mock(SocketAddress.class);
        SocketAddress remoteAddress = mock(SocketAddress.class);
        ChannelId channelId = mock(ChannelId.class);
        Object msg = new Object();
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("channelId");
        httpTraceLoggingHandler.write(ctx, msg, promise);

        when(channel.localAddress()).thenReturn(localAddress);
        when(localAddress.toString()).thenReturn("localAddress");
        when(channel.remoteAddress()).thenReturn(remoteAddress);
        when(remoteAddress.toString()).thenReturn("remoteAddress");
        httpTraceLoggingHandler.write(ctx, msg, promise);
        verify(ctx, times(2)).write(msg, promise);
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

    @Test
    public void testChannelReadWithByteBuf() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);

        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        ChannelId channelId = mock(ChannelId.class);
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("channelId");
        ByteBuf msg = Unpooled.buffer();
        httpTraceLoggingHandler.channelRead(ctx, msg);
        msg.writeBytes(new byte[16]);
        httpTraceLoggingHandler.channelRead(ctx, msg);
        msg.clear();
        msg.writeBytes(new byte[10]);
        httpTraceLoggingHandler.channelRead(ctx, msg);
        verify(ctx, times(3)).fireChannelRead(msg);
    }

    @Test
    public void testChannelReadWithByteBufHolder() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        ChannelId channelId = mock(ChannelId.class);
        ByteBufHolder msg = mock(ByteBufHolder.class);
        ByteBuf content = Unpooled.buffer();
        when(msg.toString()).thenReturn("test");
        when(msg.content()).thenReturn(content);
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("channelId");
        httpTraceLoggingHandler.channelRead(ctx, msg);
        content.writeBytes(new byte[16]);
        httpTraceLoggingHandler.channelRead(ctx, msg);
        content.clear();
        content.writeBytes(new byte[10]);
        httpTraceLoggingHandler.channelRead(ctx, msg);
        verify(ctx, times(3)).fireChannelRead(msg);
    }

    @Test
    public void testFormatWithOnlyStringAndCtx() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        ChannelId channelId = mock(ChannelId.class);
        SocketAddress localAddress = mock(SocketAddress.class);
        SocketAddress remoteAddress = mock(SocketAddress.class);
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("55");
        when(channel.localAddress()).thenReturn(localAddress);
        when(localAddress.toString()).thenReturn("localAddress");
        when(channel.remoteAddress()).thenReturn(remoteAddress);
        when(remoteAddress.toString()).thenReturn("remoteAddress");
        String returnVal = httpTraceLoggingHandler.format(ctx, "INBOUND");
        String expected = "[id: 0x55, correlatedSource: n/a, host:localAddress - remote:remoteAddress] INBOUND";
        Assert.assertEquals(returnVal, expected);

        returnVal = httpTraceLoggingHandler.format(ctx, "CONNECT");
        expected = "[id: 0x55] CONNECT";
        Assert.assertEquals(returnVal, expected);

        returnVal = httpTraceLoggingHandler.format(ctx, "REGISTERED");
        expected = "[id: 0x55] REGISTERED";
        Assert.assertEquals(returnVal, expected);
    }

    @Test
    public void testFormatWithTwoObjects() {
        HttpTraceLoggingHandler httpTraceLoggingHandler = new HttpTraceLoggingHandler(LogLevel.INFO);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        ChannelId channelId = mock(ChannelId.class);
        SocketAddress localAddress = mock(SocketAddress.class);
        SocketAddress remoteAddress = mock(SocketAddress.class);
        String arg1 = "arg1";
        String arg2 = "arg2";
        when(ctx.channel()).thenReturn(channel);
        when(channel.id()).thenReturn(channelId);
        when(channelId.asShortText()).thenReturn("55");
        when(channel.localAddress()).thenReturn(localAddress);
        when(localAddress.toString()).thenReturn("localAddress");
        when(channel.remoteAddress()).thenReturn(remoteAddress);
        when(remoteAddress.toString()).thenReturn("remoteAddress");
        String returnVal = httpTraceLoggingHandler.format(ctx, "INBOUND", arg1, arg2);
        String expected = "[id: 0x55, correlatedSource: n/a, host:localAddress - remote:remoteAddress] " +
                "INBOUND: arg1, arg2";
        Assert.assertEquals(returnVal, expected);
    }

}
