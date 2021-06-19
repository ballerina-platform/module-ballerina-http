/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.testutils;

import io.netty.handler.codec.http.FullHttpResponse;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.nio.ByteBuffer;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;

/**
 * A utility class for keep payloads.
 */
public class Utils {

    public static String getEntityBodyFrom(FullHttpResponse httpResponse) {
        ByteBuffer content = httpResponse.content().nioBuffer();
        StringBuilder stringContent = new StringBuilder();
        while (content.hasRemaining()) {
            stringContent.append((char) content.get());
        }
        return stringContent.toString();
    }

    // TODO: find a better way to run client bal files during integration tests.
    public static void prepareBalo(Object test) throws URISyntaxException {
        if (System.getProperty(TestConstant.BALLERINA_HOME) != null) {
            return;
        }

        String path = new File(test.getClass().getProtectionDomain().getCodeSource().getLocation().toURI().getPath())
                .getAbsolutePath();
        Path target = Paths.get(path).getParent();
        if (target != null) {
            System.setProperty(TestConstant.BALLERINA_HOME, target.toString());
        }
    }

    public static KeyStore getKeyStore(File keyStore)
            throws IOException, KeyStoreException, CertificateException, NoSuchAlgorithmException {
        KeyStore ks;
        try (InputStream is = new FileInputStream(keyStore)) {
            ks = KeyStore.getInstance("PKCS12");
            ks.load(is, "ballerina".toCharArray());
        }

        return ks;
    }
}
