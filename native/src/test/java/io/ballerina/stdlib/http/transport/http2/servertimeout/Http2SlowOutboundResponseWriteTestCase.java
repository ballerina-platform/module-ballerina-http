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

package io.ballerina.stdlib.http.transport.http2.servertimeout;

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
 * Verifies that an HTTP/2 server writing a large response to a slow client is not timed out by its own stream
 * timer.
 *
 * <p>This is the outbound counterpart of the inbound flow control cases. When the client is the slow consumer
 * its window closes, and the response the server has already produced sits queued in the remote flow
 * controller waiting to go out. No frames are written while that lasts, so the stream looks idle to the server
 * even though it has data ready and the client is the one holding it up. Acting on that apparent idleness made
 * the server send RST_STREAM, which the client surfaced as a prematurely closed response stream.
 *
 * <p>Note that the server idle timeout must be short here and the client timeout long: the reverse
 * arrangement, used by the inbound tests, keeps the server timer out of the picture entirely and cannot catch
 * this.
 */
public class Http2SlowOutboundResponseWriteTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2SlowOutboundResponseWriteTestCase.class);

    // Large enough that the server cannot hand the whole response to the encoder before the client's window
    // closes. A response small enough to be written in one go completes the stream and cancels the timer,
    // which is exactly why smaller payloads never showed this.
    private static final int RESPONSE_SIZE = 32 * 1024 * 1024;
    private static final int SERVER_IDLE_TIMEOUT = 2000;
    private static final int READ_SLICE = 16 * 1024;
    private static final int CONSUMER_PAUSE = SERVER_IDLE_TIMEOUT * 2;
    private static final int PAUSED_READS = 3;

    private HttpClientConnector h2PriorOnClient;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setSocketIdleTimeout(SERVER_IDLE_TIMEOUT);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new Http2ServerLargeResponseListener(RESPONSE_SIZE));
        future.sync();

        // Keep the client well out of the way, the server side timing is what is under test.
        h2PriorOnClient = getHttp2Client(connectorFactory, true, 500000);
    }

    @Test(description = "A large response written to a slow client must not be reset by the server's own "
            + "stream timer, because the stream is quiet due to flow control rather than a stalled peer.")
    public void testSlowlyReadResponseIsNotResetByServer() throws Exception {
        HttpCarbonMessage request = MessageGenerator.generateRequest(HttpMethod.POST, "test");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = h2PriorOnClient.send(request);
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

    @AfterClass
    public void cleanUp() {
        h2PriorOnClient.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
