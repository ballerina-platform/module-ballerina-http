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

package io.ballerina.stdlib.http.transport.contractimpl.listener.states;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.HttpOutboundRespListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpRequest;

/**
 * Context class to manipulate current state of the listener message.
 */
public class ListenerReqRespStateManager {

    private ListenerState state;

    public void readInboundRequestHeaders(HttpCarbonMessage inboundRequestMsg, HttpRequest inboundRequestHeaders) {
        state.readInboundRequestHeaders(inboundRequestMsg, inboundRequestHeaders);
    }

    public void readInboundRequestBody(Object inboundRequestEntityBody) throws ServerConnectorException {
        state.readInboundRequestBody(inboundRequestEntityBody);
    }

    public void writeOutboundResponseHeaders(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        state.writeOutboundResponseHeaders(outboundResponseMsg, httpContent);
    }

    public void writeOutboundResponseBody(HttpOutboundRespListener outboundResponseListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        state.writeOutboundResponseBody(outboundResponseListener, outboundResponseMsg, httpContent);
    }

    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {
        state.handleAbruptChannelClosure(serverConnectorFuture);
    }

    public ChannelFuture handleIdleTimeoutConnectionClosure(ServerConnectorFuture serverConnectorFuture,
                                                            ChannelHandlerContext ctx) {
        return state.handleIdleTimeoutConnectionClosure(serverConnectorFuture, ctx);
    }

    public void setState(ListenerState state) {
        this.state = state;
    }
}
