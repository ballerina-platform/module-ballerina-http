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

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelPromise;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.net.SocketAddress;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

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
    public void testChannelRegistered() throws Exception {
        httpAccessLoggingHandler.channelRegistered(ctx);
        verify(ctx, times(1)).fireChannelRegistered();
    }

    @Test
    public void testChannelUnregistered() throws Exception {
        httpAccessLoggingHandler.channelUnregistered(ctx);
        verify(ctx, times(1)).fireChannelUnregistered();
    }

    @Test
    public void testExceptionCaught() throws Exception {
        httpAccessLoggingHandler.exceptionCaught(ctx, cause);
        verify(ctx, times(1)).fireExceptionCaught(cause);
    }

    @Test
    public void testUserEventTriggered() throws Exception {
        httpAccessLoggingHandler.userEventTriggered(ctx, evt);
        verify(ctx, times(1)).fireUserEventTriggered(evt);
    }

    @Test
    public void testBind() throws Exception {
        httpAccessLoggingHandler.bind(ctx, localAddress, promise);
        verify(ctx, times(1)).bind(localAddress, promise);
    }

    @Test
    public void testConnect() throws Exception {
        httpAccessLoggingHandler.connect(ctx, remoteAddress, localAddress, promise);
        verify(ctx, times(1)).connect(remoteAddress, localAddress, promise);
    }

    @Test
    public void testDisconnect() throws Exception {
        httpAccessLoggingHandler.disconnect(ctx, promise);
        verify(ctx, times(1)).disconnect(promise);
    }

    @Test
    public void testClose() throws Exception {
        httpAccessLoggingHandler.close(ctx, promise);
        verify(ctx, times(1)).close(promise);
    }

    @Test
    public void testDeregister() throws Exception {
        httpAccessLoggingHandler.deregister(ctx, promise);
        verify(ctx, times(1)).deregister(promise);
    }

    @Test
    public void testChannelReadComplete() throws Exception {
        httpAccessLoggingHandler.channelReadComplete(ctx);
        verify(ctx, times(1)).fireChannelReadComplete();
    }

    @Test
    public void testChannelWritabilityChanged() throws Exception {
        httpAccessLoggingHandler.channelWritabilityChanged(ctx);
        verify(ctx, times(1)).fireChannelWritabilityChanged();
    }

    @Test
    public void testFlush() throws Exception {
        httpAccessLoggingHandler.flush(ctx);
        verify(ctx, times(1)).flush();
    }

}
