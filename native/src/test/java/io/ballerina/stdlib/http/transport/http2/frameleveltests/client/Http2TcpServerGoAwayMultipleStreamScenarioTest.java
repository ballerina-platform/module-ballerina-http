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
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getResponseMessage;
import static org.testng.Assert.assertEqualsNoOrder;

/**
 * This contains a test case where the tcp server sends a GoAway for a stream in a multiple stream scenario.
 */
public class Http2TcpServerGoAwayMultipleStreamScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAwayMultipleStreamScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayWhenReceivingHeadersInAMultipleStreamScenario() {
        CountDownLatch latch = new CountDownLatch(4);
        DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
        DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
        DefaultHttpConnectorListener msgListener3 = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
        DefaultHttpConnectorListener msgListener4 = TestUtil.sendRequestAsync(latch, h2ClientWithPriorKnowledge);
        try {
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }

        Object responseValOrError1 = msgListener1.getHttpResponseMessage() == null ?
                getErrorResponseMessage(msgListener1) : getResponseMessage(msgListener1);
        Object responseValOrError2 = msgListener2.getHttpResponseMessage() == null ?
                getErrorResponseMessage(msgListener2) : getResponseMessage(msgListener2);
        Object responseValOrError3 = msgListener3.getHttpResponseMessage() == null ?
                getErrorResponseMessage(msgListener3) : getResponseMessage(msgListener3);
        Object responseValOrError4 = msgListener4.getHttpResponseMessage() == null ?
                getErrorResponseMessage(msgListener4) : getResponseMessage(msgListener4);
        assertEqualsNoOrder(List.of(responseValOrError1, responseValOrError2, responseValOrError3, responseValOrError4),
                List.of(FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_03, FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_05,
                FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_07,
                        Constants.REMOTE_SERVER_SENT_GOAWAY_BEFORE_INITIATING_INBOUND_RESPONSE));
    }

    private void runTcpServer(int port) {
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                Socket clientSocket = serverSocket.accept();
                LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                try (OutputStream outputStream = clientSocket.getOutputStream()) {
                    sendGoAwayForASingleStreamInAMultipleStreamScenario(outputStream);
                } catch (Exception e) {
                    LOGGER.error(e.getMessage());
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAwayForASingleStreamInAMultipleStreamScenario(OutputStream outputStream)
            throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_05);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_05);
        outputStream.write(FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_07);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        // Sending the frames for higher streams to check whether client correctly ignores them.
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_09);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_09);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        // Sending the frames for lower streams to check whether client correctly accepts them.
        outputStream.write(FrameLevelTestUtils.CLIENT_HEADER_FRAME_STREAM_07);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_07);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.END_SLEEP_TIME);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
