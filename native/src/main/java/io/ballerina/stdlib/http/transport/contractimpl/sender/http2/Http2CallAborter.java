/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.contract.CallExchange;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.Http2Error;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.RejectedExecutionException;
import java.util.function.IntSupplier;

import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.handleIncompleteInboundMessage;

/**
 * Aborts the exchange of an HTTP/2 request by resetting its stream with {@code CANCEL}, which leaves the connection
 * and the other streams on it alone.
 */
public class Http2CallAborter implements CallExchange.Aborter {

    private static final Logger LOG = LoggerFactory.getLogger(Http2CallAborter.class);

    private final Http2ClientChannel http2ClientChannel;
    private final OutboundMsgHolder outboundMsgHolder;
    // Looked up when the exchange is aborted, as the stream is only opened once the request starts to be written
    private final IntSupplier streamIdSupplier;

    public Http2CallAborter(Http2ClientChannel http2ClientChannel, OutboundMsgHolder outboundMsgHolder,
                            IntSupplier streamIdSupplier) {
        this.http2ClientChannel = http2ClientChannel;
        this.outboundMsgHolder = outboundMsgHolder;
        this.streamIdSupplier = streamIdSupplier;
    }

    /**
     * Creates the aborter of the exchange of a request written on a stream of the given channel.
     *
     * @param http2ClientChannel the channel carrying the stream
     * @param outboundMsgHolder  the request
     * @return the aborter
     */
    public static Http2CallAborter forStreamOf(Http2ClientChannel http2ClientChannel,
                                               OutboundMsgHolder outboundMsgHolder) {
        return new Http2CallAborter(http2ClientChannel, outboundMsgHolder, () -> {
            HttpCarbonMessage request = outboundMsgHolder.getRequest();
            return request.getHttp2MessageStateContext() == null ? 0 :
                    request.getHttp2MessageStateContext().getStreamId();
        });
    }

    @Override
    public void abort(Throwable failure) {
        try {
            http2ClientChannel.getChannel().eventLoop().execute(() -> abortOnEventLoop(failure));
        } catch (RejectedExecutionException e) {
            LOG.debug("Event loop is shut down, so the connection is closing anyway: {}", e.getMessage());
        }
    }

    /**
     * Aborts the stream. Must run on the event loop of the connection.
     *
     * @param failure the reason the exchange is aborted
     */
    public void abortOnEventLoop(Throwable failure) {
        if (outboundMsgHolder == null) {
            return;
        }
        int streamId = streamIdSupplier.getAsInt();
        if (streamId <= 0) {
            // No stream is open, and the request is not written on one once the exchange is aborted
            return;
        }
        // A stream that ended already is not tied to the exchange any more
        if (http2ClientChannel.getMessageSendingRequest(streamId) != outboundMsgHolder
                || !outboundMsgHolder.claimStreamTermination()) {
            return;
        }
        outboundMsgHolder.getRequest().setIoException(new IOException(failure.getMessage()));
        Channel channel = http2ClientChannel.getChannel();
        ChannelHandlerContext ctx = channel.pipeline().context(Constants.HTTP2_TARGET_HANDLER);
        if (ctx != null) {
            ((Http2TargetHandler) ctx.handler()).resetStream(ctx, streamId, Http2Error.CANCEL);
        }
        // The caller of a response that has not been delivered yet was told by the exchange, so what is left to fail
        // is a response whose body is still arriving
        if (outboundMsgHolder.getResponse() != null) {
            handleIncompleteInboundMessage(outboundMsgHolder.getResponse(), failure.getMessage());
        }
        http2ClientChannel.removeInFlightMessage(streamId);
    }
}
