/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.ballerinalang.net.http.actions.httpclient;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.values.BObject;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpClientConnectorListener;
import org.ballerinalang.net.transport.message.ResponseHandle;

/**
 * {@code HasPromise} action can be used to check whether a push promise is available.
 */
public class HasPromise extends AbstractHTTPAction {

    public static boolean hasPromise(Environment env, BObject clientObj, BObject handleObj) {
        ResponseHandle responseHandle = (ResponseHandle) handleObj.getNativeData(HttpConstants.TRANSPORT_HANDLE);
        if (responseHandle == null) {
            throw HttpUtil.createHttpError("invalid http handle");
        }
        HttpClientConnector clientConnector = (HttpClientConnector) clientObj.getNativeData(HttpConstants.CLIENT);
        clientConnector.hasPushPromise(responseHandle).
                setPromiseAvailabilityListener(new PromiseAvailabilityCheckListener(env.markAsync()));
        return false;
    }

    private static class PromiseAvailabilityCheckListener implements HttpClientConnectorListener {

        private Future balFuture;

        PromiseAvailabilityCheckListener(Future balFuture) {
            this.balFuture = balFuture;
        }

        @Override
        public void onPushPromiseAvailability(boolean isPromiseAvailable) {
            balFuture.complete(isPromiseAvailable);
        }
    }
}
