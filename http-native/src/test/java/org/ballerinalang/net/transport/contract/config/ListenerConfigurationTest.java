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

package org.ballerinalang.net.transport.contract.config;

import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * A unit test class for Transport module ListenerConfiguration class functions.
 */
public class ListenerConfigurationTest {

    @Test
    public void testGetID() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertEquals(listenerConfiguration.getId(), "default");

        listenerConfiguration = new ListenerConfiguration("testId", "testHost", 1234);
        Assert.assertEquals(listenerConfiguration.getId(), "testId");
    }

    @Test
    public void testBindOnStartUp() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertFalse(listenerConfiguration.isBindOnStartup());

        listenerConfiguration.setBindOnStartup(true);
        Assert.assertTrue(listenerConfiguration.isBindOnStartup());
    }

    @Test
    public void testGetParameters() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertNotNull(listenerConfiguration.getParameters());
    }

    @Test
    public void testGetMessageProcessorId() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertNull(listenerConfiguration.getMessageProcessorId());

        listenerConfiguration.setMessageProcessorId("testMsgProcessorId");
        Assert.assertEquals(listenerConfiguration.getMessageProcessorId(), "testMsgProcessorId");
    }

    @Test
    public void testIsHttpTraceLogEnabled() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertFalse(listenerConfiguration.isHttpTraceLogEnabled());

        listenerConfiguration.setHttpTraceLogEnabled(true);
        Assert.assertTrue(listenerConfiguration.isHttpTraceLogEnabled());
    }

    @Test
    public void testIsHttpAccessLogEnabled() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertFalse(listenerConfiguration.isHttpAccessLogEnabled());

        listenerConfiguration.setHttpAccessLogEnabled(true);
        Assert.assertTrue(listenerConfiguration.isHttpAccessLogEnabled());
    }

    @Test
    public void testGetMsgSizeValidationConfig() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        Assert.assertNotNull(listenerConfiguration.getMsgSizeValidationConfig());

        InboundMsgSizeValidationConfig requestSizeValidationConfig = new InboundMsgSizeValidationConfig();
        listenerConfiguration.setMsgSizeValidationConfig(requestSizeValidationConfig);
        InboundMsgSizeValidationConfig returnVal = listenerConfiguration.getMsgSizeValidationConfig();
        Assert.assertEquals(returnVal, requestSizeValidationConfig);
    }

}
