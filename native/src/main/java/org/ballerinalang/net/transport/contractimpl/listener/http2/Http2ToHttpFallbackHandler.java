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

package org.ballerinalang.net.transport.contractimpl.listener.http2;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.ChannelPipeline;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contractimpl.listener.HttpServerChannelInitializer;

import static org.ballerinalang.net.transport.contractimpl.common.Util.safelyRemoveHandlers;

/**
 * {@code Http2ToHttpFallbackHandler} is responsible for fallback from http2 to http when http2 upgrade fails.
 */
public class Http2ToHttpFallbackHandler extends ChannelInboundHandlerAdapter {

    private HttpServerChannelInitializer serverChannelInitializer;

    public Http2ToHttpFallbackHandler(HttpServerChannelInitializer serverChannelInitializer) {
        this.serverChannelInitializer = serverChannelInitializer;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ChannelPipeline pipeline = ctx.pipeline();
        safelyRemoveHandlers(pipeline, Constants.HTTP2_UPGRADE_HANDLER);
        serverChannelInitializer.configureHttpPipeline(pipeline, Constants.HTTP2_CLEARTEXT_PROTOCOL);
        pipeline.remove(this);
        ctx.fireChannelActive();
        ctx.fireChannelRead(msg);
    }
}
