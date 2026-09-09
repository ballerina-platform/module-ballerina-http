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

package io.ballerina.stdlib.http.transport.http2.clienttimeout;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.http2.listeners.Http2ServerLargeResponseListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.InputStream;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.Http2Util.getHttp2Client;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that {@code maxBackPressureStallTime} is a genuine ceiling on an HTTP/2 stream that is permanently
 * stalled by flow control, not just one that is slow and eventually resumes like
 * {@link Http2SlowInboundResponseBodyConsumerTestCase}.
 */
public class Http2ClientBackPressureStallLimitTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2ClientBackPressureStallLimitTestCase.class);

    // Comfortably larger than the default 64KB inbound flow control window.
    private static final int RESPONSE_SIZE = 1024 * 1024;
    private static final int SOCKET_IDLE_TIMEOUT = 2000;
    private static final double MAX_BACK_PRESSURE_STALL_SECONDS = 0.4;
    private static final int READ_SLICE = 16 * 1024;
    // Past SOCKET_IDLE_TIMEOUT + (MAX_BACK_PRESSURE_STALL_SECONDS * 1000) = 2400ms, well short of what a
    // bypassed cap would need (the stream would never be reclaimed at all).
    private static final int CONSUMER_PAUSE = 2600;
    private static final long RECLAIM_DEADLINE_MILLIS = 3200;
    // A regression here is a permanently stalled read rather than a quick error, so the test method is bounded
    // to keep a failure a red test instead of a hung build.
    private static final int TEST_TIME_OUT = 60000;
    // Tearing down a connection whose stream was just reset with a large amount of still-buffered outbound
    // data can take noticeably longer on some platforms (observed on Windows CI) than on others, so this is
    // generous rather than tight.
    private static final int CLEAN_UP_TIME_OUT = 60000;

    private HttpClientConnector h2Client;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        Util.setMaxBackPressureStallTime(MAX_BACK_PRESSURE_STALL_SECONDS);

        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        // Keep the server well out of the way, the client side timing is what is under test.
        listenerConfiguration.setSocketIdleTimeout(500000);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new Http2ServerLargeResponseListener(RESPONSE_SIZE));
        future.sync();

        h2Client = getHttp2Client(connectorFactory, true, SOCKET_IDLE_TIMEOUT);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A stream that never resumes reading after stalling must still be reclaimed once the "
                  + "configured cap elapses, rather than being excused forever")
    public void testPermanentlyStalledStreamIsReclaimed() throws Exception {
        HttpCarbonMessage request = MessageGenerator.generateRequest(HttpMethod.POST, "test");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = h2Client.send(request);
        responseFuture.setHttpConnectorListener(listener);

        assertTrue(latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS),
                   "Did not receive the response headers");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Response message is null: " + listener.getHttpErrorMessage());

        byte[] received = new byte[RESPONSE_SIZE];
        int totalRead = 0;
        long stallStartMillis;

        try (InputStream inputStream = new HttpMessageDataStreamer(response).getInputStream()) {
            int firstRead = inputStream.read(received, 0, READ_SLICE);
            assertTrue(firstRead > 0, "Expected to read some content before stalling");
            totalRead += firstRead;
            stallStartMillis = System.currentTimeMillis();

            // Deliberately not read again until the pause has elapsed: any read here reopens the window
            // and lets the transfer continue, masking the very stall the cap is meant to bound.
            LOG.debug("Stalling the consumer for {}ms, well past the {}s back-pressure stall cap",
                       CONSUMER_PAUSE, MAX_BACK_PRESSURE_STALL_SECONDS);
            Thread.sleep(CONSUMER_PAUSE);

            // Only content queued before the stall began can still be drained here; once that runs out
            // the stream must already have been reclaimed and reset independently of any read of ours.
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
                LOG.debug("Reading failed as expected once the reclaimed stream's content ran out: {}",
                           e.getMessage());
            }
        }

        long reclaimDurationMillis = System.currentTimeMillis() - stallStartMillis;
        assertTrue(totalRead < RESPONSE_SIZE,
                   "Response body was not truncated even though the consumer stalled past the configured "
                           + "maxBackPressureStallTime cap - the flow control window must have reopened and let "
                           + "the transfer continue");
        assertTrue(reclaimDurationMillis < RECLAIM_DEADLINE_MILLIS,
                   "Stream was not reclaimed until " + reclaimDurationMillis + "ms into the stall - if this "
                           + "matches the test timeout instead, the stall was excused indefinitely");
    }

    // alwaysRun: setup() applies the shortened stall cap before it can fail (e.g. a port still in TIME_WAIT),
    // and that global setting must not leak into later test classes even when setup() never finishes.
    @AfterClass(alwaysRun = true, timeOut = CLEAN_UP_TIME_OUT)
    public void cleanUp() {
        // Restore the default so this global setting does not leak into other test classes.
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
        if (h2Client != null) {
            h2Client.close();
        }
        if (serverConnector != null) {
            serverConnector.stop();
        }
        try {
            if (connectorFactory != null) {
                connectorFactory.shutdown();
            }
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
