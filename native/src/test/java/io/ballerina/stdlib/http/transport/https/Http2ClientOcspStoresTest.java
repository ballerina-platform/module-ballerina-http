/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.https;

import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLHandlerFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.lang.reflect.Field;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;

/**
 * Tests that the HTTP/2 client with OCSP stapling builds its SSL context from the configured key and trust stores.
 */
public class Http2ClientOcspStoresTest {

    @Test
    public void testConfiguredStoresAreLoadedForOcspStapling() throws Exception {
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(TestUtil.KEY_STORE_FILE_PATH));
        senderConfiguration.setKeyStorePass(TestUtil.KEY_STORE_PASSWORD);
        senderConfiguration.setTrustStoreFile(TestUtil.getAbsolutePath(TestUtil.TRUST_STORE_FILE_PATH));
        senderConfiguration.setTrustStorePass(TestUtil.KEY_STORE_PASSWORD);
        senderConfiguration.setOcspStaplingEnabled(true);
        senderConfiguration.setScheme(HTTPS_SCHEME);

        SSLConfig sslConfig = senderConfiguration.getClientSSLConfig();
        sslConfig.initializeSSLContext(true);

        Assert.assertNotNull(sslConfig.getReferenceCountedOpenSslContext());
        SSLHandlerFactory factory = sslConfig.getSslHandlerFactory();
        Assert.assertNotNull(factory);
        Assert.assertNotNull(read(factory, "tmf"), "the configured trust store must be used");
        Assert.assertNotNull(read(factory, "kmf"), "the configured key store must be used");
    }

    private static Object read(SSLHandlerFactory factory, String fieldName) throws Exception {
        Field field = SSLHandlerFactory.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        return field.get(factory);
    }
}
