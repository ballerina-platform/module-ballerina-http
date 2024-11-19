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

package io.ballerina.stdlib.http.transport.contractimpl.common;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.Http2FrameLogger;
import org.junit.Assert;
import org.testng.annotations.Test;

import static io.netty.handler.logging.LogLevel.TRACE;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module FrameLogger class functions.
 */
public class FrameLoggerTest {

    @Test
    public void testFrameLoggerLog() {
        FrameLogger frameLogger = new FrameLogger(TRACE, Constants.TRACE_LOG_DOWNSTREAM);
        Assert.assertNotNull(frameLogger);
        Http2FrameLogger.Direction direction = mock(Http2FrameLogger.Direction.class);
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        ByteBuf data = Unpooled.buffer();
        when(direction.name()).thenReturn("testDirection");
        data.clear();
        frameLogger.logData(direction, ctx, 5, data, 10, true);
        data.writeBytes(new byte[16]);
        frameLogger.logData(direction, ctx, 5, data, 10, true);
        data.clear();
        data.writeBytes(new byte[10]);
        frameLogger.logData(direction, ctx, 5, data, 10, true);
    }

}
