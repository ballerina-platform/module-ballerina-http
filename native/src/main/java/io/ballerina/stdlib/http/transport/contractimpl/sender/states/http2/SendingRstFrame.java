/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.sender.states.http2;

import io.ballerina.stdlib.http.transport.contract.exceptions.EndpointTimeOutException;
import io.ballerina.stdlib.http.transport.contract.exceptions.RequestCancelledException;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2TargetHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.OutboundMsgHolder;
import io.ballerina.stdlib.http.transport.message.Http2DataFrame;
import io.ballerina.stdlib.http.transport.message.Http2HeadersFrame;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2Exception;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_SENDING_RST_STREAM;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_SENDING_RST_STREAM;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_SENT_GOAWAY_WHILE_SENDING_RST_STREAM;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_SENT_RST_STREAM_WHILE_SENDING_RST_STREAM;

/**
 * A state to reset the stream in the middle of communication.
 */
public class SendingRstFrame implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(SendingRstFrame.class);

    private final Http2TargetHandler http2TargetHandler;
    private final Http2MessageStateContext http2MessageStateContext;
    private final OutboundMsgHolder outboundMsgHolder;
    private final Http2ClientChannel http2ClientChannel;
    private final Http2ConnectionEncoder encoder;
    private int streamId;
    private final Http2TargetHandler.Http2RequestWriter http2RequestWriter;

    public SendingRstFrame(Http2TargetHandler http2TargetHandler,
                           Http2TargetHandler.Http2RequestWriter http2RequestWriter) {
        this.http2TargetHandler = http2TargetHandler;
        this.http2MessageStateContext = http2RequestWriter.getHttp2MessageStateContext();
        this.outboundMsgHolder = http2RequestWriter.getOutboundMsgHolder();
        this.http2ClientChannel = http2TargetHandler.getHttp2ClientChannel();
        this.encoder = http2TargetHandler.getEncoder();
        this.streamId = http2RequestWriter.getStreamId();
        this.http2RequestWriter = http2RequestWriter;
    }

    @Override
    public void writeOutboundRequestHeaders(ChannelHandlerContext ctx, HttpContent httpContent) throws Http2Exception {
        LOG.warn("writeOutboundRequestHeaders is not a dependant action of this state");
    }

    @Override
    public void writeOutboundRequestBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                         Http2MessageStateContext http2MessageStateContext) throws Http2Exception {
        resetStream(ctx);
    }

    @Override
    public void readInboundResponseHeaders(ChannelHandlerContext ctx, Http2HeadersFrame http2HeadersFrame,
                                           OutboundMsgHolder outboundMsgHolder, boolean serverPush,
                                           Http2MessageStateContext http2MessageStateContext) throws Http2Exception {
        LOG.warn("readInboundResponseHeaders is not a dependant action of this state");
    }

    @Override
    public void readInboundResponseBody(ChannelHandlerContext ctx, Http2DataFrame http2DataFrame,
                                        OutboundMsgHolder outboundMsgHolder, boolean serverPush,
                                        Http2MessageStateContext http2MessageStateContext) {
        LOG.warn("readInboundResponseBody is not a dependant action of this state");
    }

    @Override
    public void readInboundPromise(ChannelHandlerContext ctx, Http2PushPromise http2PushPromise,
                                   OutboundMsgHolder outboundMsgHolder) {
        LOG.warn("readInboundPromise is not a dependant action of this state");
    }

    @Override
    public void handleStreamTimeout(OutboundMsgHolder outboundMsgHolder, boolean serverPush, ChannelHandlerContext ctx,
                                    int streamId) throws Http2Exception {
        if (!serverPush) {
            outboundMsgHolder.getResponseFuture().notifyHttpListener(
                    new EndpointTimeOutException(IDLE_TIMEOUT_TRIGGERED_WHILE_SENDING_RST_STREAM,
                            HttpResponseStatus.GATEWAY_TIMEOUT.code()));
        }
    }

    @Override
    public void handleConnectionClose(OutboundMsgHolder outboundMsgHolder) {
        outboundMsgHolder.getResponseFuture().notifyHttpListener(new ServerConnectorException(
                REMOTE_SERVER_CLOSED_WHILE_SENDING_RST_STREAM));
    }

    @Override
    public void handleServerGoAway(OutboundMsgHolder outboundMsgHolder) {
        outboundMsgHolder.getResponseFuture().notifyHttpListener(new RequestCancelledException(
                REMOTE_SERVER_SENT_GOAWAY_WHILE_SENDING_RST_STREAM,
                HttpResponseStatus.BAD_GATEWAY.code()));
    }

    @Override
    public void handleRstStream(OutboundMsgHolder outboundMsgHolder) {
        outboundMsgHolder.getResponseFuture().notifyHttpListener(new RequestCancelledException(
                REMOTE_SERVER_SENT_RST_STREAM_WHILE_SENDING_RST_STREAM,
                HttpResponseStatus.BAD_GATEWAY.code()));
    }

    public void resetStream(ChannelHandlerContext ctx) {
        encoder.writeRstStream(ctx, streamId, Http2Error.STREAM_CLOSED.code(), ctx.newPromise());
        try {
            encoder.flowController().writePendingBytes();
        } catch (Http2Exception e) {
            LOG.warn(e.toString());
        }
        ctx.flush();
        outboundMsgHolder.setRequestWritten(true);
        http2MessageStateContext.setSenderState(new RequestCompleted(http2TargetHandler, http2RequestWriter));
    }
}
