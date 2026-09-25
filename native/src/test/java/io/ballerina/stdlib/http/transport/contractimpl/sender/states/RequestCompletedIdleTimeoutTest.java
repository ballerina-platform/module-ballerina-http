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

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.exceptions.EndpointTimeOutException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpResponseFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.ResponseEntityBodySizeValidator;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.Test;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;

/**
 * Verifies how {@link RequestCompleted} reports an idle timeout, which reaches it both before a response starts and
 * while the response entity body size validator is holding a response back.
 */
public class RequestCompletedIdleTimeoutTest {

    @Test(description = "A timeout while a response is held back is reported as one while reading its body")
    public void testTimeoutWhileResponseIsHeldBack() {
        EmbeddedChannel channel = newClientChannel();
        HttpResponse response = new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
        response.headers().set(HttpHeaderNames.TRANSFER_ENCODING, "chunked");
        channel.writeInbound(response, new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[100])));

        assertTimeoutReportedAs(channel, Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    @Test(description = "A timeout before any response arrives is reported as one before the response started")
    public void testTimeoutBeforeResponse() {
        assertTimeoutReportedAs(newClientChannel(),
                                Constants.IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_INBOUND_RESPONSE);
    }

    private static EmbeddedChannel newClientChannel() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(Constants.IDLE_STATE_HANDLER, new ChannelInboundHandlerAdapter());
        channel.pipeline().addLast(Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER,
                                   new ResponseEntityBodySizeValidator(1024));
        return channel;
    }

    private static void assertTimeoutReportedAs(EmbeddedChannel channel, String expectedMessage) {
        DefaultHttpResponseFuture responseFuture = new DefaultHttpResponseFuture();

        new RequestCompleted(new SenderReqRespStateManager(channel, 60000))
                .handleIdleTimeoutConnectionClosure(null, responseFuture, "channel-id");

        Throwable cause = responseFuture.getStatus().getCause();
        assertTrue(cause instanceof EndpointTimeOutException, "The timeout was not reported as one: " + cause);
        assertEquals(cause.getMessage(), expectedMessage);
        channel.finishAndReleaseAll();
    }
}
