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
import org.ballerinalang.net.transport.util.TestUtil;
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

    @Test
    public void testGetClientSSLConfigInvalidScheme() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        Assert.assertNull(sslConfiguration.getClientSSLConfig());
        sslConfiguration.setScheme(null);
        Assert.assertNull(sslConfiguration.getClientSSLConfig());
    }

    @Test
    public void testGetClientSSLConfigWithDisableSslAndDefault() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.disableSsl();
        Assert.assertNotNull(sslConfiguration.getClientSSLConfig());
        sslConfiguration.useJavaDefaults();
        Assert.assertNotNull(sslConfiguration.getClientSSLConfig());
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "TrustStore File testTrustStoreFile not found")
    public void testGetClientSSLConfigWithInvalidTrustStore() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setTrustStoreFile("testTrustStoreFile");
        sslConfiguration.setTrustStorePass("testTrustStorePass");
        sslConfiguration.getClientSSLConfig();
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Key file or server certificates file not found")
    public void testGetClientSSLConfigWithInvalidTrustCertificate() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setClientTrustCertificates("testClientTrustCertificate");
        sslConfiguration.getClientSSLConfig();
    }

    @Test
    public void testGetClientSSLConfigWithNullParameters() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setParameters(null);
        sslConfiguration.setClientTrustCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        Assert.assertNotNull(sslConfiguration.getClientSSLConfig());
    }

    @Test
    public void testGetListenerSSLConfigInvalidScheme() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        Assert.assertNull(sslConfiguration.getListenerSSLConfig());
        sslConfiguration.setScheme(null);
        Assert.assertNull(sslConfiguration.getListenerSSLConfig());
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "keyStoreFile or keyStorePassword not defined for HTTPS scheme")
    public void testGetListenerSSLConfigurationWithoutKeyStore() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.getListenerSSLConfig();
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "KeyStore File testKeyStoreFile not found")
    public void testGetListenerSSLConfigurationWithInvalidKeyStoreFile() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setKeyStoreFile("testKeyStoreFile");
        sslConfiguration.setKeyStorePass("testKeyStorePass");
        sslConfiguration.getListenerSSLConfig();
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Key file or server certificates file not found")
    public void testGetListenerSSLConfigurationWithInvalidKeyFile() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setServerKeyFile("testKeyFile");
        sslConfiguration.setServerCertificates("testCertificate");
        sslConfiguration.getListenerSSLConfig();
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "TrustStore file testTrustStore not found")
    public void testGetListenerSSLConfigurationWithInvalidTrustStore() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setServerKeyFile(TestUtil.getAbsolutePath(TestUtil.KEY_FILE));
        sslConfiguration.setServerCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        sslConfiguration.setTrustStoreFile("testTrustStore");
        sslConfiguration.getListenerSSLConfig();
    }

    @Test(expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Truststore password is not defined for HTTPS scheme")
    public void testGetListenerSSLConfigurationWithoutTrustStorePass() {
        SslConfiguration sslConfiguration = new SslConfiguration();
        sslConfiguration.setScheme("https");
        sslConfiguration.setServerKeyFile(TestUtil.getAbsolutePath(TestUtil.KEY_FILE));
        sslConfiguration.setServerCertificates(TestUtil.getAbsolutePath(TestUtil.CERT_FILE));
        sslConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(TestUtil.TRUST_STORE_FILE_PATH));
        sslConfiguration.getListenerSSLConfig();
    }

}
