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
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.Semaphore;

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.RST_STREAM_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.RST_STREAM_FRAME_STREAM_07;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getDecoderErrorMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getResponseMessage;
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
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testRSTStreamFrameForMultipleStreams() {
        try {
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            writeSemaphore.release();
            readSemaphore.acquire();
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            writeSemaphore.release();
            readSemaphore.acquire();
            DefaultHttpConnectorListener msgListener3 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            writeSemaphore.release();
            readSemaphore.acquire();
            assertEquals(getErrorResponseMessage(msgListener1),
                    Constants.REMOTE_SERVER_SENT_RST_STREAM_BEFORE_INITIATING_INBOUND_RESPONSE);
            assertEquals(getResponseMessage(msgListener2), DATA_VALUE_HELLO_WORLD_05);
            assertEquals(getDecoderErrorMessage(msgListener3),
                    Constants.REMOTE_SERVER_SENT_RST_STREAM_WHILE_READING_INBOUND_RESPONSE_BODY);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
            fail();
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
        Thread.sleep(SLEEP_TIME);
        outputStream.write(RST_STREAM_FRAME_STREAM_07);
        Thread.sleep(SLEEP_TIME);
        readSemaphore.release();
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
