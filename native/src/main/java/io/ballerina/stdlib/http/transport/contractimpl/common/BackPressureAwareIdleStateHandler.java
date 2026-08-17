/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.common;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.handler.timeout.IdleStateHandler;
import io.netty.util.Attribute;
import io.netty.util.AttributeKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.ticksInNanos;

/**
 * An {@link IdleStateHandler} which does not treat inbound application back-pressure as an idle connection.
 *
 * <p>Inbound entity bodies are pulled off the socket on demand. Once the transport has queued up a threshold
 * amount of content for the application, it stops asking the socket for more data until the application
 * consumes what is already queued. While the reads are throttled like that, the channel looks completely idle
 * to a plain {@link IdleStateHandler}, even though the peer is still actively sending the message and would
 * hand over more data the moment we asked for it. Acting on that apparent idleness tears down the connection
 * in the middle of a large streamed message, which surfaces to the application as a prematurely closed
 * stream.
 *
 * <p>This handler therefore fires an {@link IdleStateEvent} only when the transport is genuinely waiting on
 * the peer: reads must not be suspended, and a full idle period must have elapsed since the reads were last
 * resumed. The read suspension is signalled by the inbound content listener via
 * {@link #suspendInboundReads(Channel)} and {@link #resumeInboundReads(Channel)}.
 */
public class BackPressureAwareIdleStateHandler extends IdleStateHandler {

    private static final Logger LOG = LoggerFactory.getLogger(BackPressureAwareIdleStateHandler.class);

    private static final AttributeKey<InboundReadState> INBOUND_READ_STATE =
            AttributeKey.valueOf("inboundReadState");

    private final long idleTimeoutNanos;

    public BackPressureAwareIdleStateHandler(long idleTimeout, TimeUnit unit) {
        super(0, 0, idleTimeout, unit);
        this.idleTimeoutNanos = unit.toNanos(idleTimeout);
    }

    /**
     * Records that the transport has deliberately stopped pulling data off the socket because the application
     * has not consumed what is already queued. The idle timeout does not run while a channel is in this state.
     *
     * @param channel the channel whose inbound reads are suspended
     */
    public static void suspendInboundReads(Channel channel) {
        getOrCreateState(channel).suspend();
    }

    /**
     * Records that the transport has started pulling data off the socket again. This also restarts the idle
     * countdown, so that the peer is given a full idle period to respond after every resumption.
     *
     * @param channel the channel whose inbound reads have resumed
     */
    public static void resumeInboundReads(Channel channel) {
        getOrCreateState(channel).resume();
    }

    private static InboundReadState getOrCreateState(Channel channel) {
        Attribute<InboundReadState> attribute = channel.attr(INBOUND_READ_STATE);
        InboundReadState state = attribute.get();
        if (state == null) {
            InboundReadState newState = new InboundReadState();
            InboundReadState existingState = attribute.setIfAbsent(newState);
            state = existingState != null ? existingState : newState;
        }
        return state;
    }

    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        // A pooled channel can be handed over with a stale suspension from the previous message, so every
        // message this handler is installed for starts with a clean idle countdown.
        resumeInboundReads(ctx.channel());
        super.handlerAdded(ctx);
    }

    @Override
    protected void channelIdle(ChannelHandlerContext ctx, IdleStateEvent evt) throws Exception {
        InboundReadState state = ctx.channel().attr(INBOUND_READ_STATE).get();
        if (state != null) {
            if (state.isReadSuspended()) {
                LOG.debug("Idle timeout not triggered on {}, inbound reads are suspended by application "
                        + "back-pressure", ctx.channel().id());
                return;
            }
            if (ticksInNanos() - state.getLastResumeTimeNanos() < idleTimeoutNanos) {
                LOG.debug("Idle timeout not triggered on {}, inbound reads resumed less than an idle period ago",
                        ctx.channel().id());
                return;
            }
        }
        super.channelIdle(ctx, evt);
    }

    /**
     * Per channel view of whether the transport is currently asking the socket for inbound data.
     */
    private static final class InboundReadState {

        private volatile boolean readSuspended;
        private volatile long lastResumeTimeNanos = ticksInNanos();

        void suspend() {
            readSuspended = true;
        }

        void resume() {
            lastResumeTimeNanos = ticksInNanos();
            readSuspended = false;
        }

        boolean isReadSuspended() {
            return readSuspended;
        }

        long getLastResumeTimeNanos() {
            return lastResumeTimeNanos;
        }
    }
}
