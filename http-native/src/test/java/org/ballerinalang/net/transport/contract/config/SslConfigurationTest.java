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

import org.ballerinalang.net.transport.contractimpl.common.ssl.SSLConfig;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;

/**
 * A unit test class for Transport module SslConfiguration class functions.
 */
public class SslConfigurationTest {

    @Test
    public void testSetVerifyClientWithUnidentifiedConfig() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setVerifyClient("test");
    }

    @Test
    public void testSetVerifyClientWithEmptyString() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setVerifyClient("");
    }

    @Test
    public void testGetParameters() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        Assert.assertNotNull(sslConfiguration.getParameters());
        Assert.assertTrue(sslConfiguration.getParameters().isEmpty());

        List<Parameter> parameters = new ArrayList<>();
        sslConfiguration.setParameters(parameters);
        Assert.assertEquals(sslConfiguration.getParameters(), parameters);
    }

    @Test
    public void testGetKeyStoreFile() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        Assert.assertEquals(sslConfiguration.getKeyStoreFile(), "null");
    }

    @Test
    public void testGetKetStorePass() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        Assert.assertNull(sslConfiguration.getKeyStorePass());
    }

    @Test
    public void testSetCacheValidityPeriod() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setCacheValidityPeriod(10);
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        SSLConfig sslConfig = sslConfiguration.getClientSSLConfig();
        Assert.assertEquals(sslConfig.getCacheValidityPeriod(), 10);
    }

    @Test
    public void testSetCacheSize() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setCacheSize(10);
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        SSLConfig sslConfig = sslConfiguration.getClientSSLConfig();
        Assert.assertEquals(sslConfig.getCacheSize(), 10);
    }

    @Test
    public void testSetClientKeyPassword() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setClientKeyPassword("testPassword");
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        SSLConfig sslConfig = sslConfiguration.getClientSSLConfig();
        Assert.assertEquals(sslConfig.getClientKeyPassword(), "testPassword");
    }

    @Test
    public void testSetServerKeyPassword() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setServerKeyPassword("testPassword");
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        SSLConfig sslConfig = sslConfiguration.getClientSSLConfig();
        Assert.assertEquals(sslConfig.getServerKeyPassword(), "testPassword");
    }

    @Test
    public void testUseJavaDefaults() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.useJavaDefaults();
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        SSLConfig sslConfig = sslConfiguration.getClientSSLConfig();
        Assert.assertTrue(sslConfig.useJavaDefaults());
    }

}
