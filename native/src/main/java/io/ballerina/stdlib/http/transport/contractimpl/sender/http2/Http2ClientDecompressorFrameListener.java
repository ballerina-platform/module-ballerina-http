/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.DelegatingDecompressorFrameListener;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2Headers;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contract.Constants.CONTENT_DECODING_FAILED;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.handleIncompleteInboundMessage;

/**
 * A {@link DelegatingDecompressorFrameListener} that reports content decoding failures back to the caller.
 * <p>
 * Netty raises a stream error when decoding fails, which {@code Http2ConnectionHandler} answers with a local
 * RST_STREAM without firing {@code exceptionCaught}. Nothing downstream of the codec ever learns why the stream
 * ended, so the pending response body would otherwise be left waiting on content that can no longer arrive.
 * This listener turns a decode failure into an error on the response, matching what the HTTP/1.1 pipeline
 * produces through {@code TargetHandler.exceptionCaught}.
 */
public class Http2ClientDecompressorFrameListener extends DelegatingDecompressorFrameListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http2ClientDecompressorFrameListener.class);

    private final ClientFrameListener clientFrameListener;

    public Http2ClientDecompressorFrameListener(Http2Connection connection,
                                                ClientFrameListener clientFrameListener) {
        super(connection, clientFrameListener);
        this.clientFrameListener = clientFrameListener;
    }

    @Override
    public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int padding,
                              boolean endStream) throws Http2Exception {
        try {
            super.onHeadersRead(ctx, streamId, headers, padding, endStream);
        } catch (Throwable cause) {
            notifyDecodingFailure(streamId, cause);
            throw cause;
        }
    }

    @Override
    public void onHeadersRead(ChannelHandlerContext ctx, int streamId, Http2Headers headers, int streamDependency,
                              short weight, boolean exclusive, int padding, boolean endStream) throws Http2Exception {
        try {
            super.onHeadersRead(ctx, streamId, headers, streamDependency, weight, exclusive, padding, endStream);
        } catch (Throwable cause) {
            notifyDecodingFailure(streamId, cause);
            throw cause;
        }
    }

    @Override
    public int onDataRead(ChannelHandlerContext ctx, int streamId, ByteBuf data, int padding,
                          boolean endOfStream) throws Http2Exception {
        try {
            return super.onDataRead(ctx, streamId, data, padding, endOfStream);
        } catch (Throwable cause) {
            notifyDecodingFailure(streamId, cause);
            throw cause;
        }
    }

    private void notifyDecodingFailure(int streamId, Throwable cause) {
        Http2ClientChannel http2ClientChannel = clientFrameListener.getHttp2ClientChannel();
        if (http2ClientChannel == null) {
            return;
        }
        OutboundMsgHolder outboundMsgHolder = http2ClientChannel.getInFlightMessage(streamId);
        if (outboundMsgHolder == null || !outboundMsgHolder.claimStreamTermination()) {
            return;
        }
        String errorMessage = CONTENT_DECODING_FAILED + ": " + cause.getMessage();
        if (outboundMsgHolder.getResponse() == null) {
            // Headers never made it through, so no response exists to terminate.
            outboundMsgHolder.getResponseFuture().notifyHttpListener(new Exception(errorMessage, cause));
        } else {
            handleIncompleteInboundMessage(outboundMsgHolder.getResponse(), errorMessage);
        }
        LOG.debug("Content decoding failed on stream id: {}", streamId, cause);
    }
}
