/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender.states;

import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contract.Constants.CONNECTION_CLOSED_INCOMPLETE_OUTBOUND_REQUEST_BODY;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.ILLEGAL_STATE_ERROR;

/**
 * State of an outbound request whose body failed before it was fully sent. The connection is closed instead of
 * ending the body, so the backend cannot take the part already sent for a complete request.
 */
public class RequestBodyAborted implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(RequestBodyAborted.class);

    private final SenderReqRespStateManager senderReqRespStateManager;

    private RequestBodyAborted(SenderReqRespStateManager senderReqRespStateManager) {
        this.senderReqRespStateManager = senderReqRespStateManager;
    }

    static void abort(SenderReqRespStateManager senderReqRespStateManager, HttpResponseFuture httpResponseFuture,
                      HttpContent failedBodyEnd) {
        failedBodyEnd.release();
        senderReqRespStateManager.state = new RequestBodyAborted(senderReqRespStateManager);
        httpResponseFuture.notifyHttpListener(new ClientConnectorException(
                senderReqRespStateManager.nettyTargetChannel.id().asShortText(),
                CONNECTION_CLOSED_INCOMPLETE_OUTBOUND_REQUEST_BODY));
        senderReqRespStateManager.nettyTargetChannel.close();
        LOG.warn(CONNECTION_CLOSED_INCOMPLETE_OUTBOUND_REQUEST_BODY);
    }

    @Override
    public void writeOutboundRequestHeaders(HttpCarbonMessage httpOutboundRequest) {
        LOG.warn("writeOutboundRequestHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void writeOutboundRequestEntity(HttpCarbonMessage httpOutboundRequest, HttpContent httpContent) {
        httpContent.release();
    }

    @Override
    public void readInboundResponseHeaders(TargetHandler targetHandler, HttpResponse httpInboundResponse) {
        LOG.debug("readInboundResponseHeaders after the outbound request body was aborted");
    }

    @Override
    public void readInboundResponseEntityBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                              HttpCarbonMessage inboundResponseMsg) {
        httpContent.release();
    }

    @Override
    public void handleAbruptChannelClosure(TargetHandler targetHandler, HttpResponseFuture httpResponseFuture) {
        // The caller was told when the request was aborted; this is the closure that followed.
    }

    @Override
    public void handleIdleTimeoutConnectionClosure(TargetHandler targetHandler,
                                                   HttpResponseFuture httpResponseFuture, String channelID) {
        senderReqRespStateManager.nettyTargetChannel.close();
    }
}
