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

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.ballerina.stdlib.http.transport.contract.CallExchange;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.TargetChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2CallAborter;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.states.SendingHeaders;
import io.netty.channel.Channel;
import io.netty.handler.codec.http2.Http2CodecUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.RejectedExecutionException;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP2_TARGET_HANDLER;

/**
 * Aborts the exchange of an HTTP/1.1 request by closing the connection that carries it, which is the only way to
 * stop an HTTP/1.1 exchange part-way. The pool then drops the connection.
 */
public class Http1CallAborter implements CallExchange.Aborter {

    private static final Logger LOG = LoggerFactory.getLogger(Http1CallAborter.class);

    private final TargetChannel targetChannel;
    private final CallExchange exchange;

    public Http1CallAborter(TargetChannel targetChannel, CallExchange exchange) {
        this.targetChannel = targetChannel;
        this.exchange = exchange;
    }

    @Override
    public void abort(Throwable failure) {
        Channel channel = targetChannel.getChannel();
        if (channel == null) {
            // The connection is not set up yet, so the request is never sent on it once it is
            return;
        }
        try {
            channel.eventLoop().execute(() -> abortOnEventLoop(channel, failure));
        } catch (RejectedExecutionException e) {
            LOG.debug("Event loop is shut down, so the connection is closing anyway: {}", e.getMessage());
        }
    }

    // On the event loop that handles the connection's events, where the exchange is also released, so the check
    // below tells for certain whether the connection still belongs to the exchange
    private void abortOnEventLoop(Channel channel, Throwable failure) {
        if (targetChannel.getCurrentExchange() != exchange) {
            return;
        }
        if (channel.pipeline().get(HTTP2_TARGET_HANDLER) != null) {
            // The connection was upgraded to HTTP/2, so the request is a stream on it that the exchange resets
            Http2ClientChannel http2ClientChannel = targetChannel.getHttp2ClientChannel();
            new Http2CallAborter(http2ClientChannel, http2ClientChannel.getInFlightMessage(
                    Http2CodecUtil.HTTP_UPGRADE_STREAM_ID), () -> Http2CodecUtil.HTTP_UPGRADE_STREAM_ID)
                    .abortOnEventLoop(failure);
            return;
        }
        // The requests waiting for this connection to become an HTTP/2 one must not fail with this call, so each of
        // them opens its own
        targetChannel.reportHttp2Unavailable();
        if (targetChannel.senderReqRespStateManager.state instanceof SendingHeaders sendingHeaders) {
            sendingHeaders.releaseHeldContent();
        }
        TargetHandler targetHandler = targetChannel.getTargetHandler();
        if (targetHandler != null) {
            targetHandler.abortExchange(failure);
        } else {
            channel.close();
        }
    }
}
