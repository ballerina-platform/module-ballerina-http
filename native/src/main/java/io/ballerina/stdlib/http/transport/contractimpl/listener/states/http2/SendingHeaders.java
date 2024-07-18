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

import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.Http2OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceHandler;
import io.ballerina.stdlib.http.transport.message.Http2DataFrame;
import io.ballerina.stdlib.http.transport.message.Http2HeadersFrame;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2Headers;
import io.netty.handler.codec.http2.HttpConversionUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP2_VERSION;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_SENT_GOAWAY_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil.validatePromisedStreamState;

/**
 * State between start and end of outbound response headers write.
 *
 * @since 6.0.241
 */
public class SendingHeaders implements ListenerState {

    private static final Logger LOG = LoggerFactory.getLogger(SendingHeaders.class);

    private final Http2MessageStateContext http2MessageStateContext;
    private final ChannelHandlerContext ctx;
    private final Http2Connection conn;
    private final Http2ConnectionEncoder encoder;
    private final HttpResponseFuture outboundRespStatusFuture;
    private final HttpCarbonMessage inboundRequestMsg;
    private final int originalStreamId;
    private final String serverName;
    private final Http2OutboundRespListener http2OutboundRespListener;

    public SendingHeaders(Http2OutboundRespListener http2OutboundRespListener,
                          Http2MessageStateContext http2MessageStateContext) {
        this.http2OutboundRespListener = http2OutboundRespListener;
        this.http2MessageStateContext = http2MessageStateContext;
        this.ctx = http2OutboundRespListener.getChannelHandlerContext();
        this.conn = http2OutboundRespListener.getConnection();
        this.encoder = http2OutboundRespListener.getEncoder();
        this.outboundRespStatusFuture = http2OutboundRespListener.getOutboundRespStatusFuture();
        this.inboundRequestMsg = http2OutboundRespListener.getInboundRequestMsg();
        this.serverName = http2OutboundRespListener.getServerName();
        this.originalStreamId = http2OutboundRespListener.getOriginalStreamId();
    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http2HeadersFrame headersFrame) {
        LOG.warn("readInboundRequestHeaders is not a dependant action of this state");
    }

    @Override
    public void readInboundRequestBody(Http2SourceHandler http2SourceHandler, Http2DataFrame dataFrame) throws
            Http2Exception, ServerConnectorException {
        // In bidirectional streaming case, while sending the request data frames, server response data frames can
        // receive. In order to handle it. we need to change the states depending on the action.
        http2MessageStateContext.setListenerState(new ReceivingEntityBody(http2MessageStateContext));
        http2MessageStateContext.getListenerState().readInboundRequestBody(http2SourceHandler, dataFrame);
    }

    @Override
    public void writeOutboundResponseHeaders(Http2OutboundRespListener http2OutboundRespListener,
                                             HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                             int streamId) throws Http2Exception {
        writeHeaders(outboundResponseMsg, streamId);
        http2MessageStateContext.setListenerState(
                new SendingEntityBody(http2OutboundRespListener, http2MessageStateContext));
        http2MessageStateContext.getListenerState()
                .writeOutboundResponseBody(http2OutboundRespListener, outboundResponseMsg, httpContent, streamId);
    }

    @Override
    public void writeOutboundResponseBody(Http2OutboundRespListener http2OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          int streamId) throws Http2Exception {
        // When the initial frames of the response for the upgraded request is to be sent.
        writeOutboundResponseHeaders(http2OutboundRespListener, outboundResponseMsg, httpContent, streamId);
    }

    @Override
    public void writeOutboundPromise(Http2OutboundRespListener http2OutboundRespListener,
                                     Http2PushPromise pushPromise) throws Http2Exception {
        LOG.warn("writeOutboundPromise is not a dependant action of this state");
        throw new Http2Exception(Http2Error.PROTOCOL_ERROR,
                "WriteOutboundPromise is not a dependant action of SendingHeaders state");
    }

    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                    Http2OutboundRespListener http2OutboundRespListener, int streamId) {
        try {
            serverConnectorFuture.notifyErrorListener(
                    new ServerConnectorException(IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS));
            LOG.error(IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
        } catch (ServerConnectorException e) {
            LOG.error("Error while notifying error state to server-connector listener");
        }
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                           Http2OutboundRespListener http2OutboundRespListener, int streamId) {
        IOException connectionClose = new IOException(REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
        http2OutboundRespListener.getOutboundResponseMsg().setIoException(connectionClose);
        outboundRespStatusFuture.notifyHttpListener(connectionClose);

        LOG.error(REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
    }

    @Override
    public void handleClientGoAway(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext
            channelHandlerContext, Http2OutboundRespListener http2OutboundRespListener, Integer streamId) {
        IOException connectionClose = new IOException(REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
        http2OutboundRespListener.getOutboundResponseMsg().setIoException(connectionClose);
        outboundRespStatusFuture.notifyHttpListener(connectionClose);

        LOG.error(REMOTE_CLIENT_SENT_GOAWAY_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
    }

    private void writeHeaders(HttpCarbonMessage outboundResponseMsg, int streamId) throws Http2Exception {
        outboundResponseMsg.getHeaders().
                add(HttpConversionUtil.ExtensionHeaderNames.SCHEME.text(), HTTP_SCHEME);
        StateUtil.addTrailerHeaderIfPresent(outboundResponseMsg);
        HttpMessage httpMessage =
                Util.createHttpResponse(outboundResponseMsg, HTTP2_VERSION, serverName, true);
        // Construct Http2 headers
        Http2Headers http2Headers = HttpConversionUtil.toHttp2Headers(httpMessage, true);
        validatePromisedStreamState(originalStreamId, streamId, conn, inboundRequestMsg);
        Http2StateUtil.writeHttp2ResponseHeaders(ctx, encoder, outboundRespStatusFuture, streamId, http2Headers, false,
                                                 http2OutboundRespListener, inboundRequestMsg);
        http2MessageStateContext.setHeadersSent(true);
    }
}
