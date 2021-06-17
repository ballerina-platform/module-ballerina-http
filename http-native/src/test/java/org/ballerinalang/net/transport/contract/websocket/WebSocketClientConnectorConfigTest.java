/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.transport.contract.websocket;

import org.testng.Assert;
import org.testng.annotations.Test;

import static org.ballerinalang.net.transport.util.TestUtil.WEBSOCKET_REMOTE_SERVER_URL;

/**
 * A unit test class for Transport module WebSocketClientConnectorConfig class functions.
 */
public class WebSocketClientConnectorConfigTest {

    @Test
    public void testGetMaxFrameSize() {
        WebSocketClientConnectorConfig webSocketClientConnectorConfig =
                new WebSocketClientConnectorConfig(WEBSOCKET_REMOTE_SERVER_URL);
        Assert.assertEquals(webSocketClientConnectorConfig.getMaxFrameSize(), 65536);
        webSocketClientConnectorConfig.setMaxFrameSize(100);
        Assert.assertEquals(webSocketClientConnectorConfig.getMaxFrameSize(), 100);

    }

    @Test
    public void testSetSubProtocols() {
        WebSocketClientConnectorConfig webSocketClientConnectorConfig =
                new WebSocketClientConnectorConfig(WEBSOCKET_REMOTE_SERVER_URL);
        Assert.assertNull(webSocketClientConnectorConfig.getSubProtocolsStr());
        webSocketClientConnectorConfig.setSubProtocols(new String[]{"testSub1", "testSub2"});
        Assert.assertEquals(webSocketClientConnectorConfig.getSubProtocolsStr(), "testSub1,testSub2");
        webSocketClientConnectorConfig.setSubProtocols(new String[]{});
        Assert.assertNull(webSocketClientConnectorConfig.getSubProtocolsStr());
        webSocketClientConnectorConfig.setSubProtocols(new String[]{"testSub1", "testSub2"});
        webSocketClientConnectorConfig.setSubProtocols(null);
        Assert.assertNull(webSocketClientConnectorConfig.getSubProtocolsStr());
    }

}
