/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl;

import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpClientUpgradeHandler;
import io.netty.handler.codec.http.HttpObject;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.LastHttpContent;

import java.util.List;

import static io.netty.handler.codec.http.HttpResponseStatus.CONTINUE;
import static io.netty.util.ReferenceCountUtil.release;

/**
 * Implementation of the client upgrade handler.
 */
public class DefaultHttpClientUpgradeHandler extends HttpClientUpgradeHandler {

    private boolean continueResponse;

    public DefaultHttpClientUpgradeHandler(SourceCodec sourceCodec,
                                           UpgradeCodec upgradeCodec, int maxContentLength) {
        super(sourceCodec, upgradeCodec, maxContentLength);
    }

    @Override
    protected void decode(ChannelHandlerContext ctx, HttpObject msg, List<Object> out) throws Exception {
        // Handle intermediate 100-Continue responses
        if (continueResponse && msg instanceof LastHttpContent) {
            // Release the last empty content associated with the 100-Continue response
            release(msg);
            return;
        }

        if (msg instanceof HttpResponse && CONTINUE.equals(((HttpResponse) msg).status())) {
            continueResponse = true;
            ctx.fireChannelRead(msg);
            return;
        }

        continueResponse = false;
        super.decode(ctx, msg, out);
    }
}
