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

package io.ballerina.stdlib.http.transport.http2.frameleveltests;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.GO_AWAY_FRAME_MAX_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SLEEP_TIME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the client sends a request after receiving a GoAway.
 * This tests whether there is a new connection opened from the client.
 */
public class Http2TcpServerSendRequestAfterGoAwayScenarioTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2TcpServerSendRequestAfterGoAwayScenarioTest.class);

    private HttpClientConnector h2ClientWithPriorKnowledge;
    private AtomicInteger numberOfConnections = new AtomicInteger(0);
    private ServerSocket serverSocket;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = TestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testNewRequestAfterGoAwayReceivedScenario() {
        HttpCarbonMessage httpCarbonMessage1 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage2 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch1 = new CountDownLatch(1);
            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener1 = new DefaultHttpConnectorListener(latch1);
            HttpResponseFuture responseFuture1 = h2ClientWithPriorKnowledge.send(httpCarbonMessage1);
            responseFuture1.setHttpConnectorListener(msgListener1);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture1.sync();
            DefaultHttpConnectorListener msgListener2 = new DefaultHttpConnectorListener(latch2);
            HttpResponseFuture responseFuture2 = h2ClientWithPriorKnowledge.send(httpCarbonMessage2);
            responseFuture2.setHttpConnectorListener(msgListener2);
            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture2.sync();
            Throwable responseError = responseFuture1.getStatus().getCause();
            if (responseError != null) {
                assertEquals(responseError.getMessage(),
                        Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE);
            } else {
                fail("Expected error not received");
            }
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();
            assertEquals(response2.getHttpContent().content().toString(CharsetUtil.UTF_8), "hello world3");
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    private void runTcpServer(int port) {
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                while (true) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream()) {
                        if (numberOfConnections.get() == 0) {
                            sendGoAway(outputStream);
                            numberOfConnections.set(1);
                        } else if (numberOfConnections.get() == 1) {
                            sendSuccessfulResponse(outputStream);
                            break;
                        } else {
                            break;
                        }
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage());
                    }
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAway(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_03);
        Thread.sleep(END_SLEEP_TIME);
    }

    private void sendSuccessfulResponse(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_03);
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
