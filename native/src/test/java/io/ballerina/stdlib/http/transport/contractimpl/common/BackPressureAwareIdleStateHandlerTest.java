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

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.timeout.IdleStateEvent;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertTrue;

/**
 * Verifies that {@link BackPressureAwareIdleStateHandler#inboundReadsResumed} is guarded by caller identity:
 * on a pooled or keep-alive channel, a call left over from a message that has already completed must not
 * resurrect a stall clock that, since then, has come to belong to a different, still in-flight message.
 */
public class BackPressureAwareIdleStateHandlerTest {

    private static final long IDLE_TIMEOUT_MILLIS = 300;
    // Short relative to IDLE_TIMEOUT_MILLIS so the stall is checked on its own precise schedule rather than
    // waiting on Netty's coarser once-per-idle-timeout cadence, giving predictable, well separated timings:
    // a stall recorded at IDLE_TIMEOUT_MILLIS is reclaimed ~STALL_MILLIS later if never restarted, or not
    // until a further IDLE_TIMEOUT_MILLIS + STALL_MILLIS after that if it is.
    private static final double MAX_STALL_SECONDS = 0.15;
    private static final long STALL_MILLIS = (long) (MAX_STALL_SECONDS * 1000);
    private static final long POLL_STEP_MILLIS = 25;
    // Generous margin over IDLE_TIMEOUT_MILLIS/STALL_MILLIS so ordinary test/JVM scheduling overhead cannot
    // push either check past the boundary it is meant to land clearly on the near or far side of.
    private static final long MARGIN_MILLIS = 60;

    @AfterMethod
    public void resetStallLimit() {
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
    }

    @Test(description = "A resumed() call whose owner no longer matches the channel's current owner - state "
            + "left behind by a message superseded by a new one on a reused channel - must not clear a stall "
            + "the current owner is relying on to still be excused")
    public void testStaleResumedFromPreviousOwnerDoesNotClearCurrentOwnersStall() throws Exception {
        Util.setMaxBackPressureStallTime(MAX_STALL_SECONDS);
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            Object staleOwner = new Object();
            Object currentOwner = new Object();

            // currentOwner is permanently suspended, so the first idle check excuses it and starts its stall
            // clock instead of firing straight away.
            BackPressureAwareIdleStateHandler.trackInboundReads(channel, currentOwner, () -> true);
            pollFor(channel, IDLE_TIMEOUT_MILLIS + MARGIN_MILLIS);
            assertTrue(recorder.events.isEmpty(), "Idle event fired before the stall allowance even began");

            // A stale call from a message that no longer owns this channel's tracking state - it must be a
            // no-op rather than clearing currentOwner's stall clock.
            BackPressureAwareIdleStateHandler.inboundReadsResumed(channel, staleOwner);

            // Past when the stall clock started above would exceed its allowance, but well short of when a
            // (wrongly) restarted one, or Netty's own next natural recheck, would land.
            pollFor(channel, STALL_MILLIS + MARGIN_MILLIS);

            assertTrue(!recorder.events.isEmpty(),
                       "Stall was not reclaimed - the stale resumed() call incorrectly cleared its clock");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "A resumed() call from the owner that is actually current must restart the stall "
            + "clock, giving a still-suspended stream a fresh allowance rather than letting the original one "
            + "run out on schedule")
    public void testResumedFromCurrentOwnerRestartsTheStallClock() throws Exception {
        Util.setMaxBackPressureStallTime(MAX_STALL_SECONDS);
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            Object currentOwner = new Object();

            BackPressureAwareIdleStateHandler.trackInboundReads(channel, currentOwner, () -> true);
            pollFor(channel, IDLE_TIMEOUT_MILLIS + MARGIN_MILLIS);
            assertTrue(recorder.events.isEmpty(), "Idle event fired before the stall allowance even began");

            // The actual current owner reporting progress - this must restart the allowance.
            BackPressureAwareIdleStateHandler.inboundReadsResumed(channel, currentOwner);

            // Past when the original stall clock would have exceeded its allowance if left alone, but well
            // short of when Netty's own next natural recheck - and so a freshly restarted clock - would land.
            pollFor(channel, STALL_MILLIS + MARGIN_MILLIS);

            assertTrue(recorder.events.isEmpty(),
                       "Idle event fired even though the current owner's progress should have restarted the "
                               + "stall allowance");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    private void pollFor(EmbeddedChannel channel, long totalMillis) throws InterruptedException {
        long elapsed = 0;
        while (elapsed < totalMillis) {
            long step = Math.min(POLL_STEP_MILLIS, totalMillis - elapsed);
            Thread.sleep(step);
            elapsed += step;
            channel.runScheduledPendingTasks();
        }
    }

    private static final class RecordingHandler extends ChannelInboundHandlerAdapter {

        private final List<IdleStateEvent> events = new CopyOnWriteArrayList<>();

        @Override
        public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
            if (evt instanceof IdleStateEvent) {
                events.add((IdleStateEvent) evt);
            }
        }
    }
}
