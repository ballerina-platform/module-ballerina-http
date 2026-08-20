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

import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.BooleanSupplier;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isWithinBackPressureStallLimit;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.remainingBackPressureStallNanos;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.ticksInNanos;

/**
 * An {@link IdleStateHandler} which does not treat inbound application back-pressure as an idle connection:
 * a slow consumer suspending reads looks identical to an unresponsive peer to a plain {@link IdleStateHandler},
 * which would otherwise tear down the connection mid-transfer. Fires an {@link IdleStateEvent} only once reads
 * have been suspended, or genuinely idle, for a full period, and only excuses that for up to
 * {@code maxBackPressureStallTime} before timing out anyway.
 */
public class BackPressureAwareIdleStateHandler extends IdleStateHandler {

    private static final Logger LOG = LoggerFactory.getLogger(BackPressureAwareIdleStateHandler.class);
    private static final long MIN_RECHECK_NANOS = TimeUnit.MILLISECONDS.toNanos(1);

    private static final AttributeKey<InboundReadState> INBOUND_READ_STATE =
            AttributeKey.valueOf(BackPressureAwareIdleStateHandler.class, "inboundReadState");

    private final long idleTimeoutNanos;

    public BackPressureAwareIdleStateHandler(long idleTimeout, TimeUnit unit) {
        super(0, 0, idleTimeout, unit);
        this.idleTimeoutNanos = unit.toNanos(idleTimeout);
    }

    // readSuspended is polled when a timeout is about to be raised, rather than cached, so it cannot go stale.
    public static void trackInboundReads(Channel channel, BooleanSupplier readSuspended) {
        getOrCreateState(channel).track(readSuspended);
    }

    public static void untrackInboundReads(Channel channel) {
        getOrCreateState(channel).reset();
    }

    // Restarts the idle countdown and clears any accumulated stall allowance.
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
        // Runs before the superclass starts its own timers: a pooled channel can carry state from the
        // previous message, so every message this handler is installed for starts with a clean countdown.
        getOrCreateState(ctx.channel()).reset();
        super.handlerAdded(ctx);
    }

    @Override
    protected void channelIdle(ChannelHandlerContext ctx, IdleStateEvent evt) throws Exception {
        InboundReadState state = ctx.channel().attr(INBOUND_READ_STATE).get();
        if (state != null && isCausedByBackPressure(state)) {
            long stallStart = state.recordStall();
            if (isWithinBackPressureStallLimit(stallStart)) {
                scheduleStallLimitRecheck(ctx, evt, state, stallStart);
                LOG.debug("Idle timeout not triggered on {}, inbound reads are held up by application "
                                  + "back-pressure", ctx.channel().id());
                return;
            }
            LOG.debug("Idle timeout triggered on {}, inbound reads have been held up by application "
                              + "back-pressure past the permitted stall time without any progress",
                      ctx.channel().id());
        }
        super.channelIdle(ctx, evt);
    }

    // Netty only rechecks once per idleTimeoutNanos, too coarse when maxBackPressureStallTime is shorter, so
    // this schedules an extra, cancellable recheck timed to the remaining allowance.
    private void scheduleStallLimitRecheck(ChannelHandlerContext ctx, IdleStateEvent evt, InboundReadState state,
                                           long stallStart) {
        state.cancelStallLimitRecheck();
        long remaining = remainingBackPressureStallNanos(stallStart);
        if (remaining < 0 || remaining >= idleTimeoutNanos) {
            return;
        }
        long delay = Math.max(remaining, MIN_RECHECK_NANOS);
        state.setStallLimitRecheckTask(ctx.channel().eventLoop().schedule(() -> {
            if (!ctx.isRemoved()) {
                try {
                    channelIdle(ctx, evt);
                } catch (Exception e) {
                    LOG.debug("Error while re-checking the back-pressure stall limit on {}", ctx.channel().id(), e);
                }
            }
        }, delay, TimeUnit.NANOSECONDS));
    }

    private boolean isCausedByBackPressure(InboundReadState state) {
        return state.isReadSuspended() || ticksInNanos() - state.getLastResumeTimeNanos() < idleTimeoutNanos;
    }

    // Per channel view of whether the transport is currently asking the socket for inbound data.
    private static final class InboundReadState {

        private volatile BooleanSupplier readSuspended;
        private volatile long lastResumeTimeNanos = ticksInNanos();
        private final AtomicLong stallStartTimeNanos = new AtomicLong();
        private final AtomicReference<ScheduledFuture<?>> stallLimitRecheckTask = new AtomicReference<>();

        void track(BooleanSupplier suspensionCheck) {
            readSuspended = suspensionCheck;
        }

        void resumed() {
            lastResumeTimeNanos = ticksInNanos();
            stallStartTimeNanos.set(0);
            cancelStallLimitRecheck();
        }

        void reset() {
            readSuspended = null;
            resumed();
        }

        void setStallLimitRecheckTask(ScheduledFuture<?> task) {
            ScheduledFuture<?> previous = stallLimitRecheckTask.getAndSet(task);
            if (previous != null) {
                previous.cancel(false);
            }
        }

        void cancelStallLimitRecheck() {
            ScheduledFuture<?> task = stallLimitRecheckTask.getAndSet(null);
            if (task != null) {
                task.cancel(false);
            }
        }

        boolean isReadSuspended() {
            BooleanSupplier suspensionCheck = readSuspended;
            return suspensionCheck != null && suspensionCheck.getAsBoolean();
        }

        long getLastResumeTimeNanos() {
            return lastResumeTimeNanos;
        }

        // Marks the channel as stalled if it was not already, and returns when the stall began; compareAndSet
        // keeps the original start time so the allowance covers the whole stall, not just the latest check.
        long recordStall() {
            long now = ticksInNanos();
            return stallStartTimeNanos.compareAndSet(0, now) ? now : stallStartTimeNanos.get();
        }
    }
}
