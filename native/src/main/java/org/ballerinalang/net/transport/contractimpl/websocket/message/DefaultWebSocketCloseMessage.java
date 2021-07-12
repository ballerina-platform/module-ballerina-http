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

package org.ballerinalang.net.transport.contractimpl.websocket.message;

import org.ballerinalang.net.transport.contract.websocket.WebSocketCloseMessage;
import org.ballerinalang.net.transport.contractimpl.websocket.DefaultWebSocketMessage;

/**
 * Implementation of {@link WebSocketCloseMessage}.
 */
public class DefaultWebSocketCloseMessage extends DefaultWebSocketMessage implements WebSocketCloseMessage {

    private final int closeCode;
    private final String closeReason;

    public DefaultWebSocketCloseMessage(int closeCode) {
        this(closeCode, null);
    }

    public DefaultWebSocketCloseMessage(int closeCode, String closeReason) {
        this.closeCode = closeCode;
        this.closeReason = closeReason;
    }

    @Override
    public int getCloseCode() {
        return closeCode;
    }

    @Override
    public String getCloseReason() {
        return closeReason;
    }
}
