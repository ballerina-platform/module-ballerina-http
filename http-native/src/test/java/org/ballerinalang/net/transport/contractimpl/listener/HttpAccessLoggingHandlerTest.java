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

import io.netty.buffer.ByteBuf;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelPromise;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.ballerinalang.net.transport.contract.Constants;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module HttpAccessLoggingHandler class functions.
 */
public class HttpAccessLoggingHandlerTest {

    HttpAccessLoggingHandler httpAccessLoggingHandler;
    ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
    ChannelPromise promise = mock(ChannelPromise.class);
    Throwable cause = new Throwable();
    Object evt = new Object();
    SocketAddress localAddress = mock(SocketAddress.class);
    SocketAddress remoteAddress = mock(SocketAddress.class);

    @BeforeClass
    public void initializeHttpAccessLoggingHandler() {
        httpAccessLoggingHandler = new HttpAccessLoggingHandler("test");
    }

    @Test
    public void testHttpAccessLoggingHandler() {
        Assert.assertNotNull(httpAccessLoggingHandler);
    }

    @Test
    public void testChannelActive() throws Exception {
        SocketAddress socketAddress = mock(SocketAddress.class);
        Channel channel = mock(Channel.class);
        when(ctx.channel()).thenReturn(channel);
        when(channel.remoteAddress()).thenReturn(socketAddress);
        httpAccessLoggingHandler.channelInactive(ctx);
        httpAccessLoggingHandler.channelActive(ctx);
        verify(ctx).fireChannelActive();
    }

    @Test
    public void testChannelActiveWithInetSocketAddress() throws Exception {
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        InetSocketAddress socketAddress = mock(InetSocketAddress.class);
        InetAddress address = mock(InetAddress.class);
        Channel channel = mock(Channel.class);
        when(ctx.channel()).thenReturn(channel);
        when(channel.remoteAddress()).thenReturn(socketAddress);
        when(socketAddress.getAddress()).thenReturn(address);
        when(address.toString()).thenReturn("/test");
        httpAccessLoggingHandler.channelActive(ctx);
        verify(ctx).fireChannelActive();
    }

    @Test
    public void testChannelInactive() throws Exception {
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        httpAccessLoggingHandler.channelInactive(ctx);
        verify(ctx).fireChannelInactive();
    }

    @Test
    public void testChannelRead() throws Exception {
        HttpRequest httpRequest = mock(HttpRequest.class);
        HttpHeaders httpHeaders = mock(HttpHeaders.class);
        when(httpRequest.headers()).thenReturn(httpHeaders);
        when(httpRequest.method()).thenReturn(new HttpMethod("name"));
        when(httpRequest.protocolVersion()).thenReturn(HttpVersion.HTTP_1_1);
        when(httpRequest.uri()).thenReturn("testUri");
        httpAccessLoggingHandler.channelRead(ctx, httpRequest);

        when(httpHeaders.contains(Constants.HTTP_X_FORWARDED_FOR)).thenReturn(true);
        when(httpHeaders.get(Constants.HTTP_X_FORWARDED_FOR)).thenReturn("test");
        when(httpHeaders.contains(HttpHeaderNames.USER_AGENT)).thenReturn(true);
        when(httpHeaders.get(HttpHeaderNames.USER_AGENT)).thenReturn("testUserAgent");
        when(httpHeaders.contains(HttpHeaderNames.REFERER)).thenReturn(true);
        when(httpHeaders.get(HttpHeaderNames.REFERER)).thenReturn("testReferer");
        httpAccessLoggingHandler.channelRead(ctx, httpRequest);

        when(httpHeaders.get(Constants.HTTP_X_FORWARDED_FOR)).thenReturn("test,test1");
        httpAccessLoggingHandler.channelRead(ctx, httpRequest);

        Object msg = new Object();
        httpAccessLoggingHandler.channelRead(ctx, msg);

        verify(ctx, times(3)).fireChannelRead(httpRequest);
        verify(ctx).fireChannelRead(msg);
    }

