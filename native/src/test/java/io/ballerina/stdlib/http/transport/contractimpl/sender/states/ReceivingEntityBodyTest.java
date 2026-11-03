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

package io.ballerina.stdlib.http.transport.contractimpl.sender.states;

import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.HttpClientChannelInitializer;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.TargetChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.buffer.Unpooled;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.CharsetUtil;
import org.testng.annotations.Test;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;

/**
 * Verifies how {@link ReceivingEntityBody} ends an inbound response.
 */
public class ReceivingEntityBodyTest {

    @Test(description = "A failure to return the connection to the pool must still end the response")
    public void testResponseEndsWhenReturningTheConnectionFails() throws Exception {
        EmbeddedChannel channel = new EmbeddedChannel();
        TargetChannel targetChannel = mock(TargetChannel.class);
        when(targetChannel.getChannel()).thenReturn(channel);
        ConnectionManager connectionManager = mock(ConnectionManager.class);
        doThrow(new IllegalStateException("Couldn't return channel to pool"))
                .when(connectionManager).returnChannel(targetChannel);
        HttpCarbonRequest request =
                new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/"));
        request.setHttpVersion("1.1");

        TargetHandler targetHandler = mock(TargetHandler.class);
        when(targetHandler.getHttpClientChannelInitializer()).thenReturn(mock(HttpClientChannelInitializer.class));
        when(targetHandler.getTargetChannel()).thenReturn(targetChannel);
        when(targetHandler.getConnectionManager()).thenReturn(connectionManager);
        when(targetHandler.getKeepAliveConfig()).thenReturn(KeepAliveConfig.AUTO);
        when(targetHandler.getOutboundRequestMsg()).thenReturn(request);

        HttpCarbonResponse response =
                new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
        ReceivingEntityBody state = new ReceivingEntityBody(new SenderReqRespStateManager(channel, 0), targetHandler);
        try {
            expectThrows(IllegalStateException.class, () -> state.readInboundResponseEntityBody(
                    null, new DefaultLastHttpContent(Unpooled.copiedBuffer("body", CharsetUtil.UTF_8)), response));

            assertTrue(response.isLastHttpContentArrived(), "The response was not ended");
            HttpContent lastContent = response.getHttpContent();
            assertEquals(lastContent.content().toString(CharsetUtil.UTF_8), "body");
            lastContent.release();
        } finally {
            channel.finishAndReleaseAll();
        }
    }
}
