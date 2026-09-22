/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.zip.GZIPOutputStream;

/**
 * Bodies served under a {@code content-encoding: gzip} header by the gzip test servers.
 */
public final class GzipPayloads {

    public static final String PATH_MALFORMED_GZIP = "/badgzip";

    public static final String PATH_PUSH = "/push";

    public static final String DECODED_CONTENT = "Hello from a gzip encoded response";

    private GzipPayloads() {}

    /**
     * Plain bytes served under a gzip content encoding, so decoding fails on the very first chunk.
     */
    public static byte[] malformedGzip() {
        return "not-a-gzip-stream".getBytes(StandardCharsets.UTF_8);
    }

    public static byte[] validGzip() {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            try (GZIPOutputStream gzip = new GZIPOutputStream(out)) {
                gzip.write(DECODED_CONTENT.getBytes(StandardCharsets.UTF_8));
            }
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /**
     * Picks the body for a request target, which the client may send in either origin or absolute form.
     *
     * @param path the request target
     * @return the bytes to serve under the gzip content encoding
     */
    public static byte[] payloadFor(String path) {
        if (path != null && path.contains(PATH_MALFORMED_GZIP)) {
            return malformedGzip();
        }
        return validGzip();
    }
}
