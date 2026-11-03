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

package io.ballerina.stdlib.http.transport.contractimpl.sender.states.http2;

import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.OutboundMsgHolder;
import io.ballerina.stdlib.http.transport.message.Http2DataFrame;
import io.ballerina.stdlib.http.transport.message.Http2HeadersFrame;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.util.ReferenceCountUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * State of a request whose stream could not be opened. The request has already failed, so the rest of its body is
 * released without being written, and no further attempt is made to open the stream.
 */
public class StreamNotOpened implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(StreamNotOpened.class);

    @Override
    public void writeOutboundRequestHeaders(ChannelHandlerContext ctx, HttpContent httpContent) {
        ReferenceCountUtil.release(httpContent);
    }

    @Override
    public void writeOutboundRequestBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                         Http2MessageStateContext http2MessageStateContext) {
        ReferenceCountUtil.release(httpContent);
    }

    @Override
    public void readInboundResponseHeaders(ChannelHandlerContext ctx, Http2HeadersFrame http2HeadersFrame,
                                           OutboundMsgHolder outboundMsgHolder, boolean serverPush,
                                           Http2MessageStateContext http2MessageStateContext) {
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
    public void handleStreamTimeout(OutboundMsgHolder outboundMsgHolder, boolean serverPush,
                                    ChannelHandlerContext ctx, int streamId) {
        LOG.debug("handleStreamTimeout for a request whose stream was never opened");
    }

    @Override
    public void handleConnectionClose(OutboundMsgHolder outboundMsgHolder) {
        LOG.debug("handleConnectionClose for a request whose stream was never opened");
    }

    @Override
    public void handleServerGoAway(OutboundMsgHolder outboundMsgHolder) {
        LOG.debug("handleServerGoAway for a request whose stream was never opened");
    }

    @Override
    public void handleRstStream(OutboundMsgHolder outboundMsgHolder) {
        LOG.debug("handleRstStream for a request whose stream was never opened");
    }

    @Override
    public void handleStreamClosedLocally(OutboundMsgHolder outboundMsgHolder) {
        LOG.debug("handleStreamClosedLocally for a request whose stream was never opened");
    }
}
