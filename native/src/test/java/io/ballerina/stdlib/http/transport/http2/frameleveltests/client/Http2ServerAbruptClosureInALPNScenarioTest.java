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
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.Http2Util;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.getErrorResponseMessage;
import static org.testng.Assert.fail;
import static org.testng.AssertJUnit.assertEquals;

/**
 * This contains a test case where the tcp server closes abruptly while the alpn upgrade is happening.
 */
public class Http2ServerAbruptClosureInALPNScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2ServerAbruptClosureInALPNScenarioTest.class);
    private HttpClientConnector h2ClientWithUpgrade;
    private ServerSocket serverSocket;
    private int numOfConnections = 0;

    @BeforeClass
    public void setup() throws InterruptedException {
        runTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithUpgrade = setupHttp2UpgradeClient();
    }

    public HttpClientConnector setupHttp2UpgradeClient() {
        HttpWsConnectorFactory connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = Http2Util.getSenderConfigs(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(false);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(new TransportsConfiguration()), senderConfiguration);
    }

    @Test
    private void testServerAbruptClosureInALPNScenario() {
        try {
            CountDownLatch latch1 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener1 = TestUtil.sendRequestAsync(latch1, h2ClientWithUpgrade);
            latch1.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            CountDownLatch latch2 = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener2 = TestUtil.sendRequestAsync(latch2, h2ClientWithUpgrade);
            latch2.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);

            assertEquals(getErrorResponseMessage(msgListener1),
                    "Remote host: localhost/127.0.0.1:9000 closed the connection while SSL handshake");
            assertEquals(getErrorResponseMessage(msgListener2),
                    "Remote host: localhost/127.0.0.1:9000 closed the connection while SSL handshake");
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
                    try (InputStream inputStream = clientSocket.getInputStream()) {
                        readSocketAndExit(inputStream);
                        numOfConnections += 1;
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
        // This will just read the socket input content and exit the socket without sending any response
        // which will trigger the channel inactive in the client side
        byte[] buffer = new byte[4096];
        int bytesRead = 0;
        try {
            bytesRead = inputStream.read(buffer);
        } catch (Exception exception) {
            LOGGER.error(exception.getMessage());
        }
        String data = new String(buffer, 0, bytesRead);
        LOGGER.info("Received ALPN request: " + data);
    }

    @AfterClass
    public void cleanUp() throws IOException {
        h2ClientWithUpgrade.close();
        serverSocket.close();
    }
}
