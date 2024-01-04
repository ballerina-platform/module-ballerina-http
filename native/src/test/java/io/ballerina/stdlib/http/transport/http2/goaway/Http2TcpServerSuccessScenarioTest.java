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

package io.ballerina.stdlib.http.transport.http2.goaway;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp server sends a successful response.
 */
public class Http2TcpServerSuccessScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerSuccessScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;

    @BeforeClass
    public void setup() throws InterruptedException {
        startTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = GoAwayTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testSuccessfulConnection() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = h2ClientWithPriorKnowledge.send(httpCarbonMessage);
            responseFuture.setHttpConnectorListener(msgListener);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture.sync();
            HttpContent content = msgListener.getHttpResponseMessage().getHttpContent();
            assertEquals(content.content().toString(CharsetUtil.UTF_8), "hello world");
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    private void startTcpServer(int port) {
        new Thread(() -> {
            ServerSocket serverSocket;
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                while (true) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream()) {
                        sendSuccessfulResponse(outputStream);
                        break;
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage());
                    }
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private static void sendSuccessfulResponse(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        LOGGER.info("Wrote settings frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});
        Thread.sleep(100);
        LOGGER.info("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame with status 200");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        Thread.sleep(100);
        LOGGER.info("Writing data frame with hello world");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64});
        Thread.sleep(100);
    }
}
