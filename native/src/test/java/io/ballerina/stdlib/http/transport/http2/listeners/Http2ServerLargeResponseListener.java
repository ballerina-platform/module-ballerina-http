/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.http2.listeners;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Responds with a body that is large enough to exhaust the HTTP/2 inbound flow control window of a client that
 * does not consume it promptly.
 */
public class Http2ServerLargeResponseListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http2ServerLargeResponseListener.class);
    private static final int CHUNK_SIZE = 8192;

    private final int responseSize;

    public Http2ServerLargeResponseListener(int responseSize) {
        this.responseSize = responseSize;
    }

    public static byte[] buildExpectedPayload(int size) {
        byte[] payload = new byte[size];
        for (int i = 0; i < size; i++) {
            payload[i] = (byte) ('A' + (i % 26));
        }
        return payload;
    }

    @Override
    public void onMessage(HttpCarbonMessage httpRequest) {
        Thread.startVirtualThread(() -> {
            try {
                HttpCarbonMessage httpResponse = new HttpCarbonResponse(
                        new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
                httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
                httpResponse.setHttpStatusCode(HttpResponseStatus.OK.code());

                HttpResponseFuture responseFuture = httpRequest.respond(httpResponse);

                byte[] payload = buildExpectedPayload(responseSize);
                for (int offset = 0; offset < responseSize; offset += CHUNK_SIZE) {
                    int length = Math.min(CHUNK_SIZE, responseSize - offset);
                    httpResponse.addHttpContent(
                            new DefaultHttpContent(Unpooled.copiedBuffer(payload, offset, length)));
                }
                httpResponse.addHttpContent(new DefaultLastHttpContent());

                responseFuture.sync();
                Throwable error = responseFuture.getStatus().getCause();
                if (error != null) {
                    responseFuture.resetStatus();
                    LOG.error("Error occurred while sending the response {}", error.getMessage());
                }
            } catch (Exception e) {
                LOG.error("Error occurred while processing message: {}", e.getMessage());
            }
        });
    }

    @Override
    public void onError(Throwable throwable) {
        LOG.error("Error occurred in Http2ServerLargeResponseListener: {}", throwable.getMessage());
    }
}
