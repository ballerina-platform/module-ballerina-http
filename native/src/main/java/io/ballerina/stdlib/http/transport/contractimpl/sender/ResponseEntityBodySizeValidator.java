/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpUtil;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.util.ReferenceCounted;

import java.util.LinkedList;

/**
 * Responsible for validating response entity body size before sending it to the application. If the validation fails,
 * throws an exception to be handled by the targetHandler for downstream notification through respective response
 * state.
 */
public class ResponseEntityBodySizeValidator extends ChannelInboundHandlerAdapter {

    private long maxEntityBodySize;
    private long currentSize;
    private HttpResponse inboundResponse;
    private LinkedList<HttpContent> fullContent;

    public ResponseEntityBodySizeValidator(long maxEntityBodySize) {
        this.maxEntityBodySize = maxEntityBodySize;
        this.fullContent = new LinkedList<>();
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (ctx.channel().isActive()) {
            if (msg instanceof HttpResponse) {
                inboundResponse = (HttpResponse) msg;
                if (isContentLengthInvalid(inboundResponse, maxEntityBodySize)) {
                    releaseContentAndNotifyError();
                    return;
                }
                ctx.channel().read();
            } else {
                HttpContent inboundContent = (HttpContent) msg;
                this.currentSize += inboundContent.content().readableBytes();
                this.fullContent.add(inboundContent);
                if (this.currentSize > maxEntityBodySize) {
                    releaseContentAndNotifyError();
                } else {
                    if (msg instanceof LastHttpContent) {
                        super.channelRead(ctx, this.inboundResponse);
                        while (!this.fullContent.isEmpty()) {
                            super.channelRead(ctx, this.fullContent.pop());
                        }
                    } else {
                        ctx.channel().read();
                    }
                }
            }
        }
    }

    private void releaseContentAndNotifyError() {
        this.fullContent.forEach(ReferenceCounted::release);
        this.fullContent.forEach(httpContent -> this.fullContent.remove(httpContent));
        throw new RuntimeException("Response max entity body size exceeds: Entity body is larger than "
                                           + this.maxEntityBodySize + " bytes. ");
    }

    private boolean isContentLengthInvalid(HttpMessage start, long maxContentLength) {
        try {
            return HttpUtil.getContentLength(start, -1L) > maxContentLength;
        } catch (NumberFormatException var4) {
            return false;
        }
    }
}
