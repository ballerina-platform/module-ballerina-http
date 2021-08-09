/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */
package io.ballerina.stdlib.http.transport.contractimpl.websocket;

import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketConnectorException;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketWriteTimeOutListener;
import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;

/**
 * Handler to capture and handle Client write timeout event.
 */
public class ClientWriteTimeoutHandler extends ChannelDuplexHandler {
    WebSocketWriteTimeOutListener timeOutListener;

    public ClientWriteTimeoutHandler(WebSocketWriteTimeOutListener timeOutListener) {
        this.timeOutListener = timeOutListener;
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            if (event.state() == IdleState.WRITER_IDLE) {
                timeOutListener.onTimeout(new WebSocketConnectorException("Write timed out"));
            } else {
                ctx.fireUserEventTriggered(evt);
            }
        }
    }
}
