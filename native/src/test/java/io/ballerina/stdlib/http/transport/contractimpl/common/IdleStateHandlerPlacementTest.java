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
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.util.List;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * Verifies that {@link Util#addIdleStateHandler} places the idle state handler directly after the HTTP codec, so that
 * handlers holding reads back, such as the entity body size validators, cannot hide a message's progress from it.
 */
public class IdleStateHandlerPlacementTest {

    private static final String CONSUMER = "consumer";

    @DataProvider
    public Object[][] codecNames() {
        return new Object[][]{{Constants.HTTP_CLIENT_CODEC}, {Constants.HTTP_DECODER}, {Constants.HTTP_SERVER_CODEC}};
    }

    @Test(dataProvider = "codecNames", description = "The idle state handler goes directly after the HTTP codec")
    public void testPlacedAfterCodec(String codecName) {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast(codecName, new ChannelInboundHandlerAdapter());
        channel.pipeline().addLast(Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER,
                                   new ResponseEntityBodySizeValidator(1024));
        channel.pipeline().addLast(CONSUMER, new ChannelInboundHandlerAdapter());

        Util.addIdleStateHandler(channel.pipeline(), CONSUMER, idleStateHandler());

        assertEquals(handlerNames(channel), List.of(codecName, Constants.IDLE_STATE_HANDLER,
                                                    Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER, CONSUMER));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Without an HTTP codec the idle state handler goes directly in front of the consumer")
    public void testPlacedBeforeConsumerWithoutCodec() {
        EmbeddedChannel channel = new EmbeddedChannel();
        channel.pipeline().addLast("other", new ChannelInboundHandlerAdapter());
        channel.pipeline().addLast(CONSUMER, new ChannelInboundHandlerAdapter());

        Util.addIdleStateHandler(channel.pipeline(), CONSUMER, idleStateHandler());

        assertEquals(handlerNames(channel), List.of("other", Constants.IDLE_STATE_HANDLER, CONSUMER));
        channel.finishAndReleaseAll();
    }

    @Test(description = "Without an HTTP codec or the consumer the idle state handler is added last")
    public void testAddedLastWithoutCodecOrConsumer() {
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
