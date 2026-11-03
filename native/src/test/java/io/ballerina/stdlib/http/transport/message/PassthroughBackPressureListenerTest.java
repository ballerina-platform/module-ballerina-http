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

package io.ballerina.stdlib.http.transport.message;

import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureAwareIdleStateHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.DefaultEventLoopGroup;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.channel.local.LocalChannel;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.timeout.IdleStateEvent;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that a {@link PassthroughBackPressureListener} suspending reads because its downstream leg went
 * unwritable is visible to {@link BackPressureAwareIdleStateHandler}, the same way {@link DefaultListener}'s own
 * internal queue cap already is - so the idle timeout does not mistake that back-pressure for an unresponsive
 * peer and tear the connection down mid-transfer.
 */
public class PassthroughBackPressureListenerTest {

    private static final long IDLE_TIMEOUT_MILLIS = 150;

    @AfterMethod
    public void resetStallLimit() {
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
    }

    @Test(description = "Reads suspended by a PassthroughBackPressureListener must excuse the idle timeout")
    public void testDownstreamUnwritableExcusesIdleTimeout() throws Exception {
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            ChannelHandlerContext ctx = channel.pipeline().context(recorder);
            DefaultListener defaultListener = new DefaultListener(ctx);
            defaultListener.onAdd(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[]{1})));

            PassthroughBackPressureListener passthroughListener =
                    new PassthroughBackPressureListener(ctx, defaultListener);
            passthroughListener.onUnWritable();

            waitPastIdleTimeoutAndRunDueTasks(channel);

            assertTrue(recorder.events.isEmpty(),
                       "Idle event fired even though reads were suspended by downstream back-pressure");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "Control case: suspending reads without going through PassthroughBackPressureListener - "
            + "the state before this fix - leaves the idle timeout blind to the suspension")
    public void testAutoReadAloneWithoutNotifyingTheListenerDoesNotExcuseIdleTimeout() throws Exception {
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
        RecordingHandler recorder = new RecordingHandler();
        EmbeddedChannel channel = new EmbeddedChannel(
                new BackPressureAwareIdleStateHandler(IDLE_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS), recorder);
        try {
            ChannelHandlerContext ctx = channel.pipeline().context(recorder);
            DefaultListener defaultListener = new DefaultListener(ctx);
            defaultListener.onAdd(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[]{1})));

            // Suspends reads the same way PassthroughBackPressureListener does, but without telling
            // DefaultListener - reproducing the gap this test guards against.
            channel.config().setAutoRead(false);

            waitPastIdleTimeoutAndRunDueTasks(channel);

            assertFalse(recorder.events.isEmpty(),
                        "Expected the idle event to fire when the suspension isn't tracked");
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    @Test(description = "A pause requested off the inbound event loop is applied on it, never from the caller")
    public void testReadInterestIsChangedOnlyOnTheInboundEventLoop() throws Exception {
        EventLoopGroup group = new DefaultEventLoopGroup(1);
        try {
            Channel channel = new LocalChannel();
            channel.pipeline().addLast(new ChannelInboundHandlerAdapter());
            group.register(channel).sync();
            ChannelHandlerContext ctx = channel.pipeline().firstContext();
            PassthroughBackPressureListener listener =
                    new PassthroughBackPressureListener(ctx, new DefaultListener(ctx));

            CountDownLatch releaseEventLoop = new CountDownLatch(1);
            channel.eventLoop().execute(() -> {
                try {
                    releaseEventLoop.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            boolean autoReadBeforeTheLoopRuns;
            try {
                listener.onUnWritable();
                autoReadBeforeTheLoopRuns = channel.config().isAutoRead();
            } finally {
                releaseEventLoop.countDown();
            }
            assertTrue(autoReadBeforeTheLoopRuns, "Read interest was changed from outside the event loop");
            channel.eventLoop().submit(() -> { }).sync();
            assertFalse(channel.config().isAutoRead());

            listener.onWritable();
            channel.eventLoop().submit(() -> { }).sync();
            assertTrue(channel.config().isAutoRead());
        } finally {
            group.shutdownGracefully(0, 1, TimeUnit.SECONDS).sync();
        }
    }

    @Test(description = "A writable event without a pause leaves reads suspended by something else alone")
    public void testWritableWithoutPauseDoesNotResumeReads() {
        ChannelInboundHandlerAdapter handler = new ChannelInboundHandlerAdapter();
        EmbeddedChannel channel = new EmbeddedChannel(handler);
        try {
            ChannelHandlerContext ctx = channel.pipeline().context(handler);
            PassthroughBackPressureListener listener =
                    new PassthroughBackPressureListener(ctx, new DefaultListener(ctx));
            channel.config().setAutoRead(false);

            listener.onWritable();

            assertFalse(channel.config().isAutoRead());
        } finally {
            channel.finishAndReleaseAll();
        }
    }

    private void waitPastIdleTimeoutAndRunDueTasks(EmbeddedChannel channel) throws InterruptedException {
        Thread.sleep(IDLE_TIMEOUT_MILLIS * 3);
        channel.runScheduledPendingTasks();
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
