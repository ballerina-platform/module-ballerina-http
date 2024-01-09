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

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_09;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.GO_AWAY_FRAME_MAX_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_09;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SLEEP_TIME;
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
        h2ClientWithPriorKnowledge = TestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayWhenReceivingHeadersInAMultipleStreamScenario() {
        HttpCarbonMessage httpCarbonMessage1 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage2 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage3 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage4 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch = new CountDownLatch(4);
            DefaultHttpConnectorListener msgListener1 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture1 = h2ClientWithPriorKnowledge.send(httpCarbonMessage1);
            responseFuture1.setHttpConnectorListener(msgListener1);
            DefaultHttpConnectorListener msgListener2 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture2 = h2ClientWithPriorKnowledge.send(httpCarbonMessage2);
            responseFuture2.setHttpConnectorListener(msgListener2);
            DefaultHttpConnectorListener msgListener3 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture3 = h2ClientWithPriorKnowledge.send(httpCarbonMessage3);
            responseFuture3.setHttpConnectorListener(msgListener3);
            DefaultHttpConnectorListener msgListener4 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture4 = h2ClientWithPriorKnowledge.send(httpCarbonMessage4);
            responseFuture4.setHttpConnectorListener(msgListener4);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture1.sync();
            responseFuture2.sync();
            responseFuture3.sync();
            responseFuture4.sync();
            HttpCarbonMessage response1 = msgListener1.getHttpResponseMessage();
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();
            HttpCarbonMessage response3 = msgListener3.getHttpResponseMessage();
            HttpCarbonMessage response4 = msgListener4.getHttpResponseMessage();
            Object responseValOrError1 = response1 == null ? responseFuture1.getStatus().getCause().getMessage() :
                    response1.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError2 = response2 == null ? responseFuture2.getStatus().getCause().getMessage() :
                    response2.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError3 = response3 == null ? responseFuture3.getStatus().getCause().getMessage() :
                    response3.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError4 = response4 == null ? responseFuture4.getStatus().getCause().getMessage() :
                    response4.getHttpContent().content().toString(CharsetUtil.UTF_8);
            assertEqualsNoOrder(List.of(responseValOrError1, responseValOrError2, responseValOrError3,
                    responseValOrError4), List.of("hello world3", "hello world5", "hello world7",
                    Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE));
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
        outputStream.write(SETTINGS_FRAME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_05);
        outputStream.write(DATA_FRAME_STREAM_05);
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_07);
        Thread.sleep(SLEEP_TIME);
        // Sending the frames for higher streams to check whether client correctly ignores them.
        outputStream.write(HEADER_FRAME_STREAM_09);
        outputStream.write(DATA_FRAME_STREAM_09);
        Thread.sleep(SLEEP_TIME);
        // Sending the frames for lower streams to check whether client correctly accepts them.
        outputStream.write(HEADER_FRAME_STREAM_07);
        outputStream.write(DATA_FRAME_STREAM_07);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_03);
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
