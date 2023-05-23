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

package io.ballerina.stdlib.http.transport.contractimpl.listener.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.listener.HttpServerChannelInitializer;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufUtil;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.group.ChannelGroup;
import io.netty.handler.codec.http2.Http2CodecUtil;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.safelyRemoveHandlers;
import static java.lang.Math.min;

/**
 * {@code Http2WithPriorKnowledgeHandler} handles the requests received directly in HTTP/2 without
 * attempting an upgrade from HTTP/1.x.
 * <p>
 * As per https://tools.ietf.org/html/rfc7540#section-3.4 a client can directly send HTTP/2 frames if
 * it is has a prior knowledge of server's capability of handling HTTP/2.
 */
public class Http2WithPriorKnowledgeHandler extends ChannelInboundHandlerAdapter {

    private String interfaceId;
    private String serverName;
    private ServerConnectorFuture serverConnectorFuture;
    private HttpServerChannelInitializer serverChannelInitializer;
    private ChannelGroup allChannels;
    private ChannelGroup listenerChannels;
    private int initialWindowSize;

    public Http2WithPriorKnowledgeHandler(String interfaceId, String serverName,
                                          ServerConnectorFuture serverConnectorFuture,
                                          HttpServerChannelInitializer serverChannelInitializer,
                                          ChannelGroup allChannels,
                                          ChannelGroup listenerChannels,
                                          int initialWindowSize) {
        this.interfaceId = interfaceId;
        this.serverName = serverName;
        this.serverConnectorFuture = serverConnectorFuture;
        this.serverChannelInitializer = serverChannelInitializer;
        this.allChannels = allChannels;
        this.listenerChannels = listenerChannels;
        this.initialWindowSize = initialWindowSize;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        if (msg instanceof ByteBuf) {
            ByteBuf inputData = (ByteBuf) msg;
            ByteBuf clientPrefaceString = Http2CodecUtil.connectionPrefaceBuf();
            int bytesRead = min(inputData.readableBytes(), clientPrefaceString.readableBytes());
            ChannelPipeline pipeline = ctx.pipeline();
            if (ByteBufUtil.equals(inputData, inputData.readerIndex(), clientPrefaceString,
                    clientPrefaceString.readerIndex(), bytesRead)) {
                // HTTP/2 request received without an upgrade
                safelyRemoveHandlers(pipeline, Constants.HTTP_SERVER_CODEC);
                pipeline.addBefore(
                        Constants.HTTP2_UPGRADE_HANDLER,
                        Constants.HTTP2_SOURCE_CONNECTION_HANDLER,
                        new Http2SourceConnectionHandlerBuilder(
                                interfaceId, serverConnectorFuture, serverName, serverChannelInitializer,
                                allChannels, listenerChannels, initialWindowSize).build());

                safelyRemoveHandlers(pipeline, Constants.HTTP2_UPGRADE_HANDLER,
                        Constants.HTTP_COMPRESSOR, Constants.HTTP_TRACE_LOG_HANDLER);
            }
            pipeline.remove(this);
            ctx.fireChannelRead(msg);
        }
    }
}
