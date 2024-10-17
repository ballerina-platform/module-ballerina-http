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

package io.ballerina.stdlib.http.api.client.actions;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;

import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code GetNextPromise} action can be used to get the next available push promise message associated with
 * a previous asynchronous invocation.
 */
public class GetNextPromise extends AbstractHTTPAction {

    public static Object getNextPromise(Environment env, BObject clientObj, BObject handleObj) {
        HttpClientConnector clientConnector = (HttpClientConnector) clientObj.getNativeData(HttpConstants.CLIENT);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, handleObj, null);
            ResponseHandle responseHandle = (ResponseHandle) handleObj.getNativeData(HttpConstants.TRANSPORT_HANDLE);
            if (responseHandle == null) {
                throw HttpUtil.createHttpError("invalid http handle");
            }
            clientConnector.getNextPushPromise(responseHandle).setPushPromiseListener(new PromiseListener(dataContext));
            return getResult(balFuture);
        });
    }

    private static class PromiseListener implements HttpClientConnectorListener {

        private DataContext dataContext;

        PromiseListener(DataContext dataContext) {
            this.dataContext = dataContext;
        }

        @Override
        public void onPushPromise(Http2PushPromise pushPromise) {
            BObject pushPromiseObj =
                    ValueCreator.createObjectValue(ModuleUtils.getHttpPackage(),
                                                   HttpConstants.PUSH_PROMISE,
                                                   StringUtils.fromString(pushPromise.getPath()),
                                                   StringUtils.fromString(pushPromise.getMethod()));
            HttpUtil.populatePushPromiseStruct(pushPromiseObj, pushPromise);
            dataContext.notifyInboundResponseStatus(pushPromiseObj, null);
        }
    }

    private GetNextPromise() {
    }
}
