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

package io.ballerina.stdlib.http.transport;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.LargeResponseServerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.InputStream;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that a client which consumes a large inbound response body slowly is not disconnected by the socket
 * idle timeout: reads paused waiting on the application must not be counted as an idle connection.
 */
public class SlowInboundResponseBodyConsumerTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(SlowInboundResponseBodyConsumerTestCase.class);

    // Large enough to push the inbound content past the 2MB threshold at which reads are throttled.
    private static final int RESPONSE_SIZE = 4 * 1024 * 1024;
    private static final int SOCKET_IDLE_TIMEOUT = 2000;
    // Read in slices that are small relative to the body, pausing for longer than the idle timeout in between.
    private static final int READ_SLICE = 64 * 1024;
    private static final int CONSUMER_PAUSE = SOCKET_IDLE_TIMEOUT + SOCKET_IDLE_TIMEOUT / 2;
    private static final int PAUSED_READS = 2;
    // A regression here shows up as a stalled transfer rather than a quick error, so the test methods and the
    // tear down are bounded to keep a failure a red test instead of a hung build.
    private static final int TEST_TIME_OUT = 60000;
    private static final int CLEAN_UP_TIME_OUT = 30000;

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT,
                                              new LargeResponseServerInitializer(RESPONSE_SIZE));

        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setSocketIdleTimeout(SOCKET_IDLE_TIMEOUT);
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A response body consumed more slowly than the socket idle timeout must still arrive "
                  + "in full, because the idleness is caused by the consumer rather than by the remote server.")
    public void testSlowlyConsumedLargeResponseIsNotTruncated() throws Exception {
        HttpCarbonMessage msg = TestUtil.createHttpPostReq(TestUtil.HTTP_SERVER_PORT, "Test request body", "");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = httpClientConnector.send(msg);
        responseFuture.setHttpConnectorListener(listener);

        assertTrue(latch.await(10, TimeUnit.SECONDS), "Did not receive the response headers");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Response message is null: " + listener.getHttpErrorMessage());

        byte[] expected = LargeResponseServerInitializer.buildExpectedPayload(RESPONSE_SIZE);
        byte[] received = new byte[RESPONSE_SIZE];
        int totalRead = 0;
        int pausesTaken = 0;

        try (InputStream inputStream = new HttpMessageDataStreamer(response).getInputStream()) {
            while (totalRead < RESPONSE_SIZE) {
                int toRead = Math.min(READ_SLICE, RESPONSE_SIZE - totalRead);
                int readCount = inputStream.read(received, totalRead, toRead);
                if (readCount == -1) {
                    break;
                }
                totalRead += readCount;

                // Stall the consumer for longer than the idle timeout a handful of times. Before the fix the
                // connection was closed during the very first of these pauses.
                if (pausesTaken < PAUSED_READS) {
                    pausesTaken++;
                    LOG.debug("Pausing the consumer after reading {} bytes", totalRead);
                    Thread.sleep(CONSUMER_PAUSE);
                }
            }
        }

        assertEquals(totalRead, RESPONSE_SIZE, "Response body was truncated");
        assertEquals(received, expected, "Response body content does not match what the server sent");
    }

    @AfterClass(timeOut = CLEAN_UP_TIME_OUT)
    public void cleanUp() throws ServerConnectorException {
        try {
            httpServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Failed to shutdown the test server");
        }
    }
}
