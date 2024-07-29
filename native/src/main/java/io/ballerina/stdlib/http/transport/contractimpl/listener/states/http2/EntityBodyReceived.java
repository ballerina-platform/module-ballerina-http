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

package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http2;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientClosedConnectionException;
import io.ballerina.stdlib.http.transport.contract.exceptions.EndpointTimeOutException;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.Http2OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceHandler;
import io.ballerina.stdlib.http.transport.message.Http2DataFrame;
import io.ballerina.stdlib.http.transport.message.Http2HeadersFrame;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP2_SERVER_TIMEOUT_ERROR_MESSAGE;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_SENT_GOAWAY_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil.writeHttp2Promise;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.CONNECTOR_NOTIFYING_ERROR;

/**
 * State between end of inbound request payload read and start of outbound response or push response headers write.
 *
 * @since 6.0.241
 */
public class EntityBodyReceived implements ListenerState {

    private static final Logger LOG = LoggerFactory.getLogger(EntityBodyReceived.class);

    private final Http2MessageStateContext http2MessageStateContext;

    public EntityBodyReceived(Http2MessageStateContext http2MessageStateContext) {
        this.http2MessageStateContext = http2MessageStateContext;
    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http2HeadersFrame headersFrame) {
        LOG.warn("readInboundRequestHeaders is not a dependant action of this state");
    }

    @Override
    public void readInboundRequestBody(Http2SourceHandler http2SourceHandler, Http2DataFrame dataFrame) {
        LOG.warn("readInboundRequestBody is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseHeaders(Http2OutboundRespListener http2OutboundRespListener,
                                             HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                             int streamId) {
        LOG.warn("writeOutboundResponseHeaders is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseBody(Http2OutboundRespListener http2OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          int streamId) throws Http2Exception {
        if (http2MessageStateContext.isHeadersSent()) {
            // response header already sent. move the state to SendingEntityBody.
            http2MessageStateContext.setListenerState(
                    new SendingEntityBody(http2OutboundRespListener, http2MessageStateContext));
            http2MessageStateContext.getListenerState()
                    .writeOutboundResponseBody(http2OutboundRespListener, outboundResponseMsg, httpContent, streamId);
        } else {
            Http2StateUtil.beginResponseWrite(http2MessageStateContext, http2OutboundRespListener,
                                              outboundResponseMsg, httpContent, streamId);
        }
    }

    @Override
    public void writeOutboundPromise(Http2OutboundRespListener http2OutboundRespListener,
                                     Http2PushPromise pushPromise) throws Http2Exception {
        writeHttp2Promise(pushPromise, http2OutboundRespListener.getChannelHandlerContext(),
                http2OutboundRespListener.getConnection(), http2OutboundRespListener.getEncoder(),
                http2OutboundRespListener.getInboundRequestMsg(),
                http2OutboundRespListener.getInboundRequestMsg().getHttpOutboundRespStatusFuture(),
                http2OutboundRespListener.getOriginalStreamId());
    }

    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                    Http2OutboundRespListener http2OutboundRespListener, int streamId) {
        try {
            serverConnectorFuture.notifyErrorListener(new EndpointTimeOutException(
                    IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE,
                    HttpResponseStatus.GATEWAY_TIMEOUT.code()));
        } catch (ServerConnectorException e) {
            LOG.error(IDLE_TIMEOUT_TRIGGERED_BEFORE_INITIATING_OUTBOUND_RESPONSE + ":" + e.getMessage());
        }
        //Write server timeout error to caller
        Http2StateUtil.sendRequestTimeoutResponse(ctx, http2OutboundRespListener, streamId,
                                                  HttpResponseStatus.INTERNAL_SERVER_ERROR, Unpooled.copiedBuffer(
                        HTTP2_SERVER_TIMEOUT_ERROR_MESSAGE, CharsetUtil.UTF_8), false, false);
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                           Http2OutboundRespListener http2OutboundRespListener, int streamId) {
        try {
            serverConnectorFuture.notifyErrorListener(
                    new ClientClosedConnectionException(REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE));
        } catch (ServerConnectorException e) {
            LOG.error(CONNECTOR_NOTIFYING_ERROR, e);
        }
        http2OutboundRespListener.getOutboundResponseMsg().setIoException(
                new IOException(REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE));
    }

    @Override
    public void handleClientGoAway(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext
            channelHandlerContext, Http2OutboundRespListener http2OutboundRespListener, Integer streamId) {
        try {
            serverConnectorFuture.notifyErrorListener(
                    new ClientClosedConnectionException(REMOTE_CLIENT_SENT_GOAWAY_BEFORE_INITIATING_OUTBOUND_RESPONSE));
        } catch (ServerConnectorException e) {
            LOG.error(CONNECTOR_NOTIFYING_ERROR, e);
        }
        http2OutboundRespListener.getOutboundResponseMsg().setIoException(
                new IOException(REMOTE_CLIENT_SENT_GOAWAY_BEFORE_INITIATING_OUTBOUND_RESPONSE));
    }
}
