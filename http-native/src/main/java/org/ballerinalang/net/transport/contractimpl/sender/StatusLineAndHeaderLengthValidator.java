/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.contractimpl.sender;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.TooLongFrameException;
import io.netty.handler.codec.http.HttpResponse;
import org.wso2.transport.http.netty.contract.Constants;

/**
 * Responsible for validating the inbound response's status line and total header size before sending it to the
 * application. If the validation fails, throws an exception to be handled by the targetHandler for downstream
 * notification through respective response state.
 */
public class StatusLineAndHeaderLengthValidator extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (msg instanceof HttpResponse) {
            if (!ctx.channel().isActive()) {
                return;
            }
            Throwable cause = ((HttpResponse) msg).decoderResult().cause();
            if (cause instanceof TooLongFrameException) {
                String message = cause.getMessage();
                if (message.contains(Constants.REQUEST_HEADER_TOO_LARGE)) {
                    throw new RuntimeException("Response max header size exceeds: " + cause.getMessage());
                } else if (message.contains(Constants.REQUEST_LINE_TOO_LONG)) {
                    throw new RuntimeException("Response max status line length exceeds: " + cause.getMessage());
                } else {
                    super.channelRead(ctx, msg);
                }
            } else {
                super.channelRead(ctx, msg);
            }
        } else {
            super.channelRead(ctx, msg);
        }
    }
}
