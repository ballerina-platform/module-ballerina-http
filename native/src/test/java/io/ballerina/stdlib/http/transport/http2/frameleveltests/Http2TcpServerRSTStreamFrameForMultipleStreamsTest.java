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
import io.netty.handler.codec.http.HttpContent;
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
import java.util.concurrent.Semaphore;

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.DATA_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.HEADER_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.RST_STREAM_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.RST_STREAM_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.TestUtils.SLEEP_TIME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the tcp server sends a successful response.
 */
public class Http2TcpServerRSTStreamFrameForMultipleStreamsTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2TcpServerRSTStreamFrameForMultipleStreamsTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    Semaphore readSemaphore = new Semaphore(0);
    Semaphore writeSemaphore = new Semaphore(0);
    private ServerSocket serverSocket;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = TestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testRSTStreamFrameForMultipleStreams() {
        HttpCarbonMessage httpCarbonMessage1 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage2 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage3 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            DefaultHttpConnectorListener msgListener1 = new DefaultHttpConnectorListener(new CountDownLatch(1));
            HttpResponseFuture responseFuture1 = h2ClientWithPriorKnowledge.send(httpCarbonMessage1);
            responseFuture1.setHttpConnectorListener(msgListener1);
            writeSemaphore.release();
            readSemaphore.acquire();
            DefaultHttpConnectorListener msgListener2 = new DefaultHttpConnectorListener(new CountDownLatch(1));
            HttpResponseFuture responseFuture2 = h2ClientWithPriorKnowledge.send(httpCarbonMessage2);
            responseFuture2.setHttpConnectorListener(msgListener2);
            writeSemaphore.release();
            readSemaphore.acquire();
            DefaultHttpConnectorListener msgListener3 = new DefaultHttpConnectorListener(new CountDownLatch(1));
            HttpResponseFuture responseFuture3 = h2ClientWithPriorKnowledge.send(httpCarbonMessage3);
            responseFuture3.setHttpConnectorListener(msgListener3);
            writeSemaphore.release();
            readSemaphore.acquire();
            responseFuture1.sync();
            responseFuture2.sync();
            responseFuture3.sync();
            Throwable throwable = responseFuture1.getStatus().getCause();
            if (throwable != null) {
                assertEquals(throwable.getMessage(),
                        Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE);
            } else {
//                HttpContent content1 = msgListener1.getHttpResponseMessage().getHttpContent();
//                if (content1 != null) {
//                    assertEquals(content1.decoderResult().cause().getMessage(),
//                            Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
//                } else {
                    fail("Expected an error");
//                }
            }
            HttpContent content2 = msgListener2.getHttpResponseMessage().getHttpContent();
            assertEquals(content2.content().toString(CharsetUtil.UTF_8), "hello world5");
            HttpContent content3 = msgListener3.getHttpResponseMessage().getHttpContent();
            if (content3 != null) {
                assertEquals(content3.decoderResult().cause().getMessage(),
                        Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
            } else {
                fail("Expected http content");
            }
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
                    sendRSTStream(outputStream);
                } catch (Exception e) {
                    LOGGER.error(e.getMessage());
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            } finally {
                readSemaphore.release();
                writeSemaphore.release();
            }
        }).start();
    }

    // This will send an RST_STREAM frame for stream 3 before sending headers and a successful response for
    // stream 5 and an RST_STREAM frame for stream 7 after sending headers
    private void sendRSTStream(OutputStream outputStream) throws IOException, InterruptedException {
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        writeSemaphore.acquire();
        outputStream.write(RST_STREAM_FRAME_STREAM_03);
        readSemaphore.release();
        Thread.sleep(SLEEP_TIME);
        writeSemaphore.acquire();
        outputStream.write(HEADER_FRAME_STREAM_05);
        outputStream.write(DATA_FRAME_STREAM_05);
        Thread.sleep(SLEEP_TIME);
        readSemaphore.release();
        writeSemaphore.acquire();
        outputStream.write(HEADER_FRAME_STREAM_07);
        outputStream.write(RST_STREAM_FRAME_STREAM_07);
        readSemaphore.release();
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
