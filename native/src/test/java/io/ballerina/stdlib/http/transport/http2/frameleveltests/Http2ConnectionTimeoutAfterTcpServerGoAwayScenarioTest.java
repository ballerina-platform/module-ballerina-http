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
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
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
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_03_DIFFERENT_DATA;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.GO_AWAY_FRAME_MAX_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SLEEP_TIME;
import static org.testng.Assert.assertEqualsNoOrder;

/**
 * This contains a test case where the tcp server sends a GoAway and the connection gets timed out from client side.
 */
public class Http2ConnectionTimeoutAfterTcpServerGoAwayScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2ConnectionTimeoutAfterTcpServerGoAwayScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;
    private int numOfConnections = 0;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = setupHttp2PriorKnowledgeClient();
    }

    public HttpClientConnector setupHttp2PriorKnowledgeClient() {
        HttpWsConnectorFactory connectorFactory = new DefaultHttpWsConnectorFactory();
        PoolConfiguration poolConfiguration = new PoolConfiguration();
        poolConfiguration.setHttp2ConnectionIdleTimeout(5000);
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
    private void testConnectionTimeoutAfterServerGoAwayScenario() {
        HttpCarbonMessage httpCarbonMessage1 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage2 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage3 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch1 = new CountDownLatch(2);
            DefaultHttpConnectorListener msgListener1 = new DefaultHttpConnectorListener(latch1);
            HttpResponseFuture responseFuture1 = h2ClientWithPriorKnowledge.send(httpCarbonMessage1);
            responseFuture1.setHttpConnectorListener(msgListener1);

            DefaultHttpConnectorListener msgListener2 = new DefaultHttpConnectorListener(latch1);
            HttpResponseFuture responseFuture2 = h2ClientWithPriorKnowledge.send(httpCarbonMessage2);
            responseFuture2.setHttpConnectorListener(msgListener2);

            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture1.sync();
            responseFuture2.sync();

            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener3 = new DefaultHttpConnectorListener(latch2);
            HttpResponseFuture responseFuture3 = h2ClientWithPriorKnowledge.send(httpCarbonMessage3);
            responseFuture3.setHttpConnectorListener(msgListener3);

            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture3.sync();

            HttpCarbonMessage response1 = msgListener1.getHttpResponseMessage();
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();
            HttpCarbonMessage response3 = msgListener3.getHttpResponseMessage();

            Object responseVal1 = response1.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseVal2 = response2.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseVal3 = response3.getHttpContent().content().toString(CharsetUtil.UTF_8);
            assertEqualsNoOrder(List.of(responseVal1, responseVal2, responseVal3),
                    List.of("hello world3", "hello world5", "hello world5"));
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    private void runTcpServer(int port) {
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
                            numOfConnections += 1;
                        } else {
                            // If the connection successfully closed, a new socket connection
                            // will be opened and it will come here
                            sendSuccessfulRequest(outputStream);
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

    private void sendGoAwayForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(SETTINGS_FRAME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        // This will move the connection to the stale connections list
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_05);
        // Sleeping for 8 seconds and the timer task will check whether there are inflight message still
        // remaining in the channel.
        Thread.sleep(8000);
        outputStream.write(DATA_FRAME_STREAM_03);
        outputStream.write(HEADER_FRAME_STREAM_05);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_05);
        // Once all the inflight messages are completed, the connection will be closed.
        Thread.sleep(8000);
    }

    private void sendSuccessfulRequest(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(SETTINGS_FRAME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_03_DIFFERENT_DATA);
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
