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

package io.ballerina.stdlib.http.transport.contractimpl.websocket;

import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketBinaryMessage;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketCloseMessage;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketConnection;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketConnectorException;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketConnectorListener;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketControlMessage;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketHandshaker;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketTextMessage;

/**
 * Default implementation of {@link WebSocketConnectorFuture}.
 */
public class DefaultWebSocketConnectorFuture implements WebSocketConnectorFuture {

    private WebSocketConnectorListener wsConnectorListener;

    @Override
    public void setWebSocketConnectorListener(WebSocketConnectorListener wsConnectorListener) {
        this.wsConnectorListener = wsConnectorListener;
    }

    @Override
    public void notifyWebSocketListener(WebSocketHandshaker webSocketHandshaker) throws Exception {
        checkConnectorState();
        wsConnectorListener.onHandshake(webSocketHandshaker);
    }

    @Override
    public void notifyWebSocketListener(WebSocketTextMessage textMessage) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onMessage(textMessage);
    }

    @Override
    public void notifyWebSocketListener(WebSocketBinaryMessage binaryMessage) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onMessage(binaryMessage);
    }

    @Override
    public void notifyWebSocketListener(WebSocketControlMessage controlMessage) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onMessage(controlMessage);
    }

    @Override
    public void notifyWebSocketListener(WebSocketCloseMessage closeMessage) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onMessage(closeMessage);
    }

    @Override
    public void notifyWebSocketListener(WebSocketConnection webSocketConnection, Throwable throwable)
            throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onError(webSocketConnection, throwable);
    }

    @Override
    public void notifyWebSocketIdleTimeout(WebSocketControlMessage controlMessage) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onIdleTimeout(controlMessage);
    }

    @Override
    public void notifyWebSocketListener(WebSocketConnection webSocketConnection) throws WebSocketConnectorException {
        checkConnectorState();
        wsConnectorListener.onClose(webSocketConnection);
    }

    private void checkConnectorState() throws WebSocketConnectorException {
        if (wsConnectorListener == null) {
            throw new WebSocketConnectorException("WebSocket connector listener is not set");
        }
    }
}
