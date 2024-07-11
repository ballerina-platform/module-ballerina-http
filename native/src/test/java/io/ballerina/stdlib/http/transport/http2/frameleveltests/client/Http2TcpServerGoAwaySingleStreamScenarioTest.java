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
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getResponseMessage;
import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp server sends a GoAway for a single request.
 */
public class Http2TcpServerGoAwaySingleStreamScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAwaySingleStreamScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;

    @BeforeMethod
    public void setup(Method method) throws InterruptedException {
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test (description = "In this, server sends headers and data for the accepted stream")
    private void testGoAwayWhenReceivingHeadersForASingleStream() {
        runTcpServer(TestUtil.HTTP_SERVER_PORT, 1);
        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            assertEquals(getResponseMessage(msgListener), FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_03);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    @Test (description = "In this, server exits without sending the headers and data for the accepted stream as well")
    private void testGoAwayAndServerExitWhenReceivingHeadersForASingleStream() {
        runTcpServer(TestUtil.HTTP_SERVER_PORT, 2);
        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener msgListener = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
        try {
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
        assertEquals(getErrorResponseMessage(msgListener),
                Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE);
    }

    private void runTcpServer(int port, int option) {
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                Socket clientSocket = serverSocket.accept();
                LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                try (OutputStream outputStream = clientSocket.getOutputStream()) {
                    if (option == 1) {
                        sendGoAwayForASingleStream(outputStream);
                    } else {
                        sendGoAwayAndExitForASingleStream(outputStream);
                    }
                } catch (Exception e) {
                    LOGGER.error(e.getMessage());
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAwayAndExitForASingleStream(OutputStream outputStream)
            throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_03);
        // Once the sleep time elapses, channel inactive of client gets fired.
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
    }

    private void sendGoAwayForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
