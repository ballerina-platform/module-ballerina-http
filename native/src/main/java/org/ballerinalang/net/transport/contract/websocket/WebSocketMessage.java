/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 *
 */

package org.ballerinalang.net.transport.contract.websocket;

/**
 * This is the common interface for all WebSocket messages.
 * <b>Note: Use this interface in the application level only and only if the user needs only the channel details
 * of a WebSocket message otherwise use the extensions of this interface.</b>
 */
public interface WebSocketMessage {

    /**
     * Retrieve the target of the application as a String.
     *
     * @return the target of the application.
     */
    String getTarget();

    /**
     * Check whether the message is coming from server connector or client connector.
     *
     * @return true if the message is coming from server connector else return false if the message is coming from
     * client connector.
     */
    boolean isServerMessage();

    /**
     * Retrieve the session of the connection.
     *
     * @return the session of the connection.
     */
    WebSocketConnection getWebSocketConnection();
}
