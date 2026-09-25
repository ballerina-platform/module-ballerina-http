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

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contractimpl.common.EntityBodySizeValidator;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelPromise;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpStatusClass;
import io.netty.handler.timeout.IdleStateEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contract.Constants.HEADER_VAL_100_CONTINUE;

/**
 * Responsible for validating request entity body size before sending it to the application.
 */
public class MaxEntityBodyValidator extends EntityBodySizeValidator {

    private static final Logger LOG = LoggerFactory.getLogger(MaxEntityBodyValidator.class);

    private final String serverName;
    private long requestsReceived;
    private long responsesStarted;

    MaxEntityBodyValidator(String serverName, long maxEntityBodySize) {
        super(maxEntityBodySize);
        this.serverName = serverName;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (msg instanceof HttpRequest) {
            this.requestsReceived++;
        }
        super.channelRead(ctx, msg);
    }

    @Override
    public void write(ChannelHandlerContext ctx, Object msg, ChannelPromise promise) {
        if (msg instanceof HttpResponse response && response.status().codeClass() != HttpStatusClass.INFORMATIONAL) {
            this.responsesStarted++;
        }
        ctx.write(msg, promise);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent && isHoldingMessage()) {
            // Handing over what has arrived lets the source handler time the request out as it does without a limit.
            passOnHeldMessage(ctx);
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    protected boolean passesThroughUnheld(HttpMessage message) {
        // A 100-continue client sends its body only after the service answers, which needs the request first.
        return HEADER_VAL_100_CONTINUE.equalsIgnoreCase(message.headers().get(HttpHeaderNames.EXPECT));
    }

    @Override
    protected void onLimitExceeded(ChannelHandlerContext ctx) {
        LOG.warn("Inbound request payload size exceeds the max entity body allowed for a request");
        if (this.responsesStarted >= this.requestsReceived) {
            // A 413 after the service's response would be read by the client as the response to its next request.
            ctx.channel().close();
            return;
        }
        Util.sendAndCloseNoEntityBodyResp(ctx, HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE,
                                          currentMessage().protocolVersion(), this.serverName);
    }
}
