/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.message;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.EventLoop;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2LocalFlowController;
import io.netty.handler.codec.http2.Http2Stream;
import io.netty.incubator.codec.http3.DefaultHttp3HeadersFrame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Represents the HTTP/3 inbound content listener.
 */
public class Http3InboundContentListener implements Listener {

    private long streamId;
    private boolean appConsumeRequired = true;
    private AtomicBoolean consumeInboundContent = new AtomicBoolean(true);
    private ChannelHandlerContext channelHandlerContext;
    private String inboundType;

    public Http3InboundContentListener(long streamId, ChannelHandlerContext ctx,
                                       String inboundType) {
        this.streamId = streamId;
        this.channelHandlerContext = ctx;
        this.inboundType = inboundType;
    }

    @Override
    public void onAdd(HttpContent httpContent) {
    }

    public void onRemove(HttpContent httpContent) {
    }

    @Override
    public void resumeReadInterest() {

    }

}
