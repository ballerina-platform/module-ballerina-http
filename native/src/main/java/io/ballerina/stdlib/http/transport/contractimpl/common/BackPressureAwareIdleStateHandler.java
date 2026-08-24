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
    // owner identifies the caller (e.g. the DefaultListener for the message currently being read) so that a
    // resumed() call arriving late - after a reused channel has moved on to tracking a different message - can
    // be told apart from one that still applies and ignored instead of resetting state it no longer owns.
    public static void trackInboundReads(Channel channel, Object owner, BooleanSupplier readSuspended) {
        getOrCreateState(channel).track(owner, readSuspended);
    }

    // Ignored, like inboundReadsResumed, if owner is no longer the one currently being tracked: untracking is
    // the more destructive of the two, since clearing readSuspended for a message that has since started being
    // tracked in its place would leave that message's back-pressure invisible to the idle timeout.
    public static void untrackInboundReads(Channel channel, Object owner) {
        getOrCreateState(channel).reset(owner);
    }

    // Restarts the idle countdown and clears any accumulated stall allowance. Ignored if owner is no longer
    // the one currently being tracked on this channel.
    public static void inboundReadsResumed(Channel channel, Object owner) {
        getOrCreateState(channel).resumed(owner);
    }

    private static InboundReadState getOrCreateState(Channel channel) {
        Attribute<InboundReadState> attribute = channel.attr(INBOUND_READ_STATE);
        InboundReadState state = attribute.get();
        if (state != null) {
            return state;
        }
        InboundReadState newState = new InboundReadState();
        InboundReadState existingState = attribute.setIfAbsent(newState);
        state = existingState != null ? existingState : newState;
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
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        // Recorded in the same method the superclass uses to update its own idle baseline for this read, so
        // the two advance together. Deriving this from DefaultListener's later, separate notification instead
        // would trail Netty's own baseline by however long that read takes to reach it, which could make a
        // connection that is now genuinely idle still look recently active when the idle check runs.
        getOrCreateState(ctx.channel()).recordRawRead();
        super.channelReadComplete(ctx);
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
            if (ctx.isRemoved()) {
                return;
            }
            try {
                channelIdle(ctx, evt);
            } catch (Exception e) {
                LOG.debug("Error while re-checking the back-pressure stall limit on {}", ctx.channel().id(), e);
            }
        }, delay, TimeUnit.NANOSECONDS));
    }

    private boolean isCausedByBackPressure(InboundReadState state) {
        if (state.isReadSuspended()) {
            return true;
        }
        // Only while a message is actually being tracked. On a connection no application back-pressure has
        // been applied to, a channelReadComplete that carried no decoded message - a partial chunk, a partial
        // TLS record, a read that returned nothing - must not excuse a timeout that is otherwise due.
        return state.isTracking() && ticksInNanos() - state.getLastProgressTimeNanos() < idleTimeoutNanos;
    }

    // Per channel view of whether the transport is currently asking the socket for inbound data.
    private static final class InboundReadState {

        private volatile Object owner;
        private volatile BooleanSupplier readSuspended;
        // Updated only from channelReadComplete, in step with the superclass's own idle baseline - see there.
        private volatile long lastRawReadTimeNanos = ticksInNanos();
        // When the transport last started, or went back to, asking the peer for data. Kept alongside the raw
        // read time because reads resuming after a long suspension leave that one stale by definition: the
        // peer has to be given a full period to answer the read that has only just been issued to it.
        private volatile long lastResumeTimeNanos = ticksInNanos();
        private final AtomicLong stallStartTimeNanos = new AtomicLong();
        private final AtomicReference<ScheduledFuture<?>> stallLimitRecheckTask = new AtomicReference<>();

        void track(Object newOwner, BooleanSupplier suspensionCheck) {
            owner = newOwner;
            readSuspended = suspensionCheck;
            // A newly tracked message starts on a clean stall clock. Whatever the previous one left behind on
            // this channel - it may have ended without ever untracking - is not this message's to answer for.
            recordProgress();
        }

        boolean isTracking() {
            return owner != null;
        }

        void recordRawRead() {
            lastRawReadTimeNanos = ticksInNanos();
        }

        // Ignored if callerOwner is not the owner currently being tracked: a message's own progress must not
        // resurrect stall-clock state that, on a reused channel, already belongs to whatever message has since
        // started being tracked in its place.
        void resumed(Object callerOwner) {
            if (callerOwner != owner) {
                return;
            }
            recordProgress();
        }

        // Guarded the same way resumed() is - see untrackInboundReads.
        void reset(Object callerOwner) {
            if (callerOwner != owner) {
                return;
            }
            reset();
        }

        void reset() {
            owner = null;
            readSuspended = null;
            // A freshly tracked message starts out counted as recently active, the same way a freshly added
            // handler does, rather than inheriting a possibly stale timestamp from whatever this channel was
            // last used for.
            lastRawReadTimeNanos = ticksInNanos();
            recordProgress();
        }

        // Restarts the idle countdown and clears any accumulated stall allowance.
        private void recordProgress() {
            lastResumeTimeNanos = ticksInNanos();
            stallStartTimeNanos.set(0);
            cancelStallLimitRecheck();
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

        // The later of the two, so that neither a peer that has just sent something nor a read that has just
        // been reissued to it is mistaken for silence.
        long getLastProgressTimeNanos() {
            return Math.max(lastRawReadTimeNanos, lastResumeTimeNanos);
        }

        // Marks the channel as stalled if it was not already, and returns when the stall began; compareAndSet
        // keeps the original start time so the allowance covers the whole stall, not just the latest check.
        long recordStall() {
            long now = ticksInNanos();
            return stallStartTimeNanos.compareAndSet(0, now) ? now : stallStartTimeNanos.get();
        }
    }
}
