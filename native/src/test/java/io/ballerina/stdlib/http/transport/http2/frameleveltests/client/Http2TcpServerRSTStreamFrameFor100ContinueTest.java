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
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
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
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp server sends a RST Stream when in 100-continue state.
 */
public class Http2TcpServerRSTStreamFrameFor100ContinueTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerRSTStreamFrameFor100ContinueTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testRSTStreamFrameFor100ContinueScenario() {
        CountDownLatch latch = new CountDownLatch(1);
        HttpCarbonMessage httpsPostReq = TestUtil.
                createHttpsPostReq(TestUtil.HTTP_SERVER_PORT, "hello", "/");
        httpsPostReq.addHeader("Expect", "100-continue");
        DefaultHttpConnectorListener requestListener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = h2ClientWithPriorKnowledge.send(httpsPostReq);
        responseFuture.setHttpConnectorListener(requestListener);
        try {
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
        assertEquals(getErrorResponseMessage(requestListener),
                Constants.REMOTE_SERVER_SENT_RST_STREAM_WHILE_READING_INBOUND_RESPONSE_HEADERS);
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
            }
        }).start();
    }

    private void sendRSTStream(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.RST_STREAM_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
