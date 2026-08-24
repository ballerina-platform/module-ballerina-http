/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.message;

import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureAwareIdleStateHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * Default implementation of the message Listener.
 */
public class DefaultListener implements Listener {

    private static final int MAXIMUM_BYTE_SIZE = 2097152; //Maximum threshold of reading bytes(2MB)
    private final AtomicInteger cumulativeByteQuantity = new AtomicInteger(0);
    private volatile ChannelHandlerContext ctx;
    private volatile boolean readCompleted = false;
    private boolean first = true;
    // Set by a PassthroughBackPressureListener when the downstream leg this response (or request) is being
    // relayed to goes unwritable. That listener suspends reads on this channel the same way onAdd's own cap
    // does, so the idle timeout must treat it as back-pressure too, not just the internal queue cap below.
    private volatile boolean downstreamBackPressured = false;

    public DefaultListener(ChannelHandlerContext ctx) {
        this.ctx = ctx;
    }

    @Override
    public void onAdd(HttpContent httpContent) {
        if (first) {
            this.ctx.channel().config().setAutoRead(false);
            // From here on the socket is only read on demand, so the idle timeout needs to be able to tell
            // whether the transport has deliberately stopped asking the peer for data.
            BackPressureAwareIdleStateHandler.trackInboundReads(this.ctx.channel(), this, this::isReadSuspended);
            first = false;
        }
        int count = this.cumulativeByteQuantity.addAndGet(httpContent.content().readableBytes());
        if (readCompleted) {
            return;
        }
        if (Util.isLastHttpContent(httpContent)) {
            // Restore default read behaviour regardless of how much content is still queued, so a pooled
            // connection is not handed back with its reads suspended.
            Channel channel = this.ctx.channel();
            readCompleted = true;
            this.ctx = null;
            BackPressureAwareIdleStateHandler.untrackInboundReads(channel);
            channel.config().setAutoRead(true);
        } else if (count < MAXIMUM_BYTE_SIZE) {
            BackPressureAwareIdleStateHandler.inboundReadsResumed(this.ctx.channel(), this);
            this.ctx.channel().read();
        }
        // Otherwise reads stay suspended until the application drains what is already queued.
    }

    @Override
    public void onRemove(HttpContent httpContent) {
        ChannelHandlerContext currentCtx = this.ctx;
        if (currentCtx == null) {
            this.cumulativeByteQuantity.addAndGet(-(httpContent.content().readableBytes()));
            return;
        }
        // Recorded before the reduced count is published, so that whoever observes the lower count also
        // observes the refreshed resume time instead of a stale one that could time the peer out early. Guarded
        // by identity: if this call is delayed past the point where a pooled channel has moved on to tracking a
        // new message, it must not resurrect that new message's stall clock.
        BackPressureAwareIdleStateHandler.inboundReadsResumed(currentCtx.channel(), this);
        int count = this.cumulativeByteQuantity.addAndGet(-(httpContent.content().readableBytes()));
        if (count < MAXIMUM_BYTE_SIZE && !readCompleted) {
            currentCtx.channel().read();
        }
    }

    @Override
    public void resumeReadInterest() {
        ChannelHandlerContext currentCtx = this.ctx;
        if (currentCtx != null) {
            // This listener is being detached, so it will never report progress on the channel again and
            // must not be left as the answer to "are the reads suspended".
            BackPressureAwareIdleStateHandler.untrackInboundReads(currentCtx.channel());
            currentCtx.channel().config().setAutoRead(true);
        }
    }

    // Derived from the queue itself rather than a latched flag, so the event loop adding content and the
    // application thread draining it cannot leave the two disagreeing.
    private boolean isReadSuspended() {
        return !readCompleted && (cumulativeByteQuantity.get() >= MAXIMUM_BYTE_SIZE || downstreamBackPressured);
    }

    /**
     * Called by a {@link PassthroughBackPressureListener} when the downstream leg this message is being
     * relayed to has gone unwritable and reads on this channel have been suspended as a result.
     */
    public void onDownstreamUnwritable() {
        downstreamBackPressured = true;
    }

    /**
     * Called by a {@link PassthroughBackPressureListener} when the downstream leg this message is being
     * relayed to has become writable again. Restarts the idle countdown the same way resuming reads for the
     * internal queue cap does, since the peer was excused from it for the same reason.
     */
    public void onDownstreamWritable() {
        downstreamBackPressured = false;
        ChannelHandlerContext currentCtx = this.ctx;
        if (currentCtx != null) {
            BackPressureAwareIdleStateHandler.inboundReadsResumed(currentCtx.channel(), this);
        }
    }
}
