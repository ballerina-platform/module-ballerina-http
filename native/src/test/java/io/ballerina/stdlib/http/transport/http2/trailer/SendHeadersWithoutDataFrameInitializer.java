/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.http2.trailer;

import io.netty.channel.Channel;
import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.DefaultHttp2HeadersFrame;
import io.netty.handler.codec.http2.DefaultHttp2WindowUpdateFrame;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2DataFrame;
import io.netty.handler.codec.http2.Http2FrameStream;
import io.netty.handler.codec.http2.Http2Headers;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.Http2ServerInitializer;

/**
 * An initializer class for HTTP Server. The responsibility of this class is to simulate an abnormal backend response
 * scenario which send trailers along with leading headers and no data frame.
 */
public class SendHeadersWithoutDataFrameInitializer extends Http2ServerInitializer {

    private Http2Headers headers;

    protected void addBusinessLogicHandler(Channel channel) {
        channel.pipeline().addLast("handler", new SendHeadersWithoutDataFrameHandler());
    }

    public void setHeaders(Http2Headers headers) {
        this.headers = headers;
    }

    @Override
    protected ChannelHandler getBusinessLogicHandler() {
        return new SendHeadersWithoutDataFrameHandler();
    }

    @Override
    protected Http2ConnectionHandler getBusinessLogicHandlerViaBuiler() {
        return null;
    }

    private class SendHeadersWithoutDataFrameHandler extends ChannelDuplexHandler {

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {

            if (msg instanceof Http2DataFrame) {
                Http2DataFrame data = (Http2DataFrame) msg;
                Http2FrameStream stream = data.stream();
                if (data.isEndStream()) {
                    ctx.write(new DefaultHttp2HeadersFrame(headers, true).stream(stream));
                } else {
                    data.release();
                }
                ctx.write(new DefaultHttp2WindowUpdateFrame(data.initialFlowControlledBytes()).stream(stream));
            }
        }
    }
}
