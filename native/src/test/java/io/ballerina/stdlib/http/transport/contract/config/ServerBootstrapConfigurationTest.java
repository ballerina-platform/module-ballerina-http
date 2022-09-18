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

import io.ballerina.stdlib.http.transport.contract.Constants;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.util.HashMap;

/**
 * A unit test class for Transport module ServerBootstrapConfiguration class functions.
 */
public class ServerBootstrapConfigurationTest {

    @Test
    public void testIsKeepAlive() {
        ServerBootstrapConfiguration serverBootstrapConfiguration = new ServerBootstrapConfiguration(new HashMap<>());
        Assert.assertTrue(serverBootstrapConfiguration.isKeepAlive());

        HashMap<String, Object> properties = new HashMap<>();
        properties.put(Constants.SERVER_BOOTSTRAP_KEEPALIVE, false);
        serverBootstrapConfiguration = new ServerBootstrapConfiguration(properties);
        Assert.assertFalse(serverBootstrapConfiguration.isKeepAlive());
    }

    @Test
    public void testIsSocketReuse() {
        ServerBootstrapConfiguration serverBootstrapConfiguration = new ServerBootstrapConfiguration(new HashMap<>());
        Assert.assertFalse(serverBootstrapConfiguration.isSocketReuse());

        HashMap<String, Object> properties = new HashMap<>();
        properties.put(Constants.SERVER_BOOTSTRAP_SO_REUSE, true);
        serverBootstrapConfiguration = new ServerBootstrapConfiguration(properties);
        Assert.assertTrue(serverBootstrapConfiguration.isSocketReuse());
    }

    @Test
    public void testGetSoTimeout() {
        ServerBootstrapConfiguration serverBootstrapConfiguration = new ServerBootstrapConfiguration(new HashMap<>());
        Assert.assertEquals(serverBootstrapConfiguration.getConnectTimeOut(), 15);

        HashMap<String, Object> properties = new HashMap<>();
        properties.put(Constants.SERVER_BOOTSTRAP_CONNECT_TIME_OUT, 10);
        serverBootstrapConfiguration = new ServerBootstrapConfiguration(properties);
        Assert.assertEquals(serverBootstrapConfiguration.getConnectTimeOut(), 10);
    }

}
