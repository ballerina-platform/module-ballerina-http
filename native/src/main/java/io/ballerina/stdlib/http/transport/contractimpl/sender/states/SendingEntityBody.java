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

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contract.exceptions.EndpointTimeOutException;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.channels.ClosedChannelException;

import static io.ballerina.stdlib.http.transport.contract.Constants.CLIENT_TO_REMOTE_HOST_CONNECTION_CLOSED;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_REQUEST_BODY;
import static io.ballerina.stdlib.http.transport.contract.Constants.INBOUND_RESPONSE_ALREADY_RECEIVED;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isLastHttpContent;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.ILLEGAL_STATE_ERROR;

/**
 * State between start and end of outbound request entity body write.
 */
public class SendingEntityBody implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(SendingEntityBody.class);

    private final SenderReqRespStateManager senderReqRespStateManager;

    private final HandlerExecutor handlerExecutor;
    private final HttpResponseFuture httpInboundResponseFuture;

    SendingEntityBody(SenderReqRespStateManager senderReqRespStateManager,
                      HttpResponseFuture httpInboundResponseFuture) {
        this.senderReqRespStateManager = senderReqRespStateManager;
        this.handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        this.httpInboundResponseFuture = httpInboundResponseFuture;
    }

    @Override
    public void writeOutboundRequestHeaders(HttpCarbonMessage httpOutboundRequest) {
        LOG.warn("writeOutboundRequestHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void writeOutboundRequestEntity(HttpCarbonMessage httpOutboundRequest, HttpContent httpContent) {
        if (isLastHttpContent(httpContent)) {
            writeOutboundRequestBody(httpContent);

            if (handlerExecutor != null) {
                handlerExecutor.executeAtTargetRequestSending(httpOutboundRequest);
            }
        } else {
            senderReqRespStateManager.nettyTargetChannel.writeAndFlush(httpContent);
        }
    }

    @Override
    public void readInboundResponseHeaders(TargetHandler targetHandler, HttpResponse httpInboundResponse) {
        // If this method is called, it is an application error. Inbound response is receiving before the completion
        // of request body write.
        if (httpInboundResponse.status().code() != HttpResponseStatus.CONTINUE.code()) {
            targetHandler.getOutboundRequestMsg().setIoException(new IOException(INBOUND_RESPONSE_ALREADY_RECEIVED));
            senderReqRespStateManager.setState(new ReceivingHeaders(senderReqRespStateManager));
            senderReqRespStateManager.readInboundResponseHeaders(targetHandler, httpInboundResponse);
        }
    }

    @Override
    public void readInboundResponseEntityBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                              HttpCarbonMessage inboundResponseMsg) {
        LOG.warn("readInboundResponseEntityBody {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void handleAbruptChannelClosure(TargetHandler targetHandler, HttpResponseFuture httpResponseFuture) {
        targetHandler.getOutboundRequestMsg()
                .setIoException(new IOException(REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY));
        httpResponseFuture.notifyHttpListener(
                        new ClientConnectorException(senderReqRespStateManager.nettyTargetChannel.id().asShortText(),
                REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY));
        LOG.error("Error in HTTP client: {}", REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY);
    }

    @Override
    public void handleIdleTimeoutConnectionClosure(TargetHandler targetHandler,
                                                   HttpResponseFuture httpResponseFuture, String channelID) {

        senderReqRespStateManager.nettyTargetChannel.pipeline().remove(Constants.IDLE_STATE_HANDLER);
        senderReqRespStateManager.nettyTargetChannel.close();
        targetHandler.getOutboundRequestMsg()
                .setIoException(new IOException(IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_REQUEST_BODY));
        httpResponseFuture.notifyHttpListener(
                new EndpointTimeOutException(channelID, IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_REQUEST_BODY,
                                             HttpResponseStatus.INTERNAL_SERVER_ERROR.code()));

        LOG.error("Error in HTTP client: {}", IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_REQUEST_BODY);
    }

    private void writeOutboundRequestBody(HttpContent lastHttpContent) {
        ChannelFuture outboundRequestChannelFuture =
                senderReqRespStateManager.nettyTargetChannel.writeAndFlush(lastHttpContent);
        checkForRequestWriteStatus(outboundRequestChannelFuture);
    }

    private void checkForRequestWriteStatus(ChannelFuture outboundRequestChannelFuture) {
        outboundRequestChannelFuture.addListener(writeOperationPromise -> {
            Throwable throwable = writeOperationPromise.cause();
            if (throwable != null) {
                if (throwable instanceof ClosedChannelException) {
                    throwable = new IOException(CLIENT_TO_REMOTE_HOST_CONNECTION_CLOSED);
                }
                httpInboundResponseFuture.notifyHttpListener(throwable);
            } else {
                senderReqRespStateManager.setState(new RequestCompleted(senderReqRespStateManager));
            }
        });
    }
}
