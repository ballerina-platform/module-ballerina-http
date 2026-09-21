/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

/**
 * Extern functions that start and stop the servers replying with a {@code content-encoding: gzip} header over a
 * valid or a malformed body, which a Ballerina service cannot produce because it always sets the content encoding
 * itself.
 */
public final class ExternGzipResponseTestUtil {

    private ExternGzipResponseTestUtil() {}

    public static Object startGzipResponseServer(int port, boolean http2) {
        try {
            GzipTestServer.start(port, http2);
            return null;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ErrorCreator.createError(StringUtils.fromString("Interrupted while starting the gzip server"));
        } catch (Exception e) {
            return ErrorCreator.createError(StringUtils.fromString("Failed to start the gzip server on port " + port
                    + ": " + e.getMessage()));
        }
    }

    public static Object stopGzipResponseServer(int port) {
        try {
            GzipTestServer.stop(port);
            return null;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ErrorCreator.createError(StringUtils.fromString("Interrupted while stopping the gzip server"));
        }
    }
}
