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

package io.ballerina.stdlib.http.transport.http2.frameleveltests.server;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.handler.codec.http.HttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_CLIENT_SENT_GOAWAY_WHILE_READING_INBOUND_REQUEST_BODY;
import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp connection is closed by the timer task before the stream gets completed.
 */
public class Http2ChannelCloseWhenConnectionEvictionAfterTcpClientGoAwayScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2ChannelCloseWhenConnectionEvictionAfterTcpClientGoAwayScenarioTest.class);
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    int errorCount = 0;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setTimeBetweenStaleEviction(500);
        listenerConfiguration.setMinIdleTimeInStaleState(1000);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new GoAwayMessageListener());
        future.sync();
    }

    @Test
    private void testChannelCloseWhenConnectionEvictionAfterClientGoAway() throws IOException, InterruptedException {
        Socket socket = new Socket("localhost", TestUtil.HTTP_SERVER_PORT);
        OutputStream outputStream = socket.getOutputStream();
        sendGoAwayAfterSendingHeaders(outputStream);
        Thread.sleep(2000);
        assertEquals(errorCount, 3);
    }

    public static void sendGoAwayAfterSendingHeaders(OutputStream outputStream) throws IOException, InterruptedException {
        System.out.println("Writing preface frame");
        outputStream.write(new byte[]{0x50, 0x52, 0x49, 0x20, 0x2a, 0x20, 0x48, 0x54, 0x54, 0x50, 0x2f, 0x32, 0x2e, 0x30, 0x0d, 0x0a, 0x0d, 0x0a, 0x53, 0x4d, 0x0d, 0x0a, 0x0d, 0x0a});// Sending setting frame with HEADER_TABLE_SIZE=25700
        System.out.println("Writing settings frame with header table size");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});// Sending setting frame with HEADER_TABLE_SIZE=25700
        Thread.sleep(100);
        System.out.println("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});
        Thread.sleep(100);
        System.out.println("Writing headers frame stream 03");
        outputStream.write(new byte[]{0x00, 0x00, (byte) 0x1b, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03, (byte) 0x44, (byte) 0x06, (byte) 0x2F, (byte) 0x68, (byte) 0x65, (byte) 0x6C, (byte) 0x6C, (byte) 0x6F, (byte) 0x83, (byte) 0x5F, (byte) 0x0A, (byte) 0x74, (byte) 0x65, (byte) 0x78, (byte) 0x74, (byte) 0x2F, (byte) 0x70, (byte) 0x6C, (byte) 0x61, (byte) 0x69, (byte) 0x6E, (byte) 0x7A, (byte) 0x04, (byte) 0x77, (byte) 0x73, (byte) 0x6F, (byte) 0x32});
        Thread.sleep(100);
        System.out.println("Writing headers frame stream 05");
        outputStream.write(new byte[]{0x00, 0x00, (byte) 0x1b, 0x01, 0x04, 0x00, 0x00, 0x00, 0x05, (byte) 0x44, (byte) 0x06, (byte) 0x2F, (byte) 0x68, (byte) 0x65, (byte) 0x6C, (byte) 0x6C, (byte) 0x6F, (byte) 0x83, (byte) 0x5F, (byte) 0x0A, (byte) 0x74, (byte) 0x65, (byte) 0x78, (byte) 0x74, (byte) 0x2F, (byte) 0x70, (byte) 0x6C, (byte) 0x61, (byte) 0x69, (byte) 0x6E, (byte) 0x7A, (byte) 0x04, (byte) 0x77, (byte) 0x73, (byte) 0x6F, (byte) 0x33});
        Thread.sleep(100);
        System.out.println("Writing a goaway frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0b});
        Thread.sleep(4000);
        // Sending data for stream 03 after 4 seconds which is more than the stale timeout
        System.out.println("Writing data frame stream 03");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64});
        Thread.sleep(8000);
    }

    @AfterClass
    public void cleanUp() {
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOGGER.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }

    class GoAwayMessageListener implements HttpConnectorListener {
        private ExecutorService executor = Executors.newSingleThreadExecutor();

        @Override
        public void onMessage(HttpCarbonMessage httpRequest) {
            executor.execute(() -> {
                HttpContent httpContent = httpRequest.getHttpContent();
                if (httpContent.decoderResult().isFailure()) {
                    String msg = httpContent.decoderResult().cause().getMessage();
                    if (msg.equals(REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY)) {
                        errorCount += 1;
                    } else if (msg.equals(REMOTE_CLIENT_SENT_GOAWAY_WHILE_READING_INBOUND_REQUEST_BODY)) {
                        errorCount += 2;
                    }
                }
            });
        }

        @Override
        public void onError(Throwable throwable) {}
    }
}
