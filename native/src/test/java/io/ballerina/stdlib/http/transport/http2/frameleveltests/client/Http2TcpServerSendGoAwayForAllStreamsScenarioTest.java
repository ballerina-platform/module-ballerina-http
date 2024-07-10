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

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils
        .DATA_FRAME_STREAM_03_DIFFERENT_DATA;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_04;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.util.TestUtil.getResponseMessage;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the client sends a request after receiving a GoAway.
 * This tests whether there is a new connection opened from the client.
 */
public class Http2TcpServerSendGoAwayForAllStreamsScenarioTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2TcpServerSendGoAwayForAllStreamsScenarioTest.class);

    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerSocket serverSocket;
    Semaphore semaphore = new Semaphore(0);

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayForAllStreamsScenario() {
        try {
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            DefaultHttpConnectorListener msgListener3 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            DefaultHttpConnectorListener msgListener4 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            DefaultHttpConnectorListener msgListener5 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            DefaultHttpConnectorListener msgListener6 = TestUtil.sendRequestAsync(null, h2ClientWithPriorKnowledge);
            semaphore.acquire();
            assertEquals(getResponseMessage(msgListener1), DATA_VALUE_HELLO_WORLD_03);
            assertEquals(getResponseMessage(msgListener2), DATA_VALUE_HELLO_WORLD_04);
            assertEquals(getResponseMessage(msgListener3), DATA_VALUE_HELLO_WORLD_03);
            assertEquals(getResponseMessage(msgListener4), DATA_VALUE_HELLO_WORLD_04);
            assertEquals(getResponseMessage(msgListener5), DATA_VALUE_HELLO_WORLD_03);
            assertEquals(getResponseMessage(msgListener6), DATA_VALUE_HELLO_WORLD_04);
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
            fail();
        }
    }

    private void runTcpServer(int port) {
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                int numberOfConnections = 0;
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                while (numberOfConnections < 6) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream()) {
                        if (numberOfConnections % 2 == 0) {
                            sendGoAwayBeforeSendingHeaders(outputStream);
                        } else {
                            sendGoAwayAfterSendingHeaders(outputStream);
                        }
                        numberOfConnections += 1;
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage());
                    }
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void sendGoAwayBeforeSendingHeaders(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_03);
        outputStream.write(HEADER_FRAME_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_03);
        semaphore.release();
        Thread.sleep(END_SLEEP_TIME);
    }

    private void sendGoAwayAfterSendingHeaders(OutputStream outputStream) throws IOException, InterruptedException {
        outputStream.write(SETTINGS_FRAME);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(HEADER_FRAME_STREAM_03);
        outputStream.write(GO_AWAY_FRAME_MAX_STREAM_03);
        Thread.sleep(SLEEP_TIME);
        outputStream.write(DATA_FRAME_STREAM_03_DIFFERENT_DATA);
        semaphore.release();
        Thread.sleep(END_SLEEP_TIME);
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