    @Test
    public void testWriteWithHttpResponse() throws Exception {
        HttpResponse httpResponse = mock(HttpResponse.class);
        HttpHeaders httpHeaders = mock(HttpHeaders.class);
        when(httpResponse.headers()).thenReturn(httpHeaders);
        when(httpResponse.status()).thenReturn(HttpResponseStatus.OK);
        httpAccessLoggingHandler.write(ctx, httpResponse, promise);

        when(httpHeaders.contains(HttpHeaderNames.CONTENT_LENGTH)).thenReturn(true);
        when(httpHeaders.get(HttpHeaderNames.CONTENT_LENGTH)).thenReturn("100");
        httpAccessLoggingHandler.write(ctx, httpResponse, promise);

        Object msg = new Object();
        httpAccessLoggingHandler.write(ctx, msg, promise);

        verify(ctx, times(2)).write(httpResponse, promise);
        verify(ctx).write(msg, promise);
    }

    @Test
    public void testWriteWithHttpContent() throws Exception {
        LastHttpContent httpContent = mock(LastHttpContent.class);
        ByteBuf content = mock(ByteBuf.class);
        when(content.readableBytes()).thenReturn(10);
        when(httpContent.content()).thenReturn(content);
        httpAccessLoggingHandler.write(ctx, httpContent, promise);

        HttpContent msg = mock(HttpContent.class);
        when(msg.content()).thenReturn(content);
        httpAccessLoggingHandler.write(ctx, msg, promise);

        verify(ctx).write(httpContent, promise);
        verify(ctx).write(msg, promise);
    }

    @Test
    public void testWrite() throws Exception {
        Object msg = new Object();
        httpAccessLoggingHandler.write(ctx, msg, promise);
        verify(ctx).write(msg, promise);
    }

    @Test
    public void testChannelRegistered() throws Exception {
        httpAccessLoggingHandler.channelRegistered(ctx);
        verify(ctx).fireChannelRegistered();
    }

    @Test
    public void testChannelUnregistered() throws Exception {
        httpAccessLoggingHandler.channelUnregistered(ctx);
        verify(ctx).fireChannelUnregistered();
    }

    @Test
    public void testExceptionCaught() throws Exception {
        httpAccessLoggingHandler.exceptionCaught(ctx, cause);
        verify(ctx).fireExceptionCaught(cause);
    }

    @Test
    public void testUserEventTriggered() throws Exception {
        httpAccessLoggingHandler.userEventTriggered(ctx, evt);
        verify(ctx).fireUserEventTriggered(evt);
    }

    @Test
    public void testBind() throws Exception {
        httpAccessLoggingHandler.bind(ctx, localAddress, promise);
        verify(ctx).bind(localAddress, promise);
    }

    @Test
    public void testConnect() throws Exception {
        httpAccessLoggingHandler.connect(ctx, remoteAddress, localAddress, promise);
        verify(ctx).connect(remoteAddress, localAddress, promise);
    }

    @Test
    public void testDisconnect() throws Exception {
        httpAccessLoggingHandler.disconnect(ctx, promise);
        verify(ctx).disconnect(promise);
    }

    @Test
    public void testClose() throws Exception {
        httpAccessLoggingHandler.close(ctx, promise);
        verify(ctx).close(promise);
    }

    @Test
    public void testDeregister() throws Exception {
        httpAccessLoggingHandler.deregister(ctx, promise);
        verify(ctx).deregister(promise);
    }

    @Test
    public void testChannelReadComplete() throws Exception {
        httpAccessLoggingHandler.channelReadComplete(ctx);
        verify(ctx).fireChannelReadComplete();
    }

    @Test
    public void testChannelWritabilityChanged() throws Exception {
        httpAccessLoggingHandler.channelWritabilityChanged(ctx);
        verify(ctx).fireChannelWritabilityChanged();
    }

    @Test
    public void testFlush() throws Exception {
        httpAccessLoggingHandler.flush(ctx);
        verify(ctx).flush();
    }

}
