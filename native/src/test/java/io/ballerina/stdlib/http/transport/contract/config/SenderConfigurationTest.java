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

package io.ballerina.stdlib.http.transport.contract.config;

import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * A unit test class for Transport module SenderConfiguration class functions.
 */
public class SenderConfigurationTest {

    @Test
    public void testGetId() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertEquals(senderConfiguration.getId(), "netty");

        senderConfiguration = new SenderConfiguration("testId1");
        Assert.assertEquals(senderConfiguration.getId(), "testId1");

        senderConfiguration.setId("testId2");
        Assert.assertEquals(senderConfiguration.getId(), "testId2");
    }

    @Test
    public void testGetSocketIdleTimeout() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertEquals(senderConfiguration.getSocketIdleTimeout(1234), 60000);

        senderConfiguration.setSocketIdleTimeout(0);
        Assert.assertEquals(senderConfiguration.getSocketIdleTimeout(1234), 1234);
    }

    @Test
    public void testIsHttpTraceLogEnabled() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertFalse(senderConfiguration.isHttpTraceLogEnabled());

        senderConfiguration.setHttpTraceLogEnabled(true);
        Assert.assertTrue(senderConfiguration.isHttpTraceLogEnabled());
    }

    @Test
    public void testIsHttpAccessLogEnabled() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertFalse(senderConfiguration.isHttpAccessLogEnabled());

        senderConfiguration.setHttpAccessLogEnabled(true);
        Assert.assertTrue(senderConfiguration.isHttpAccessLogEnabled());
    }

    @Test
    public void testGetHttpVersion() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertEquals(senderConfiguration.getHttpVersion(), "1.1");

        senderConfiguration.setHttpVersion("");
        Assert.assertEquals(senderConfiguration.getHttpVersion(), "1.1");

        senderConfiguration.setHttpVersion("version");
        Assert.assertEquals(senderConfiguration.getHttpVersion(), "version");
    }

    @Test
    public void testGetPoolConfiguration() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertNotNull(senderConfiguration.getPoolConfiguration());

        PoolConfiguration poolConfiguration = new PoolConfiguration();
        senderConfiguration.setPoolConfiguration(poolConfiguration);
        PoolConfiguration returnVal = senderConfiguration.getPoolConfiguration();
        Assert.assertEquals(returnVal, poolConfiguration);
    }

    @Test
    public void testGetMsgSizeValidationConfig() {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        Assert.assertNotNull(senderConfiguration.getMsgSizeValidationConfig());

        InboundMsgSizeValidationConfig responseSizeValidationConfig = new InboundMsgSizeValidationConfig();
        senderConfiguration.setMsgSizeValidationConfig(responseSizeValidationConfig);
        InboundMsgSizeValidationConfig returnVal = senderConfiguration.getMsgSizeValidationConfig();
        Assert.assertEquals(returnVal, responseSizeValidationConfig);
    }

    @Test
    public void testGetDefault() {
        SenderConfiguration senderConfiguration = SenderConfiguration.getDefault();
        Assert.assertNotNull(senderConfiguration);
        Assert.assertEquals(senderConfiguration.getId(), "netty");
    }

}
