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
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that an HTTP/2 client which consumes a large inbound response body slowly is not timed out.
 *
 * <p>On HTTP/2 the back-pressure is applied through the inbound flow control window rather than through
 * autoRead: {@code Http2InboundContentListener} only replenishes the window as the application consumes, so a
 * slow consumer causes the peer to stop sending. No data then arrives, and the per stream idle timer would
 * otherwise conclude that the peer has stalled and fail the response. The window defaults to 64KB, so this
 * kicks in far sooner than the HTTP/1.1 equivalent.
 */
public class Http2SlowInboundResponseBodyConsumerTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2SlowInboundResponseBodyConsumerTestCase.class);

    // Comfortably larger than the default 64KB inbound flow control window.
    private static final int RESPONSE_SIZE = 1024 * 1024;
    private static final int SOCKET_IDLE_TIMEOUT = 2000;
    private static final int READ_SLICE = 16 * 1024;
    private static final int CONSUMER_PAUSE = SOCKET_IDLE_TIMEOUT + SOCKET_IDLE_TIMEOUT / 2;
    private static final int PAUSED_READS = 2;
    // A regression here shows up as a stalled transfer rather than a quick error, so the test methods and the
    // tear down are bounded to keep a failure a red test instead of a hung build.
    private static final int TEST_TIME_OUT = 60000;
    private static final int CLEAN_UP_TIME_OUT = 30000;

    private HttpClientConnector h2PriorOnClient;
    private HttpClientConnector h2PriorOffClient;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
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

        h2PriorOnClient = getHttp2Client(connectorFactory, true, SOCKET_IDLE_TIMEOUT);
        h2PriorOffClient = getHttp2Client(connectorFactory, false, SOCKET_IDLE_TIMEOUT);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A slowly consumed HTTP/2 response body must arrive in full when prior knowledge is on")
    public void testSlowlyConsumedLargeResponseWithPriorOn() throws Exception {
        assertResponseIsNotTruncated(h2PriorOnClient);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A slowly consumed HTTP/2 response body must arrive in full when prior knowledge is off")
    public void testSlowlyConsumedLargeResponseWithPriorOff() throws Exception {
        assertResponseIsNotTruncated(h2PriorOffClient);
    }

    private void assertResponseIsNotTruncated(HttpClientConnector h2Client) throws Exception {
        HttpCarbonMessage request = MessageGenerator.generateRequest(HttpMethod.POST, "test");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = h2Client.send(request);
        responseFuture.setHttpConnectorListener(listener);

        assertTrue(latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS),
                   "Did not receive the response headers");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Response message is null: " + listener.getHttpErrorMessage());

        byte[] expected = Http2ServerLargeResponseListener.buildExpectedPayload(RESPONSE_SIZE);
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
    public void cleanUp() {
        h2PriorOnClient.close();
        h2PriorOffClient.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
