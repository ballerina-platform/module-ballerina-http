/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.contractimpl.common.states;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponse;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contractimpl.sender.TargetHandler;
import org.ballerinalang.net.transport.contractimpl.sender.states.SenderState;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

/**
 * Context class to manipulate current state of the message.
 */
public class SenderReqRespStateManager {

    public SenderState state;

    public final Channel nettyTargetChannel;
    public final int socketTimeout;

    public SenderReqRespStateManager(Channel nettyTargetChannel, int socketTimeout) {
        this.nettyTargetChannel = nettyTargetChannel;
        this.socketTimeout = socketTimeout;
    }

    public void writeOutboundRequestHeaders(HttpCarbonMessage httpOutboundRequest) {
        state.writeOutboundRequestHeaders(httpOutboundRequest);
    }

    public void writeOutboundRequestEntity(HttpCarbonMessage httpOutboundRequest, HttpContent httpContent) {
        state.writeOutboundRequestEntity(httpOutboundRequest, httpContent);
    }

    public void readInboundResponseHeaders(TargetHandler targetHandler, HttpResponse httpInboundResponse) {
        state.readInboundResponseHeaders(targetHandler, httpInboundResponse);
    }

    public void readInboundResponseEntityBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                              HttpCarbonMessage inboundResponseMsg) throws Exception {
        state.readInboundResponseEntityBody(ctx, httpContent, inboundResponseMsg);
    }

    public void handleAbruptChannelClosure(TargetHandler targetHandler, HttpResponseFuture httpResponseFuture) {
        nettyTargetChannel.close();
        state.handleAbruptChannelClosure(targetHandler, httpResponseFuture);
    }

    public void handleIdleTimeoutConnectionClosure(TargetHandler targetHandler,
                                                   HttpResponseFuture httpResponseFuture, String channelID) {
        state.handleIdleTimeoutConnectionClosure(targetHandler, httpResponseFuture, channelID);
    }
}
