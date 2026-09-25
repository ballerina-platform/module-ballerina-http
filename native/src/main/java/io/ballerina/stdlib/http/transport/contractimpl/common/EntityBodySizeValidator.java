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

import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpUtil;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.util.ReferenceCountUtil;

import java.util.LinkedList;

/**
 * Holds each inbound message back until its whole body has arrived, so that a body over the limit is rejected before
 * the message reaches the application. Subclasses decide how a rejection is reported.
 */
public abstract class EntityBodySizeValidator extends ChannelDuplexHandler {

    protected final long maxEntityBodySize;
    private final LinkedList<HttpContent> fullContent = new LinkedList<>();
    private long currentSize;
    private HttpMessage currentMessage;
    private HttpMessage heldMessage;
    private boolean passingThrough;

    protected EntityBodySizeValidator(long maxEntityBodySize) {
        this.maxEntityBodySize = maxEntityBodySize;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (!ctx.channel().isActive()) {
            ReferenceCountUtil.release(msg);
            return;
        }
        if (msg instanceof HttpMessage message) {
            // The handler lives as long as the connection, so a reused connection must not carry the previous
            // message's body over into this one's limit.
            releaseBufferedContent();
            this.currentSize = 0;
            this.currentMessage = message;
            this.heldMessage = null;
            this.passingThrough = false;
            if (mayHaveBody(message) && isContentLengthInvalid(message)) {
                rejectMessage(ctx);
                return;
            }
            if (message.decoderResult().isFailure() || passesThroughUnheld(message)) {
                // The decoder drops everything after a malformed message, so no body will follow to wait for.
                this.passingThrough = true;
                ctx.fireChannelRead(msg);
                return;
            }
            this.heldMessage = message;
            ctx.channel().read();
            return;
        }
        HttpContent inboundContent = (HttpContent) msg;
        this.currentSize += inboundContent.content().readableBytes();
        if (this.passingThrough) {
            if (this.currentSize > maxEntityBodySize) {
                inboundContent.release();
                rejectMessage(ctx);
            } else {
                ctx.fireChannelRead(msg);
            }
            return;
        }
        this.fullContent.add(inboundContent);
        if (this.currentSize > maxEntityBodySize) {
            rejectMessage(ctx);
        } else if (msg instanceof LastHttpContent) {
            passOnHeldMessage(ctx);
        } else {
            ctx.channel().read();
        }
    }

    @Override
    public void handlerRemoved(ChannelHandlerContext ctx) {
        releaseBufferedContent();
    }

    /**
     * Reports a message whose body exceeds the limit. Anything buffered for it has already been released.
     */
    protected abstract void onLimitExceeded(ChannelHandlerContext ctx);

    /**
     * Whether a message can carry the body its Content-Length declares. Called once for each message.
     */
    protected boolean mayHaveBody(HttpMessage message) {
        return true;
    }

    /**
     * Whether a message must be passed on as it arrives, its body counted as it passes, rather than held.
     */
    protected boolean passesThroughUnheld(HttpMessage message) {
        return false;
    }

    protected HttpMessage currentMessage() {
        return this.currentMessage;
    }

    public boolean isHoldingMessage() {
        return this.heldMessage != null;
    }

    protected void passOnHeldMessage(ChannelHandlerContext ctx) {
        HttpMessage message = this.heldMessage;
        this.heldMessage = null;
        this.passingThrough = true;
        ctx.fireChannelRead(message);
        while (!this.fullContent.isEmpty()) {
            ctx.fireChannelRead(this.fullContent.pop());
        }
    }

    private void rejectMessage(ChannelHandlerContext ctx) {
        releaseBufferedContent();
        this.heldMessage = null;
        this.passingThrough = false;
        onLimitExceeded(ctx);
    }

    private void releaseBufferedContent() {
        HttpContent httpContent;
        while ((httpContent = this.fullContent.poll()) != null) {
            httpContent.release();
        }
    }

    private boolean isContentLengthInvalid(HttpMessage message) {
        try {
            return HttpUtil.getContentLength(message, -1L) > maxEntityBodySize;
        } catch (NumberFormatException e) {
            return false;
        }
    }
}
