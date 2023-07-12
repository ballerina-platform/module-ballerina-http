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

import org.testng.Assert;
import org.testng.annotations.Test;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;

/**
 * A unit test class for Transport module ProxyServerConfiguration class functions.
 */
public class ProxyServerConfigurationTest {

    @Test
    public void testGetProxyUsername() throws UnknownHostException {
        ProxyServerConfiguration proxyServerConfiguration = new ProxyServerConfiguration("localhost",
                1234);
        Assert.assertNull(proxyServerConfiguration.getProxyUsername());

        proxyServerConfiguration.setProxyUsername("testUsername");
        Assert.assertEquals(proxyServerConfiguration.getProxyUsername(), "testUsername");
    }

    @Test ()
    public void testGetProxyPassword() throws UnknownHostException {
        ProxyServerConfiguration proxyServerConfiguration = new ProxyServerConfiguration("localhost",
                1234);
        Assert.assertNull(proxyServerConfiguration.getProxyPassword());

        proxyServerConfiguration.setProxyPassword("testPassword");
        Assert.assertEquals(proxyServerConfiguration.getProxyPassword(), "testPassword");
    }

    @Test (enabled = false)
    public void testGetInetSocketAddress() throws UnknownHostException {
        ProxyServerConfiguration proxyServerConfiguration = new ProxyServerConfiguration("localhost",
                1234);
        InetSocketAddress inetSocketAddress = new InetSocketAddress(InetAddress.getByName("localhost"), 1234);
        Assert.assertSame(proxyServerConfiguration.getInetSocketAddress(), inetSocketAddress);
    }

}
