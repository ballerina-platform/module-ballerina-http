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

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp client sends a successful response.
 */
public class Http2TcpClientSuccessScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpClientSuccessScenarioTest.class);
    static AtomicBoolean commDone = new AtomicBoolean(false);
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private String serverResponse = "";
    private Lock readLock = new ReentrantLock();

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
    }

    @Test
    private void testSuccessfulConnection() throws IOException, InterruptedException {
        Socket socket = new Socket("localhost", TestUtil.HTTP_SERVER_PORT);
        OutputStream outputStream = socket.getOutputStream();
        InputStream inputStream = socket.getInputStream();
        startReadingFromInputStream(inputStream);
        sendSuccessfulPriorKnowledgeRequest(outputStream);
        socket.close();
        readLock.lock();
        assertEquals(serverResponse, "hello world");
    }

    public static void sendSuccessfulPriorKnowledgeRequest(OutputStream outputStream) throws IOException, InterruptedException {
        System.out.println("Writing preface frame");
        outputStream.write(new byte[]{0x50, 0x52, 0x49, 0x20, 0x2a, 0x20, 0x48, 0x54, 0x54, 0x50, 0x2f, 0x32, 0x2e, 0x30, 0x0d, 0x0a, 0x0d, 0x0a, 0x53, 0x4d, 0x0d, 0x0a, 0x0d, 0x0a});// Sending setting frame with HEADER_TABLE_SIZE=25700

        System.out.println("Writing settings frame with header table size");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});// Sending setting frame with HEADER_TABLE_SIZE=25700

        Thread.sleep(1000);

        System.out.println("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});

        System.out.println("Writing headers frame");
        outputStream.write(new byte[]{0x00, 0x00, (byte) 0x1b, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03, (byte) 0x44, (byte) 0x06, (byte) 0x2F, (byte) 0x68, (byte) 0x65, (byte) 0x6C, (byte) 0x6C, (byte) 0x6F, (byte) 0x83, (byte) 0x5F, (byte) 0x0A, (byte) 0x74, (byte) 0x65, (byte) 0x78, (byte) 0x74, (byte) 0x2F, (byte) 0x70, (byte) 0x6C, (byte) 0x61, (byte) 0x69, (byte) 0x6E, (byte) 0x7A, (byte) 0x04, (byte) 0x77, (byte) 0x73, (byte) 0x6F, (byte) 0x32});
        Thread.sleep(1000);

        System.out.println("Writing data frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64});

        commDone.set(true);
        Thread.sleep(2000);
    }

    private void startReadingFromInputStream(InputStream inputStream) {
        Thread readerThread = new Thread(new ReadFromInputStream(inputStream));
        readerThread.start();
    }

    class ReadFromInputStream implements Runnable {

        final InputStream inputStream;

        public ReadFromInputStream(InputStream inputStream) {
            this.inputStream = inputStream;
        }

        @Override
        public void run() {
            readLock.lock();
            byte[] buffer = new byte[4096];
            try {
                while (true) {
                    inputStream.read(buffer);
                    // check for data frame type flag
                    if (String.format("%8s", Integer.toBinaryString(buffer[3] & 0xFF))
                            .replace(' ', '0').equals("00000000")) {
                        // read the data part from the frame
                        serverResponse = new String(buffer, 9, 11);
                    }
                    Thread.sleep(1000);
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                readLock.unlock();
            }
        }
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
}
