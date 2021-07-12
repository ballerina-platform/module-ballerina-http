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

package org.ballerinalang.net.transport.websocket.passthrough;

import org.ballerinalang.net.transport.contract.websocket.WebSocketBinaryMessage;
import org.ballerinalang.net.transport.contract.websocket.WebSocketCloseMessage;
import org.ballerinalang.net.transport.contract.websocket.WebSocketConnection;
import org.ballerinalang.net.transport.contract.websocket.WebSocketConnectorListener;
import org.ballerinalang.net.transport.contract.websocket.WebSocketControlMessage;
import org.ballerinalang.net.transport.contract.websocket.WebSocketHandshaker;
import org.ballerinalang.net.transport.contract.websocket.WebSocketTextMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client connector Listener to check WebSocket pass-through scenarios.
 */
public class WebSocketPassThroughClientConnectorListener implements WebSocketConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(WebSocketPassThroughClientConnectorListener.class);

    @Override
    public void onHandshake(WebSocketHandshaker webSocketHandshaker) {
        throw new UnsupportedOperationException("Method is not supported");
    }

    @Override
    public void onMessage(WebSocketTextMessage textMessage) {
        WebSocketConnection serverConnection = WebSocketPassThroughTestConnectionManager.getInstance().
                getServerConnection(textMessage.getWebSocketConnection());
        serverConnection.pushText(textMessage.getText());
        serverConnection.readNextFrame();
    }

    @Override
    public void onMessage(WebSocketBinaryMessage binaryMessage) {
        WebSocketConnection serverConnection = WebSocketPassThroughTestConnectionManager.getInstance().
                getServerConnection(binaryMessage.getWebSocketConnection());
        serverConnection.pushBinary(binaryMessage.getByteBuffer());
        serverConnection.readNextFrame();
    }

    @Override
    public void onMessage(WebSocketControlMessage controlMessage) {
        throw new UnsupportedOperationException("Method is not supported");
    }

    @Override
    public void onMessage(WebSocketCloseMessage closeMessage) {
        throw new UnsupportedOperationException("Method is not supported");
    }

    @Override
    public void onClose(WebSocketConnection webSocketConnection) {
        //Do nothing
    }

    @Override
    public void onError(WebSocketConnection webSocketConnection, Throwable throwable) {
    }

    @Override
    public void onIdleTimeout(WebSocketControlMessage controlMessage) {
    }
}
