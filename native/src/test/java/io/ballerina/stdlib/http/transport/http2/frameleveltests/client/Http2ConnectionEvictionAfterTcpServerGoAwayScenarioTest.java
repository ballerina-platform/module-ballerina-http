/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.http2.frameleveltests.client;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.getDecoderErrorMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getResponseMessage;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertEqualsNoOrder;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the tcp server sends a GoAway and the connection gets timed out from client side.
 */
public class Http2ConnectionEvictionAfterTcpServerGoAwayScenarioTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2ConnectionEvictionAfterTcpServerGoAwayScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;
    private int numOfConnections = 0;

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
    private void testConnectionEvictionAfterAllStreamsAreClosedScenario() {
        try {
            runTcpServer(TestUtil.HTTP_SERVER_PORT);
            // Setting to -1 will make the runner to wait until all pending streams are completed
            h2ClientWithPriorKnowledge = setupHttp2PriorKnowledgeClient(-1, 1000);
            CountDownLatch latch1 = new CountDownLatch(2);
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener3 = TestUtil.sendRequestAsync(latch2, h2ClientWithPriorKnowledge);
            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            HttpCarbonMessage response1 = msgListener1.getHttpResponseMessage();
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();
            HttpCarbonMessage response3 = msgListener3.getHttpResponseMessage();

            Object responseVal1 = response1.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseVal2 = response2.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseVal3 = response3.getHttpContent().content().toString(CharsetUtil.UTF_8);

            assertEqualsNoOrder(List.of(responseVal1, responseVal2), List.of(
                    FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_03, FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_05));
            assertEquals(responseVal3, FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_04);
        } catch (InterruptedException | IOException e) {
            LOGGER.error("Exception occurred");
            fail();
        }
    }

    @Test
    private void testConnectionEvictionBeforeAllStreamsAreClosedScenario() {
        try {
            runTcpServer(TestUtil.HTTP_SERVER_PORT);
            h2ClientWithPriorKnowledge = setupHttp2PriorKnowledgeClient(5000, 1000);
            CountDownLatch latch1 = new CountDownLatch(2);
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener3 = TestUtil.sendRequestAsync(latch2, h2ClientWithPriorKnowledge);
            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            String errorMsg1 = msgListener1.getHttpErrorMessage() != null ? getErrorResponseMessage(msgListener1) :
                    getDecoderErrorMessage(msgListener1);
            String errorMsg2 = msgListener2.getHttpErrorMessage() != null ? getErrorResponseMessage(msgListener2) :
                    getDecoderErrorMessage(msgListener2);

            assertEqualsNoOrder(List.of(errorMsg1, errorMsg2),
                    List.of(Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE,
                            Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY));
            assertEquals(getResponseMessage(msgListener3), FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_04);
        } catch (InterruptedException | IOException e) {
            LOGGER.error("Exception occurred");
            fail();
        }
    }

    private void runTcpServer(int port) throws IOException {
        if (serverSocket != null) {
            serverSocket.close();
        }
        numOfConnections = 0;
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                while (numOfConnections < 2) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream()) {
                        if (numOfConnections == 0) {
                            sendGoAwayForASingleStream(outputStream);
                        } else {
                            // If the connection successfully closed, a new socket connection
                            // will be opened and it will come here
                            sendSuccessfulRequest(outputStream);
                        }
                        numOfConnections += 1;
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage());
                    }
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAwayForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        // This will move the connection to the stale connections list
        outputStream.write(FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_05);
        // Sleeping for 8 seconds and the timer task will check whether there are inflight message still
        // remaining in the channel.
        Thread.sleep(8000);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_03);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_05);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_05);
        // Once all the inflight messages are completed, the connection will be closed.
        Thread.sleep(8000);
    }

    private void sendSuccessfulRequest(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_03_DIFFERENT_DATA);
        Thread.sleep(FrameLevelTestUtils.END_SLEEP_TIME);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
