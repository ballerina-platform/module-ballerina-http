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

import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;

/**
 * Consumes the inbound request body deliberately slowly, pausing for longer than the server socket idle
 * timeout, and then responds with the number of bytes it managed to read.
 *
 * <p>The response payload is the byte count on success, or {@code error: <message>} if reading the body
 * failed, so a test can tell a complete read apart from a stream that was cut short.
 */
public class Http2SlowRequestBodyConsumerListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http2SlowRequestBodyConsumerListener.class);

    public static final String ERROR_PREFIX = "error: ";

    private final int readSlice;
    private final long pauseMillis;
    private final int pausedReads;

    public Http2SlowRequestBodyConsumerListener(int readSlice, long pauseMillis, int pausedReads) {
        this.readSlice = readSlice;
        this.pauseMillis = pauseMillis;
        this.pausedReads = pausedReads;
    }

    @Override
    public void onMessage(HttpCarbonMessage httpRequest) {
        Thread.startVirtualThread(() -> {
            String result = readBodySlowly(httpRequest);
            try {
                httpRequest.respond(MessageGenerator.generateResponse(result)).sync();
            } catch (Exception e) {
                LOG.error("Error occurred while sending the response: {}", e.getMessage());
            }
        });
    }

    private String readBodySlowly(HttpCarbonMessage httpRequest) {
        long totalRead = 0;
        int pausesTaken = 0;
        try (InputStream inputStream = new HttpMessageDataStreamer(httpRequest).getInputStream()) {
            byte[] buffer = new byte[readSlice];
            while (true) {
                int readCount = inputStream.read(buffer, 0, readSlice);
                if (readCount == -1) {
                    break;
                }
                totalRead += readCount;

                // Stall for longer than the server idle timeout a handful of times. Before the fix the stream
                // was failed during the very first of these pauses.
                if (pausesTaken < pausedReads) {
                    pausesTaken++;
                    LOG.debug("Pausing the request body consumer after reading {} bytes", totalRead);
                    Thread.sleep(pauseMillis);
                }
            }
            return Long.toString(totalRead);
        } catch (Exception e) {
            LOG.warn("Failed to read the request body after {} bytes: {}", totalRead, e.getMessage());
            return ERROR_PREFIX + e.getMessage();
        }
    }

    @Override
    public void onError(Throwable throwable) {
        LOG.error("Error occurred in Http2SlowRequestBodyConsumerListener: {}", throwable.getMessage());
    }
}
