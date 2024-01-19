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
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_FRAME_STREAM_03_DIFFERENT_DATA;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.DATA_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.END_SLEEP_TIME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_03;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.HEADER_FRAME_STREAM_05;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK;
import static io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils.SLEEP_TIME;
import static org.testng.Assert.assertEqualsNoOrder;
import static org.testng.Assert.fail;

/**
 * This contains a test case where the tcp server sends a GoAway and the connection gets timed out from client side.
 */
public class Http2ServerAbruptClosureInUpgradeScenarioTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(Http2ServerAbruptClosureInUpgradeScenarioTest.class);
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
        poolConfiguration.setMinEvictableIdleTime(5000);
        poolConfiguration.setTimeBetweenEvictionRuns(1000);
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setPoolConfiguration(poolConfiguration);
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(false);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test
    private void testServerAbruptClosureInUpgradeScenario() {
        try {
            CountDownLatch latch1 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch1, h2ClientWithPriorKnowledge);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(latch2, h2ClientWithPriorKnowledge);
            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            HttpCarbonMessage response1 = msgListener1.getHttpResponseMessage();
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();

            Object responseVal1 = response1.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseVal2 = response2.getHttpContent().content().toString(CharsetUtil.UTF_8);

            assertEqualsNoOrder(List.of(responseVal1, responseVal2),
                    List.of("hello world3", "hello world4"));
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
                while (numOfConnections < 2) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream();
                         InputStream inputStream = clientSocket.getInputStream()) {
                        readSocketAndExit(inputStream);
                    } catch (Exception e) {
                        LOGGER.error(e.getMessage());
                    }
                }
            } catch (IOException e) {
                LOGGER.error(e.getMessage());
            }
        }).start();
    }

    private void readSocketAndExit(InputStream inputStream) throws IOException {
        byte[] buffer = new byte[4096];
        int bytesRead = 0;
        try {
            Thread.sleep(1000);
            bytesRead = inputStream.read(buffer);
        } catch (Exception e) {
            e.printStackTrace();
        }
        String data = new String(buffer, 0, bytesRead);
        System.out.println("Received data: " + data);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithPriorKnowledge.close();
        serverSocket.close();
    }
}
