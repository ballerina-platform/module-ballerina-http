/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.net.transport.websocket.ssl;

import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.websocket.ClientHandshakeFuture;
import org.ballerinalang.net.transport.contract.websocket.ClientHandshakeListener;
import org.ballerinalang.net.transport.contract.websocket.WebSocketClientConnector;
import org.ballerinalang.net.transport.contract.websocket.WebSocketClientConnectorConfig;
import org.ballerinalang.net.transport.contract.websocket.WebSocketConnection;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpCarbonResponse;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.websocket.client.WebSocketTestClientConnectorListener;
import org.ballerinalang.net.transport.websocket.server.WebSocketTestServerConnectorListener;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

import static java.util.concurrent.TimeUnit.SECONDS;
import static org.ballerinalang.net.transport.util.TestUtil.WEBSOCKET_REMOTE_SERVER_PORT;
import static org.ballerinalang.net.transport.util.TestUtil.WEBSOCKET_SECURE_REMOTE_SERVER_URL;
import static org.ballerinalang.net.transport.util.TestUtil.WEBSOCKET_TEST_IDLE_TIMEOUT;

/**
 * Tests the successful SSL handshake and message reading through SSL handler in WebSocket.
 */
public class WebSocketSSLHandshakeSuccessfulTestCase {

    private String password = "ballerina";
    private String tlsStoreType = "PKCS12";
    private HttpWsConnectorFactory httpConnectorFactory;
    private ServerConnector serverConnector;

    @BeforeClass
    public void setup() throws InterruptedException {
        httpConnectorFactory = new DefaultHttpWsConnectorFactory();

        ListenerConfiguration listenerConfiguration = getListenerConfiguration();
        serverConnector = httpConnectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setWebSocketConnectorListener(new WebSocketTestServerConnectorListener());
        future.sync();
    }

    private ListenerConfiguration getListenerConfiguration() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(WEBSOCKET_REMOTE_SERVER_PORT);
        String keyStoreFile = "/simple-test-config/wso2carbon.p12";
        listenerConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(keyStoreFile));
        listenerConfiguration.setScheme("https");
        listenerConfiguration.setKeyStorePass(password);
        listenerConfiguration.setTLSStoreType(tlsStoreType);
        return listenerConfiguration;
    }

    private WebSocketClientConnectorConfig getWebSocketClientConnectorConfigWithSSL() {
        WebSocketClientConnectorConfig senderConfiguration =
                new WebSocketClientConnectorConfig(WEBSOCKET_SECURE_REMOTE_SERVER_URL);
        String trustStoreFile = "/simple-test-config/client-truststore.p12";
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(trustStoreFile));
        senderConfiguration.setTrustStorePass(password);
        senderConfiguration.setTLSStoreType(tlsStoreType);
        return senderConfiguration;
    }

    @Test
    public void testClientConnectionWithSSL() throws Throwable {
        WebSocketClientConnector webSocketClientConnector =
                httpConnectorFactory.createWsClientConnector(getWebSocketClientConnectorConfigWithSSL());
        CountDownLatch countDownLatch = new CountDownLatch(1);
        AtomicReference<WebSocketConnection> webSocketConnectionAtomicReference = new AtomicReference<>();
        AtomicReference<Throwable> throwableAtomicReference = new AtomicReference<>();
        ClientHandshakeFuture handshakeFuture = webSocketClientConnector.connect();
        WebSocketTestClientConnectorListener clientConnectorListener = new WebSocketTestClientConnectorListener();
        handshakeFuture.setWebSocketConnectorListener(clientConnectorListener);
        handshakeFuture.setClientHandshakeListener(new ClientHandshakeListener() {
            @Override public void onSuccess(WebSocketConnection webSocketConnection, HttpCarbonResponse response) {
                webSocketConnectionAtomicReference.set(webSocketConnection);
                countDownLatch.countDown();
            }

            @Override public void onError(Throwable throwable, HttpCarbonResponse response) {
                throwableAtomicReference.set(throwable);
                countDownLatch.countDown();
            }
        });
        countDownLatch.await(WEBSOCKET_TEST_IDLE_TIMEOUT, SECONDS);
        WebSocketConnection webSocketConnection = webSocketConnectionAtomicReference.get();

        Assert.assertNull(throwableAtomicReference.get());
        Assert.assertNotNull(webSocketConnection);
        Assert.assertTrue(webSocketConnection.isSecure());

        // Test whether message can be received after a successful handshake.
        webSocketConnection.startReadingFrames();
        String testText = "testText";
        CountDownLatch msgCountDownLatch = new CountDownLatch(1);
        clientConnectorListener.setCountDownLatch(msgCountDownLatch);
        webSocketConnection.pushText(testText);
        msgCountDownLatch.await(WEBSOCKET_TEST_IDLE_TIMEOUT, SECONDS);

        Assert.assertEquals(clientConnectorListener.getReceivedTextMessageToClient().getText(), testText);
    }

    @AfterClass
    public void cleanup() throws InterruptedException {
        serverConnector.stop();
        httpConnectorFactory.shutdown();
    }
}
