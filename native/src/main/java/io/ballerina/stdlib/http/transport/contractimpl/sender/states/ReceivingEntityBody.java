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

package io.ballerina.stdlib.http.transport.contractimpl.sender.states;

import io.ballerina.stdlib.http.api.logging.accesslog.SenderHttpAccessLogger;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.LastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_STATE_HANDLER;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isKeepAlive;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.safelyRemoveHandlers;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.ILLEGAL_STATE_ERROR;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.handleIncompleteInboundMessage;

/**
 * State between start and end of inbound response entity body read.
 */
public class ReceivingEntityBody implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(ReceivingEntityBody.class);

    private final SenderReqRespStateManager senderReqRespStateManager;
    private final TargetHandler targetHandler;
    private SenderHttpAccessLogger accessLogger;

    ReceivingEntityBody(SenderReqRespStateManager senderReqRespStateManager, TargetHandler targetHandler) {
        this.senderReqRespStateManager = senderReqRespStateManager;
        this.targetHandler = targetHandler;
        if (targetHandler.getHttpClientChannelInitializer().isHttpAccessLogEnabled()) {
            accessLogger = new SenderHttpAccessLogger(targetHandler.getTargetChannel().getChannel().remoteAddress());
        }
    }

    @Override
    public void writeOutboundRequestHeaders(HttpCarbonMessage httpOutboundRequest) {
        LOG.warn("writeOutboundRequestHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void writeOutboundRequestEntity(HttpCarbonMessage httpOutboundRequest, HttpContent httpContent) {
        LOG.warn("writeOutboundRequestEntity {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void readInboundResponseHeaders(TargetHandler targetHandler, HttpResponse httpInboundResponse) {
        LOG.warn("readInboundResponseHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void readInboundResponseEntityBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                              HttpCarbonMessage inboundResponseMsg) throws Exception {

        if (httpContent instanceof LastHttpContent) {
            StateUtil.setInboundTrailersToNewMessage(((LastHttpContent) httpContent).trailingHeaders(),
                                                     inboundResponseMsg);
            addHttpContent(inboundResponseMsg, httpContent);
            inboundResponseMsg.setLastHttpContentArrived();
            targetHandler.resetInboundMsg();
            safelyRemoveHandlers(targetHandler.getTargetChannel().getChannel().pipeline(), IDLE_STATE_HANDLER);
            if (accessLogger != null) {
                accessLogger.updateAccessLogInfo(targetHandler.getOutboundRequestMsg(), inboundResponseMsg);
            }
            senderReqRespStateManager.state = new EntityBodyReceived(senderReqRespStateManager);

            if (!isKeepAlive(targetHandler.getKeepAliveConfig(),
                    targetHandler.getOutboundRequestMsg(), inboundResponseMsg)) {
                targetHandler.closeChannel(ctx);
            }
            targetHandler.getConnectionManager().returnChannel(targetHandler.getTargetChannel());
        } else {
            addHttpContent(inboundResponseMsg, httpContent);
        }
    }

    @Override
    public void handleAbruptChannelClosure(TargetHandler targetHandler, HttpResponseFuture httpResponseFuture) {
        handleIncompleteInboundMessage(targetHandler.getInboundResponseMsg(),
                                       REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    @Override
    public void handleIdleTimeoutConnectionClosure(TargetHandler targetHandler,
                                                   HttpResponseFuture httpResponseFuture, String channelID) {
        senderReqRespStateManager.nettyTargetChannel.pipeline().remove(IDLE_STATE_HANDLER);
        senderReqRespStateManager.nettyTargetChannel.close();
        handleIncompleteInboundMessage(targetHandler.getInboundResponseMsg(),
                                       IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    private void addHttpContent(HttpCarbonMessage inboundResponseMsg, HttpContent httpContent) {
        inboundResponseMsg.addHttpContent(httpContent);
        if (accessLogger != null) {
            accessLogger.updateContentLength(httpContent.content());
        }
    }
}
