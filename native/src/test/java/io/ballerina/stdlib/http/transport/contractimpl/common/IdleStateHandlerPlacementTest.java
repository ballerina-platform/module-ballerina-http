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

package io.ballerina.stdlib.http.transport.contractimpl.common;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contractimpl.sender.ResponseEntityBodySizeValidator;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import org.testng.annotations.Test;

import java.util.List;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * Verifies where {@link Util#addIdleStateHandler} places the idle state handler, which decides whether it sees the
 * reads of a body an entity body size validator is holding back.
 */
public class IdleStateHandlerPlacementTest {

    private static final String CONSUMER = "consumer";

    @Test(description = "The idle state handler goes in front of an engaged entity body size validator")
    public void testPlacedBeforeEntityBodySizeValidator() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER,
                                   new ResponseEntityBodySizeValidator(1024));
        channel.pipeline().addLast(CONSUMER, new ChannelInboundHandlerAdapter());

        Util.addIdleStateHandler(channel.pipeline(), CONSUMER, idleStateHandler());

        assertEquals(handlerNames(channel), List.of(Constants.IDLE_STATE_HANDLER,
                                                    Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER, CONSUMER));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Without a validator the idle state handler goes directly in front of the consumer")
    public void testPlacedBeforeConsumerWithoutValidator() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast("other", new ChannelInboundHandlerAdapter());
        channel.pipeline().addLast(CONSUMER, new ChannelInboundHandlerAdapter());

        Util.addIdleStateHandler(channel.pipeline(), CONSUMER, idleStateHandler());

        assertEquals(handlerNames(channel), List.of("other", Constants.IDLE_STATE_HANDLER, CONSUMER));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Without the consumer in the pipeline the idle state handler is added last")
    public void testAddedLastWithoutConsumer() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast("other", new ChannelInboundHandlerAdapter());

        Util.addIdleStateHandler(channel.pipeline(), CONSUMER, idleStateHandler());

        assertEquals(handlerNames(channel), List.of("other", Constants.IDLE_STATE_HANDLER));
        channel.finishAndReleaseAll();
    }

    private static BackPressureAwareIdleStateHandler idleStateHandler() {
        return new BackPressureAwareIdleStateHandler(60, TimeUnit.SECONDS);
    }

    private static List<String> handlerNames(EmbeddedChannel channel) {
        return channel.pipeline().names().stream().filter(name -> !name.startsWith("DefaultChannelPipeline$"))
                .toList();
    }
}
