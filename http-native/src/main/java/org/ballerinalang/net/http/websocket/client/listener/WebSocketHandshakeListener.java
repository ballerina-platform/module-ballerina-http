/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.http.websocket.client.listener;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.http.nativeimpl.ModuleUtils;
import org.ballerinalang.net.http.websocket.WebSocketConstants;
import org.ballerinalang.net.http.websocket.WebSocketService;
import org.ballerinalang.net.http.websocket.WebSocketUtil;
import org.ballerinalang.net.http.websocket.client.FailoverContext;
import org.ballerinalang.net.http.websocket.client.RetryContext;
import org.ballerinalang.net.http.websocket.observability.WebSocketObservabilityUtil;
import org.ballerinalang.net.http.websocket.server.WebSocketConnectionInfo;
import org.ballerinalang.net.transport.contract.websocket.WebSocketConnection;
import org.ballerinalang.net.transport.message.HttpCarbonResponse;

import java.util.concurrent.CountDownLatch;

import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_CONFIG;

/**
 * The `WebSocketHandshakeListener` implements the `{@link ExtendedHandshakeListener}` interface directly.
 *
 * @since 1.2.0
 */
public class WebSocketHandshakeListener implements ExtendedHandshakeListener {

    private final WebSocketService wsService;
    private final ExtendedConnectorListener connectorListener;
    private final BObject webSocketClient;
    private CountDownLatch countDownLatch;
    private WebSocketConnectionInfo connectionInfo;
    private boolean readyOnConnect;

    public WebSocketHandshakeListener(BObject webSocketClient, WebSocketService wsService,
                                      ExtendedConnectorListener connectorListener,
                                      CountDownLatch countDownLatch, boolean readyOnConnect) {
        this.webSocketClient = webSocketClient;
        this.wsService = wsService;
        this.connectorListener = connectorListener;
        this.countDownLatch = countDownLatch;
        this.readyOnConnect = readyOnConnect;
    }

    @Override
    public void onSuccess(WebSocketConnection webSocketConnection, HttpCarbonResponse carbonResponse) {
        BObject webSocketConnector;
        webSocketClient.set(WebSocketConstants.CLIENT_RESPONSE_FIELD, HttpUtil.createResponseStruct(carbonResponse));
        if (isFirstConnectionEstablished(webSocketClient)) {
            webSocketConnector = (BObject) webSocketClient.get(WebSocketConstants.CLIENT_CONNECTOR_FIELD);
            webSocketClient.set(WebSocketConstants.LISTENER_ID_FIELD,
                                StringUtils.fromString(webSocketConnection.getChannelId()));
        } else {
            webSocketConnector = createWebSocketConnector(readyOnConnect);
            WebSocketUtil.populateWebSocketEndpoint(webSocketConnection, webSocketClient);
            // Calls the `countDown()` function to initialize the count down latch of the connection.
            WebSocketUtil.countDownForHandshake(webSocketClient);
        }
        if (readyOnConnect) {
            WebSocketUtil.readFirstFrame(webSocketConnection, webSocketConnector);
        }
        setWebSocketOpenConnectionInfo(webSocketConnection, webSocketConnector, webSocketClient, wsService);
        connectorListener.setConnectionInfo(connectionInfo);
        countDownLatch.countDown();
        WebSocketObservabilityUtil.observeConnection(connectionInfo);
    }

    @Override
    public void onError(Throwable t, HttpCarbonResponse response) {
        if (response != null) {
            webSocketClient.set(WebSocketConstants.CLIENT_RESPONSE_FIELD, HttpUtil.createResponseStruct(response));
        }
        BObject webSocketConnector = ValueCreator.createObjectValue(ModuleUtils.getModule(),
                                                                    WebSocketConstants.WEBSOCKET_CONNECTOR);
        setWebSocketOpenConnectionInfo(null, webSocketConnector, webSocketClient, wsService);
        webSocketConnector.addNativeData(WebSocketConstants.NATIVE_DATA_WEBSOCKET_CONNECTION_INFO, connectionInfo);
        webSocketClient.set(WebSocketConstants.CLIENT_CONNECTOR_FIELD, webSocketConnector);
        countDownLatch.countDown();
    }

    @Override
    public BObject getWebSocketClient() {
        return webSocketClient;
    }

    @Override
    public WebSocketConnectionInfo getWebSocketConnectionInfo() {
        return connectionInfo;
    }

    private void setWebSocketOpenConnectionInfo(WebSocketConnection webSocketConnection,
                                                BObject webSocketConnector,
                                                BObject webSocketClient, WebSocketService wsService) {
        this.connectionInfo = new WebSocketConnectionInfo(wsService, webSocketConnection, webSocketClient);
        webSocketConnector.addNativeData(WebSocketConstants.NATIVE_DATA_WEBSOCKET_CONNECTION_INFO, connectionInfo);
        webSocketClient.set(WebSocketConstants.CLIENT_CONNECTOR_FIELD, webSocketConnector);
    }

    private static BObject createWebSocketConnector(boolean readyOnConnect) {
        BObject webSocketConnector = ValueCreator.createObjectValue(ModuleUtils.getModule(),
                                                                    WebSocketConstants.WEBSOCKET_CONNECTOR);
        // Sets the value of `readyOnConnect` to the created `isReady' field of the webSocketConnector.
        // It checks whether the `readNextFrame` function is already called or not when the `ready()` function
        // is called.
        webSocketConnector.set(WebSocketConstants.CONNECTOR_IS_READY_FIELD, readyOnConnect);
        return webSocketConnector;
    }

    private boolean isFirstConnectionEstablished(BObject webSocketClient) {
        return (webSocketClient.getMapValue(CLIENT_ENDPOINT_CONFIG).getMapValue(
                WebSocketConstants.RETRY_CONTEXT) != null && ((RetryContext) webSocketClient.getNativeData(
                WebSocketConstants.RETRY_CONTEXT.getValue())).isFirstConnectionEstablished()) ||
                (WebSocketUtil.isFailoverClient(webSocketClient) &&
                        ((FailoverContext) webSocketClient.getNativeData(WebSocketConstants.FAILOVER_CONTEXT)).
                                isFirstConnectionEstablished());
    }
}
