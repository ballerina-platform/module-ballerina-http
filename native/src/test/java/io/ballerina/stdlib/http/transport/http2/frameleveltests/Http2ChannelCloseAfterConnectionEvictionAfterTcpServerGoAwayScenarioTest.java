/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.http2.frameleveltests;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getDecoderErrorMessage;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the tcp server sends a GoAway and the connection gets closed from the
 * server side after an eviction occurs. The successfulness of this test case cannot be confirmed by the assert
 * completely. We have to look at the logs in order to check whether there are any internal netty exceptions
 */
public class Http2ChannelCloseAfterConnectionEvictionAfterTcpServerGoAwayScenarioTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2ChannelCloseAfterConnectionEvictionAfterTcpServerGoAwayScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;

    public HttpClientConnector setupHttp2PriorKnowledgeClient(long minIdleTimeInStaleState,
                                                              long timeBetweenStaleEviction) {
        HttpWsConnectorFactory connectorFactory = new DefaultHttpWsConnectorFactory();
        PoolConfiguration poolConfiguration = new PoolConfiguration();
        poolConfiguration.setMinIdleTimeInStaleState(minIdleTimeInStaleState);
        poolConfiguration.setTimeBetweenStaleEviction(timeBetweenStaleEviction);
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setPoolConfiguration(poolConfiguration);
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test
    private void testChannelCloseAfterConnectionEvictionScenario() {
        try {
            runTcpServer(TestUtil.HTTP_SERVER_PORT);
            h2ClientWithPriorKnowledge = setupHttp2PriorKnowledgeClient(3000, 1000);
            CountDownLatch latch1 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            // Waiting more than the minIdleTimeInStaleState to trigger a connectionEviction try and a channelInactive
            Thread.sleep(8000);

            String errorMsg1 = getDecoderErrorMessage(msgListener1);
            assertEquals(errorMsg1, REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
        } catch (InterruptedException | IOException e) {
            LOGGER.error("Exception occurred");
            fail();
        }
    }

    private void runTcpServer(int port) throws IOException {
        if (serverSocket != null) {
            serverSocket.close();
        }
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                Socket clientSocket = serverSocket.accept();
                LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                try (OutputStream outputStream = clientSocket.getOutputStream()) {
                    sendGoAwayForASingleStream(outputStream);
                } catch (Exception e) {
                    LOGGER.error(e.getMessage());
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAwayForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(SETTINGS_FRAME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        // This will move the connection to the stale connections list
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_05);
        // Waiting more than the time of `minIdleTimeInStaleState` and exit the socket write to trigger a
        // `channelInactive` after minIdleTime exceeds.
        Thread.sleep(5000);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
