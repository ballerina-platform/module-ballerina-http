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
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.BooleanSupplier;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isWithinBackPressureStallLimit;
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
 * resumed. The inbound content listener supplies the suspension state through
 * {@link #trackInboundReads(Channel, BooleanSupplier)} and reports progress through
 * {@link #inboundReadsResumed(Channel)}.
 *
 * <p>Two consequences are worth knowing about. Firstly, because the peer is given a fresh period after every
 * resumption, a timeout can take up to twice the configured value to fire once a message body has started to
 * arrive. Secondly, the reprieve is not unlimited: an application that consumes nothing at all for the span
 * permitted by the {@code maxBackPressureStallTime} configurable is treated as hung and the connection is
 * timed out, so a stuck listener cannot pin a connection forever.
 */
public class BackPressureAwareIdleStateHandler extends IdleStateHandler {

    private static final Logger LOG = LoggerFactory.getLogger(BackPressureAwareIdleStateHandler.class);

    private static final AttributeKey<InboundReadState> INBOUND_READ_STATE =
            AttributeKey.valueOf(BackPressureAwareIdleStateHandler.class, "inboundReadState");

    private final long idleTimeoutNanos;

    public BackPressureAwareIdleStateHandler(long idleTimeout, TimeUnit unit) {
        super(0, 0, idleTimeout, unit);
        this.idleTimeoutNanos = unit.toNanos(idleTimeout);
    }

    /**
     * Registers where this channel's inbound read suspension can be read from. The check is evaluated when a
     * timeout is about to be raised rather than cached as a flag, so it cannot go stale against the queue it
     * describes.
     *
     * @param channel      the channel whose inbound reads are throttled on demand
     * @param readSuspended tells whether the transport has currently stopped pulling data off the socket
     */
    public static void trackInboundReads(Channel channel, BooleanSupplier readSuspended) {
        getOrCreateState(channel).track(readSuspended);
    }

    /**
     * Stops consulting a previously registered check, because the message it belonged to is over or its
     * listener has been detached. The channel is treated as never suspended from here on.
     *
     * @param channel the channel to stop tracking
     */
    public static void untrackInboundReads(Channel channel) {
        getOrCreateState(channel).reset();
    }

    /**
     * Records that the application has made progress, either by draining queued content or by the transport
     * asking the socket for more. This restarts the idle countdown, so that the peer is given a full idle
     * period to respond after every resumption, and clears any accumulated reprieve.
     *
     * @param channel the channel whose inbound reads have progressed
     */
    public static void inboundReadsResumed(Channel channel) {
        getOrCreateState(channel).resumed();
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
        // A pooled channel can be handed over carrying the state of the previous message, so every message
        // this handler is installed for starts with a clean idle countdown. This deliberately runs before
        // the superclass initialises its own timers: the resume time must not be later than the baseline
        // IdleStateHandler measures from, otherwise the very first timeout would be swallowed.
        getOrCreateState(ctx.channel()).reset();
        super.handlerAdded(ctx);
    }

    @Override
    protected void channelIdle(ChannelHandlerContext ctx, IdleStateEvent evt) throws Exception {
        InboundReadState state = ctx.channel().attr(INBOUND_READ_STATE).get();
        if (state != null && isCausedByBackPressure(state)) {
            if (isWithinBackPressureStallLimit(state.recordStall())) {
                LOG.debug("Idle timeout not triggered on {}, inbound reads are held up by application "
                                  + "back-pressure", ctx.channel().id());
                return;
            }
            // The stall start is deliberately left standing: until the application makes some progress, every
            // further period should time out too rather than earn a fresh allowance.
            LOG.debug("Idle timeout triggered on {}, inbound reads have been held up by application "
                              + "back-pressure past the permitted stall time without any progress",
                      ctx.channel().id());
        }
        super.channelIdle(ctx, evt);
    }

    private boolean isCausedByBackPressure(InboundReadState state) {
        return state.isReadSuspended() || ticksInNanos() - state.getLastResumeTimeNanos() < idleTimeoutNanos;
    }

    /**
     * Per channel view of whether the transport is currently asking the socket for inbound data.
     */
    private static final class InboundReadState {

        private volatile BooleanSupplier readSuspended;
        private volatile long lastResumeTimeNanos = ticksInNanos();
        private final AtomicLong stallStartTimeNanos = new AtomicLong();

        void track(BooleanSupplier suspensionCheck) {
            readSuspended = suspensionCheck;
        }

        void resumed() {
            lastResumeTimeNanos = ticksInNanos();
            stallStartTimeNanos.set(0);
        }

        void reset() {
            readSuspended = null;
            resumed();
        }

        boolean isReadSuspended() {
            BooleanSupplier suspensionCheck = readSuspended;
            return suspensionCheck != null && suspensionCheck.getAsBoolean();
        }

        long getLastResumeTimeNanos() {
            return lastResumeTimeNanos;
        }

        /**
         * Marks the channel as stalled if it was not already, and reports when the stall began.
         *
         * @return the time the current stall started, from {@link Util#ticksInNanos()}
         */
        long recordStall() {
            long now = ticksInNanos();
            // compareAndSet keeps the original start time once a stall is under way, so the allowance covers
            // the whole stall rather than restarting on every check.
            return stallStartTimeNanos.compareAndSet(0, now) ? now : stallStartTimeNanos.get();
        }
    }
}
