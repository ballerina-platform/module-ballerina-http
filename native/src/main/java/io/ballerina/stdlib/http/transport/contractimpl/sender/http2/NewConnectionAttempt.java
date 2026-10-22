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

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;

/**
 * Identifies one request's attempt to get an HTTP/2 connection. When the pool picks the request to open the route's
 * new connection, only a failure of that attempt releases the requests waiting for it, and they fail with it.
 */
public final class NewConnectionAttempt {

    private boolean opener;
    // Written and read under the route pool's lock
    private ClientConnectorException failure;

    void markAsOpener() {
        opener = true;
    }

    /**
     * Tells whether this attempt was picked to open the route's new connection.
     *
     * @return true if the requests waiting for a new connection are waiting for this attempt
     */
    public boolean isOpener() {
        return opener;
    }

    void fail(ClientConnectorException failure) {
        this.failure = failure;
    }

    ClientConnectorException getFailure() {
        return failure;
    }
}
