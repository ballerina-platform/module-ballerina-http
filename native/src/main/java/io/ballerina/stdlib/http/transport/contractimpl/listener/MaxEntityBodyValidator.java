/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpUtil;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.util.ReferenceCountUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.LinkedList;

import static io.ballerina.stdlib.http.transport.contract.Constants.HEADER_VAL_100_CONTINUE;

/**
 * Responsible for validating request entity body size before sending it to the application.
 */
public class MaxEntityBodyValidator extends ChannelInboundHandlerAdapter {

    private static final Logger LOG = LoggerFactory.getLogger(MaxEntityBodyValidator.class);

    private final String serverName;
    private final long maxEntityBodySize;
    private final LinkedList<HttpContent> fullContent = new LinkedList<>();
    private long currentSize;
    private HttpVersion requestVersion;
    private HttpRequest heldRequest;
    private boolean passingThrough;

    MaxEntityBodyValidator(String serverName, long maxEntityBodySize) {
        this.serverName = serverName;
        this.maxEntityBodySize = maxEntityBodySize;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (!ctx.channel().isActive()) {
            ReferenceCountUtil.release(msg);
            return;
        }
        if (msg instanceof HttpRequest request) {
            // The handler lives as long as the connection, so a keep-alive connection must not carry the previous
            // request's body over into this one's limit.
            releaseBufferedContent();
            this.currentSize = 0;
            this.requestVersion = request.protocolVersion();
            this.heldRequest = null;
            this.passingThrough = false;
            if (isContentLengthInvalid(request, maxEntityBodySize)) {
                sendEntityTooLargeResponse(ctx);
                return;
            }
            if (request.decoderResult().isFailure() || isContinueExpected(request)) {
                // Nothing follows a malformed request, and a 100-continue client sends its body only after the
                // service answers, so neither can be held until its body arrives.
                this.passingThrough = true;
                super.channelRead(ctx, msg);
                return;
            }
            this.heldRequest = request;
            ctx.channel().read();
            return;
        }
        HttpContent inboundContent = (HttpContent) msg;
        this.currentSize += inboundContent.content().readableBytes();
        if (this.passingThrough) {
            if (this.currentSize > maxEntityBodySize) {
                inboundContent.release();
                sendEntityTooLargeResponse(ctx);
            } else {
                super.channelRead(ctx, msg);
            }
            return;
        }
        this.fullContent.add(inboundContent);
        if (this.currentSize > maxEntityBodySize) {
            sendEntityTooLargeResponse(ctx);
        } else if (msg instanceof LastHttpContent) {
            passOnHeldRequest(ctx);
        } else {
            ctx.channel().read();
        }
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent && this.heldRequest != null) {
            // Handing over what has arrived lets the source handler time the request out as it does without a limit.
            passOnHeldRequest(ctx);
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    public void handlerRemoved(ChannelHandlerContext ctx) {
        releaseBufferedContent();
    }

    private void passOnHeldRequest(ChannelHandlerContext ctx) {
        HttpRequest request = this.heldRequest;
        this.heldRequest = null;
        this.passingThrough = true;
        ctx.fireChannelRead(request);
        while (!this.fullContent.isEmpty()) {
            ctx.fireChannelRead(this.fullContent.pop());
        }
    }

    private void sendEntityTooLargeResponse(ChannelHandlerContext ctx) {
        Util.sendAndCloseNoEntityBodyResp(ctx, HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE, this.requestVersion,
                                          this.serverName);
        releaseBufferedContent();
        this.heldRequest = null;
        this.passingThrough = false;
        LOG.warn("Inbound request payload size exceeds the max entity body allowed for a request");
    }

    private void releaseBufferedContent() {
        HttpContent httpContent;
        while ((httpContent = this.fullContent.poll()) != null) {
            httpContent.release();
        }
    }

    private static boolean isContinueExpected(HttpRequest request) {
        return HEADER_VAL_100_CONTINUE.equalsIgnoreCase(request.headers().get(HttpHeaderNames.EXPECT));
    }

    private boolean isContentLengthInvalid(HttpMessage start, long maxContentLength) {
        try {
            return HttpUtil.getContentLength(start, -1L) > maxContentLength;
        } catch (NumberFormatException var4) {
            return false;
        }
    }
}
