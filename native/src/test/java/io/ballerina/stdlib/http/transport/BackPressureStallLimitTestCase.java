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
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
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

import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that {@code maxBackPressureStallTime} is checked on its own schedule rather than only being noticed
 * the next time the full socket idle timeout happens to elapse.
 *
 * <p>The socket idle timeout here is deliberately larger than the configured stall cap. Netty's own idle
 * detection only rechecks once per socket idle timeout, so without a faster recheck of its own, a stall that
 * outlasts the cap but not twice the idle timeout would go unnoticed until that second period elapsed - close
 * to {@code SOCKET_IDLE_TIMEOUT * 2} - instead of close to {@code SOCKET_IDLE_TIMEOUT + cap}. The deadline
 * asserted below sits in between those two, so it fails if the faster recheck regresses back to Netty's own
 * coarser cadence.
 */
public class BackPressureStallLimitTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(BackPressureStallLimitTestCase.class);

    // Large enough to push the inbound content past the 2MB threshold at which reads are throttled.
    private static final int RESPONSE_SIZE = 4 * 1024 * 1024;
    private static final int SOCKET_IDLE_TIMEOUT = 2000;
    private static final double MAX_BACK_PRESSURE_STALL_SECONDS = 0.4;
    private static final int READ_SLICE = 64 * 1024;
    // Past SOCKET_IDLE_TIMEOUT + (MAX_BACK_PRESSURE_STALL_SECONDS * 1000) = 2400ms, so the cap should already
    // have been enforced by the time the consumer wakes up, but well short of SOCKET_IDLE_TIMEOUT * 2 = 4000ms.
    private static final int CONSUMER_PAUSE = 2600;
    // Comfortably above the ~2400ms the cap is expected to take, comfortably below the ~4000ms it would take
    // if the recheck fell back to Netty's own once-per-idle-timeout schedule.
    private static final long RECLAIM_DEADLINE_MILLIS = 3200;
    // A regression here shows up as a stalled transfer rather than a quick error, so the test methods and the
    // tear down are bounded to keep a failure a red test instead of a hung build.
    private static final int TEST_TIME_OUT = 60000;
    private static final int CLEAN_UP_TIME_OUT = 30000;

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        Util.setMaxBackPressureStallTime(MAX_BACK_PRESSURE_STALL_SECONDS);

        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT,
                                              new LargeResponseServerInitializer(RESPONSE_SIZE));

        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setSocketIdleTimeout(SOCKET_IDLE_TIMEOUT);
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A consumer stalled for longer than maxBackPressureStallTime must have its connection "
                  + "reclaimed once the cap elapses, rather than being excused until the socket idle timeout "
                  + "would separately have fired.")
    public void testStallPastCapIsReclaimed() throws Exception {
        HttpCarbonMessage msg = TestUtil.createHttpPostReq(TestUtil.HTTP_SERVER_PORT, "Test request body", "");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = httpClientConnector.send(msg);
        responseFuture.setHttpConnectorListener(listener);

        assertTrue(latch.await(10, TimeUnit.SECONDS), "Did not receive the response headers");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Response message is null: " + listener.getHttpErrorMessage());

        byte[] received = new byte[RESPONSE_SIZE];
        int totalRead = 0;
        long stallStartMillis = System.currentTimeMillis();

        try (InputStream inputStream = new HttpMessageDataStreamer(response).getInputStream()) {
            int firstRead = inputStream.read(received, 0, READ_SLICE);
            assertTrue(firstRead > 0, "Expected to read some content before stalling");
            totalRead += firstRead;

            LOG.debug("Stalling the consumer for {}ms, well past the {}s back-pressure stall cap",
                       CONSUMER_PAUSE, MAX_BACK_PRESSURE_STALL_SECONDS);
            Thread.sleep(CONSUMER_PAUSE);

            // Only content queued before the socket reads were suspended (capped well under RESPONSE_SIZE) can
            // still be drained here without blocking; once that is exhausted, the next read blocks until the
            // connection is reclaimed, either as a decode failure or as a plain end of stream.
            try {
                while (totalRead < RESPONSE_SIZE) {
                    int toRead = Math.min(READ_SLICE, RESPONSE_SIZE - totalRead);
                    int readCount = inputStream.read(received, totalRead, toRead);
                    if (readCount == -1) {
                        break;
                    }
                    totalRead += readCount;
                }
            } catch (RuntimeException e) {
                LOG.debug("Reading failed as expected once the reclaimed connection's content ran out: {}",
                           e.getMessage());
            }
        }

        long reclaimDurationMillis = System.currentTimeMillis() - stallStartMillis;
        assertTrue(totalRead < RESPONSE_SIZE,
                   "Response body was not truncated even though the consumer stalled past the configured "
                           + "maxBackPressureStallTime cap");
        assertTrue(reclaimDurationMillis < RECLAIM_DEADLINE_MILLIS,
                   "Connection was not reclaimed until " + reclaimDurationMillis + "ms into the stall, which is "
                           + "close to twice the socket idle timeout rather than close to the configured "
                           + "maxBackPressureStallTime cap");
    }

    @AfterClass(timeOut = CLEAN_UP_TIME_OUT)
    public void cleanUp() throws ServerConnectorException {
        // Restore the default so this global setting does not leak into other test classes.
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
        try {
            httpServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Failed to shutdown the test server");
        }
    }
}
