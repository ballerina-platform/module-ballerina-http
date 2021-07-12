/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.contractimpl.listener.states;

import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.util.CharsetUtil;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.exceptions.ClientClosedConnectionException;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.HttpOutboundRespListener;
import org.ballerinalang.net.transport.contractimpl.common.Util;
import org.ballerinalang.net.transport.contractimpl.listener.SourceHandler;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.netty.buffer.Unpooled.copiedBuffer;
import static io.netty.handler.codec.http.HttpResponseStatus.REQUEST_TIMEOUT;
import static org.ballerinalang.net.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static org.ballerinalang.net.transport.contractimpl.common.states.StateUtil.CONNECTOR_NOTIFYING_ERROR;
import static org.ballerinalang.net.transport.contractimpl.common.states.StateUtil.sendRequestTimeoutResponse;

/**
 * State between end of payload read and start of response headers write.
 */
public class EntityBodyReceived implements ListenerState {

    private static final Logger LOG = LoggerFactory.getLogger(EntityBodyReceived.class);

    private final ListenerReqRespStateManager listenerReqRespStateManager;
    private final SourceHandler sourceHandler;
    private final float httpVersion;

    EntityBodyReceived(ListenerReqRespStateManager listenerReqRespStateManager, SourceHandler sourceHandler,
                       float httpVersion) {
        this.listenerReqRespStateManager = listenerReqRespStateManager;
        this.sourceHandler = sourceHandler;
        this.httpVersion = httpVersion;
    }

    @Override
    public void readInboundRequestHeaders(HttpCarbonMessage inboundRequestMsg, HttpRequest inboundRequestHeaders) {
        LOG.warn("readInboundRequestHeaders is not a dependant action of this state");
    }

    @Override
    public void readInboundRequestBody(Object inboundRequestEntityBody) throws ServerConnectorException {
        LOG.warn("readInboundRequestBody is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseHeaders(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        LOG.warn("writeOutboundResponseHeaders is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseBody(HttpOutboundRespListener outboundResponseListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        if (Util.getHttpResponseStatus(outboundResponseMsg).code() != HttpResponseStatus.CONTINUE.code()) {
            listenerReqRespStateManager.state
                    = new SendingHeaders(listenerReqRespStateManager, outboundResponseListener);
            listenerReqRespStateManager.writeOutboundResponseHeaders(outboundResponseMsg, httpContent);
        }
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {
        try {
            serverConnectorFuture.notifyErrorListener(
                    new ClientClosedConnectionException(REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE));
        } catch (ServerConnectorException e) {
            LOG.error(CONNECTOR_NOTIFYING_ERROR, e);
        }
    }

    @Override
    public ChannelFuture handleIdleTimeoutConnectionClosure(ServerConnectorFuture serverConnectorFuture,
                                                            ChannelHandlerContext ctx) {
        try {
            serverConnectorFuture.notifyErrorListener(
                    new ServerConnectorException(IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE));
        } catch (ServerConnectorException e) {
            LOG.error(CONNECTOR_NOTIFYING_ERROR, e);
        }
        String responseValue = IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
        ChannelFuture outboundRespFuture =
                sendRequestTimeoutResponse(ctx, REQUEST_TIMEOUT,
                                           copiedBuffer(responseValue, CharsetUtil.UTF_8), responseValue.length(),
                                           httpVersion, sourceHandler.getServerName());
        outboundRespFuture.addListener((ChannelFutureListener) channelFuture -> {
            Throwable cause = channelFuture.cause();
            if (cause != null) {
                LOG.warn("Failed to send: {}", cause.getMessage());
            }
            ctx.close();
        });
        return outboundRespFuture;
    }
}
