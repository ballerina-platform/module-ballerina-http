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
 * Control signals for WebSocket connection.
 * These signals are the heartbeat signals of a WebSocket connection.
 */
public enum WebSocketControlSignal {

    /**
     * Heartbeat request signal.
     */
    PING,

    /**
     * Heartbeat response signal.
     */
    PONG,

    /**
     * Idle timeout indicator.
     */
    IDLE_TIMEOUT;
}
