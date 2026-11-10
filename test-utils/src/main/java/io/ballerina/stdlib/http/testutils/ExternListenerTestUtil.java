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

package io.ballerina.stdlib.http.testutils;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

/**
 * Extern functions that write raw HTTP/1.x bytes to a listener, over cleartext or TLS, and return everything read.
 */
public final class ExternListenerTestUtil {

    private static final int READ_TIMEOUT_MILLIS = 15000;

    private ExternListenerTestUtil() {}

    // Writes the raw request and reads until `expectedResponses` complete responses have been seen, the connection
    // is closed or the read times out. Returns the bytes read as a string.
    public static Object sendRawAndReadAll(int port, boolean tls, BString rawRequest, int expectedResponses) {
        try (Socket socket = tls ? tlsSocket(port) : new Socket("localhost", port)) {
            socket.setSoTimeout(READ_TIMEOUT_MILLIS);
            OutputStream out = socket.getOutputStream();
            out.write(rawRequest.getValue().getBytes(StandardCharsets.US_ASCII));
            out.flush();
            InputStream in = socket.getInputStream();
            ByteArrayOutputStream collected = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            try {
                int read;
                while ((read = in.read(buffer)) != -1) {
                    collected.write(buffer, 0, read);
                    if (responsesComplete(collected.toString(StandardCharsets.US_ASCII), expectedResponses)) {
                        break;
                    }
                }
            } catch (SocketTimeoutException e) {
                // Return what has been read so far.
            }
            return StringUtils.fromString(collected.toString(StandardCharsets.US_ASCII));
        } catch (Exception e) {
            return ErrorCreator.createError(StringUtils.fromString("Raw request to port " + port + " failed: "
                    + e.getMessage()));
        }
    }

    // The test services answer with short fixed-length bodies, so a response is complete once its content-length
    // worth of bytes follow the header terminator.
    private static boolean responsesComplete(String data, int expectedResponses) {
        int searchFrom = 0;
        for (int i = 0; i < expectedResponses; i++) {
            int headerEnd = data.indexOf("\r\n\r\n", searchFrom);
            if (headerEnd == -1) {
                return false;
            }
            String headers = data.substring(searchFrom, headerEnd).toLowerCase();
            if (headers.contains("transfer-encoding: chunked")) {
                throw new IllegalStateException("Chunked responses are not supported by this test helper");
            }
            int lengthIndex = headers.indexOf("content-length:");
            int length = 0;
            if (lengthIndex != -1) {
                int lineEnd = headers.indexOf("\r\n", lengthIndex);
                String value = headers.substring(lengthIndex + 15, lineEnd == -1 ? headers.length() : lineEnd);
                length = Integer.parseInt(value.trim());
            }
            searchFrom = headerEnd + 4 + length;
            if (searchFrom > data.length()) {
                return false;
            }
        }
        return true;
    }

    private static Socket tlsSocket(int port) throws Exception {
        SSLContext context = trustAllContext();
        SSLSocket socket = (SSLSocket) context.getSocketFactory().createSocket("localhost", port);
        socket.startHandshake();
        return socket;
    }

    private static SSLContext trustAllContext() throws Exception {
        TrustManager[] trustAll = {new X509TrustManager() {
            @Override
            public void checkClientTrusted(X509Certificate[] chain, String authType) {
            }

            @Override
            public void checkServerTrusted(X509Certificate[] chain, String authType) {
            }

            @Override
            public X509Certificate[] getAcceptedIssuers() {
                return new X509Certificate[0];
            }
        }};
        SSLContext context = SSLContext.getInstance("TLS");
        context.init(null, trustAll, new SecureRandom());
        return context;
    }
}
