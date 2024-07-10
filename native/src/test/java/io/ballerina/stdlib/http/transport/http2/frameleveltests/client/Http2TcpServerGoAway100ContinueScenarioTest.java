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

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
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

import static io.ballerina.stdlib.http.transport.contract.Constants
        .REMOTE_SERVER_SENT_GOAWAY_WHILE_READING_INBOUND_RESPONSE_HEADERS;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_01;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp server sends a GoAway for a single request when in 100-continue state.
 */
public class Http2TcpServerGoAway100ContinueScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAway100ContinueScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;

    @BeforeMethod
    public void setup(Method method) throws InterruptedException {
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayFor100ContinueForASingleStream() {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        try {
            CountDownLatch latch = new CountDownLatch(1);
            HttpCarbonMessage httpsPostReq = TestUtil.
                    createHttpsPostReq(TestUtil.HTTP_SERVER_PORT, "hello", "/");
            httpsPostReq.addHeader("Expect", "100-continue");
            DefaultHttpConnectorListener requestListener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = h2ClientWithPriorKnowledge.send(httpsPostReq);
            responseFuture.setHttpConnectorListener(requestListener);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            assertEquals(getErrorResponseMessage(requestListener),
                    REMOTE_SERVER_SENT_GOAWAY_WHILE_READING_INBOUND_RESPONSE_HEADERS);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    private void runTcpServer(int port) {
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
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_01);
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
