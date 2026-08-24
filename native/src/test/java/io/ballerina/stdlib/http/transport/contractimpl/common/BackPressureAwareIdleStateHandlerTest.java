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
import java.util.concurrent.atomic.AtomicBoolean;

import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies how {@link BackPressureAwareIdleStateHandler} decides that silence on a connection is the
 * application's own back-pressure rather than an unresponsive peer: which progress excuses a timeout, how much
 * of a fresh period the peer gets once reads resume, and that state belonging to one message on a pooled or
 * keep-alive channel is never applied to another that has since been tracked in its place.
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

    @Test(description = "A connection nobody has applied back-pressure to must time out on schedule even when "
            + "a socket read carried no decoded message - a partial chunk or TLS record advances the raw read "
            + "time without being progress the idle timeout is meant to excuse")
    public void testUntrackedChannelIsNotExcusedByAReadThatCarriedNoMessage() throws Exception {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            // No trackInboundReads at all: nothing on this channel has ever suspended reads.
            pollFor(channel, IDLE_TIMEOUT_MILLIS / 2);

            // A read that produced no message for the handlers below this one, so the superclass's own idle
            // baseline - which only advances alongside a channelRead - is deliberately left where it was.
            channel.pipeline().fireChannelReadComplete();

            pollFor(channel, IDLE_TIMEOUT_MILLIS / 2 + MARGIN_MILLIS);

            assertFalse(recorder.events.isEmpty(),
                        "Idle event was deferred on a connection with no application back-pressure at all");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "Once the application drains and reads are reissued, the peer gets a full fresh period "
            + "to answer them - the time it spent excused while the transport was not asking it for anything "
            + "must not be counted against it")
    public void testPeerGetsAFullPeriodAfterReadsResume() throws Exception {
        RecordingHandler recorder = new RecordingHandler();
        long startNanos = System.nanoTime();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            Object owner = new Object();
            AtomicBoolean suspended = new AtomicBoolean(true);
            BackPressureAwareIdleStateHandler.trackInboundReads(channel, owner, suspended::get);

            // Held suspended until just short of the second idle check, so the resume below lands in the worst
            // place it can: with the next check about to run and nothing having arrived from the peer yet.
            pollUntil(channel, startNanos + TimeUnit.MILLISECONDS.toNanos(
                    2 * IDLE_TIMEOUT_MILLIS - MARGIN_MILLIS));
            assertTrue(recorder.events.isEmpty(), "Idle event fired while reads were still suspended");

            // The application drains: reads are reissued, but the peer has not answered them yet.
            suspended.set(false);
            BackPressureAwareIdleStateHandler.inboundReadsResumed(channel, owner);

            // Past the check that was already due, but far short of a full period after the resume.
            pollFor(channel, 2 * MARGIN_MILLIS);

            assertTrue(recorder.events.isEmpty(),
                       "Peer was timed out moments after reads resumed, without being given a full period to "
                               + "answer the read it had only just been sent");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "A message that ends without ever untracking - an aborted request on a connection "
            + "whose handler is installed once and reused - must not leave its stall clock behind for the next "
            + "message on that channel to be reclaimed against")
    public void testNewOwnerDoesNotInheritThePreviousOwnersStallClock() throws Exception {
        Util.setMaxBackPressureStallTime(MAX_STALL_SECONDS);
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            // The first message stalls long enough to start a stall clock, then goes away without untracking.
            BackPressureAwareIdleStateHandler.trackInboundReads(channel, new Object(), () -> true);
            pollFor(channel, IDLE_TIMEOUT_MILLIS + MARGIN_MILLIS);
            assertTrue(recorder.events.isEmpty(), "Idle event fired before the stall allowance even began");

            // A new message starts on the same channel. Its allowance is its own, and has only just started.
            BackPressureAwareIdleStateHandler.trackInboundReads(channel, new Object(), () -> true);

            // Past when the clock left behind by the first message would have run out.
            pollFor(channel, STALL_MILLIS + MARGIN_MILLIS);

            assertTrue(recorder.events.isEmpty(),
                       "New message was reclaimed against the stall clock left behind by the previous one");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "An untrack call left over from a message that no longer owns this channel's tracking "
            + "state must not clear the suspension the message tracked in its place is relying on")
    public void testStaleUntrackFromPreviousOwnerDoesNotClearCurrentOwnersSuspension() throws Exception {
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            Object staleOwner = new Object();
            Object currentOwner = new Object();

            BackPressureAwareIdleStateHandler.trackInboundReads(channel, staleOwner, () -> false);
            // The channel has moved on: the message being read now is the one that is suspended.
            BackPressureAwareIdleStateHandler.trackInboundReads(channel, currentOwner, () -> true);

            // The superseded message detaching its listener late - a no-op, not a wipe of currentOwner's state.
            BackPressureAwareIdleStateHandler.untrackInboundReads(channel, staleOwner);

            pollFor(channel, IDLE_TIMEOUT_MILLIS + MARGIN_MILLIS);

            assertTrue(recorder.events.isEmpty(),
                       "Idle event fired even though the current owner's reads were suspended - the stale "
                               + "untrack cleared the suspension it no longer owned");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    private void pollUntil(EmbeddedChannel channel, long deadlineNanos) throws InterruptedException {
        while (System.nanoTime() < deadlineNanos) {
            Thread.sleep(POLL_STEP_MILLIS);
            channel.runScheduledPendingTasks();
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
