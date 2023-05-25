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

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.TooLongFrameException;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Responsible for validating the request before sending it to the application.
 */
public class UriAndHeaderLengthValidator extends ChannelInboundHandlerAdapter {

    private static final Logger LOG = LoggerFactory.getLogger(UriAndHeaderLengthValidator.class);

    private String serverName;

    UriAndHeaderLengthValidator(String serverName) {
        this.serverName = serverName;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (msg instanceof HttpRequest) {
            if (ctx.channel().isActive()) {
                HttpRequest inboundRequest = (HttpRequest) msg;
                Throwable cause = inboundRequest.decoderResult().cause();
                if (cause instanceof TooLongFrameException) {
                    if (cause.getMessage().contains(Constants.REQUEST_HEADER_TOO_LARGE)) {
                        String errorMsg = "Inbound request Entity exceeds the max header size allowed for a request";
                        Util.sendAndCloseEntityBodyResp(ctx, HttpResponseStatus.REQUEST_HEADER_FIELDS_TOO_LARGE,
                                HttpVersion.HTTP_1_0, serverName, errorMsg, inboundRequest.uri(),
                                inboundRequest.method().name());
                        LOG.warn(errorMsg);
                    } else if (cause.getMessage().contains(Constants.REQUEST_LINE_TOO_LONG)) {
                        String errorMsg = "Inbound request URI length exceeds the max uri length allowed for a request";
                                Util.sendAndCloseEntityBodyResp(ctx, HttpResponseStatus.REQUEST_URI_TOO_LONG,
                                HttpVersion.HTTP_1_0, serverName, errorMsg, inboundRequest.uri(),
                                inboundRequest.method().name());
                        LOG.warn(errorMsg);
                    } else {
                        super.channelRead(ctx, msg);
                    }
                } else {
                    super.channelRead(ctx, msg);
                }
            }
        } else {
            super.channelRead(ctx, msg);
        }
    }
}
