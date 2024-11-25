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

package io.ballerina.stdlib.http.transport.http2.listeners;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * Sleeps during response data write.
 */
public class Http2ServerWaitDuringDataWrite implements HttpConnectorListener {
    private static final Logger LOG = LoggerFactory.getLogger(Http2ServerWaitDuringDataWrite.class);
    private long waitTimeInMillis;

    public Http2ServerWaitDuringDataWrite(long waitTimeInMillis) {
        this.waitTimeInMillis = waitTimeInMillis;
    }

    @Override
    public void onMessage(HttpCarbonMessage httpRequest) {
        Thread.startVirtualThread(() -> {
            try {
                HttpCarbonMessage httpResponse = new HttpCarbonResponse(
                        new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
                httpResponse.setHeader(HttpHeaderNames.CONNECTION.toString(), HttpHeaderValues.KEEP_ALIVE.toString());
                httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
                httpResponse.setHttpStatusCode(HttpResponseStatus.OK.code());

                byte[] data1 = "Slow content data part1".getBytes(StandardCharsets.UTF_8);
                ByteBuffer byteBuff1 = ByteBuffer.wrap(data1);
                httpResponse.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(byteBuff1)));
                HttpResponseFuture responseFuture = httpRequest.respond(httpResponse);
                //Wait a considerable about of time to simulate server timeout during 'SendingEntityBody' state.
                Thread.sleep(waitTimeInMillis);
                responseFuture.sync();
            } catch (ServerConnectorException e) {
                LOG.error("Error occurred while processing message: " + e.getMessage());
            } catch (InterruptedException e) {
                LOG.error("InterruptedException occurred while processing message: " + e.getMessage());
            }
        });
    }

    @Override
    public void onError(Throwable throwable) {
        LOG.error("Error occurred in Http2ServerWaitDuringDataWrite: " + throwable.getMessage());
    }
}
