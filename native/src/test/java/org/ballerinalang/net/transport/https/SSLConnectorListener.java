/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.transport.https;

import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

/**
 * SSL connector test listener.
 */
public class SSLConnectorListener extends DefaultHttpConnectorListener {

    private List<Throwable> throwables = new ArrayList<>();
    private CountDownLatch latch;

    public SSLConnectorListener(CountDownLatch latch) {
        super(latch);
    }

    public void onError(Throwable throwable) {
        throwables.add(throwable);
    }

    public List<Throwable> getThrowables() {
        return throwables;
    }
}
