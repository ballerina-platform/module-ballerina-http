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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * Extern function that writes raw bytes to a listener, for requests a Ballerina client will not produce.
 */
public final class ExternRawRequestTestUtil {

    private static final int READ_TIMEOUT_MILLIS = 10000;

    private ExternRawRequestTestUtil() {}

    // Returns the status line of the response, or an empty string if the connection closed without one.
    public static Object sendRawRequest(int port, BString rawRequest) {
        try (Socket socket = new Socket("localhost", port)) {
            socket.setSoTimeout(READ_TIMEOUT_MILLIS);
            OutputStream out = socket.getOutputStream();
            out.write(rawRequest.getValue().getBytes(StandardCharsets.US_ASCII));
            out.flush();
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.US_ASCII));
            String statusLine = reader.readLine();
            return StringUtils.fromString(statusLine == null ? "" : statusLine);
        } catch (IOException e) {
            return ErrorCreator.createError(StringUtils.fromString("Raw request to port " + port + " failed: "
                    + e.getMessage()));
        }
    }
}
