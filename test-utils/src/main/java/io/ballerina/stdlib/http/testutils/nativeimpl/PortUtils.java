/*
 *  Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.testutils.nativeimpl;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;

/**
 * Port checks for the integration tests.
 */
public final class PortUtils {

    private static final int CONNECT_TIMEOUT_MILLIS = 500;

    private PortUtils() {}

    // A plain TCP connect, so that checking whether a service is up does not add an access log entry.
    public static boolean isPortOpen(long port) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", (int) port), CONNECT_TIMEOUT_MILLIS);
            return true;
        } catch (IOException e) {
            return false;
        }
    }
}
