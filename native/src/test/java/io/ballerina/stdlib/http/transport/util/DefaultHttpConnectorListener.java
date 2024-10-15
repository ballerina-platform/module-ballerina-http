/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

package io.ballerina.stdlib.http.transport.util;

import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.concurrent.CountDownLatch;

/**
 * A connector listener for HTTP.
 */
public class DefaultHttpConnectorListener implements HttpConnectorListener {

    private HttpCarbonMessage httpMessage;
    private Throwable throwable;
    private CountDownLatch latch;

    public DefaultHttpConnectorListener(CountDownLatch latch) {
        this.latch = latch;
    }

    // This constructor can be used to create a listener without a latch when an external locking mechanism is in place.
    public DefaultHttpConnectorListener() {}

    @Override
    public void onMessage(HttpCarbonMessage httpMessage) {
        this.httpMessage = httpMessage;
        if (latch != null) {
            latch.countDown();
        }
    }

    @Override
    public void onError(Throwable throwable) {
        this.throwable = throwable;
        if (latch != null) {
            latch.countDown();
        }
    }

    public HttpCarbonMessage getHttpResponseMessage() {
        return httpMessage;
    }

    public Throwable getHttpErrorMessage() {
        return throwable;
    }
}
