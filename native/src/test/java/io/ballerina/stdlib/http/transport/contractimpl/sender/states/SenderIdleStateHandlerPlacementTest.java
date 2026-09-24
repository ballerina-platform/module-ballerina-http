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
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.ResponseEntityBodySizeValidator;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import org.testng.annotations.Test;

import java.util.List;

import static org.testng.Assert.assertEquals;

/**
 * Verifies that the client states arming the idle timeout place it in front of the response entity body size
 * validator, so that the timer sees each piece of a body the validator is still holding back.
 */
public class SenderIdleStateHandlerPlacementTest {

    private static final int SOCKET_TIMEOUT_MILLIS = 60000;

    @Test(description = "Sending headers arms the idle timeout in front of the entity body size validator")
    public void testSendingHeadersPlacesIdleStateHandlerBeforeValidator() {
        EmbeddedChannel channel = newClientChannel();

        new SendingHeaders(new SenderReqRespStateManager(channel, SOCKET_TIMEOUT_MILLIS), null,
                           Constants.HTTP_1_1_VERSION, ChunkConfig.AUTO, null);

        assertIdleStateHandlerBeforeValidator(channel);
    }

    @Test(description = "Waiting for 100-continue re-arms the idle timeout in front of the entity body size validator")
    public void testSending100ContinuePlacesIdleStateHandlerBeforeValidator() {
        EmbeddedChannel channel = newClientChannel();

        new Sending100Continue(new SenderReqRespStateManager(channel, SOCKET_TIMEOUT_MILLIS), null);

        assertIdleStateHandlerBeforeValidator(channel);
    }

    private static EmbeddedChannel newClientChannel() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER,
                                   new ResponseEntityBodySizeValidator(1024));
        channel.pipeline().addLast(Constants.TARGET_HANDLER, new ChannelInboundHandlerAdapter());
        return channel;
    }

    private static void assertIdleStateHandlerBeforeValidator(EmbeddedChannel channel) {
        List<String> names = channel.pipeline().names().stream()
                .filter(name -> !name.startsWith("DefaultChannelPipeline$")).toList();
        assertEquals(names, List.of(Constants.IDLE_STATE_HANDLER, Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER,
                                    Constants.TARGET_HANDLER));
        channel.finishAndReleaseAll();
    }
}
