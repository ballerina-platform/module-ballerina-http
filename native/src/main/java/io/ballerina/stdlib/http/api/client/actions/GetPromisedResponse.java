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
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code GetPromisedResponse} action can be used to get a push response message associated with a
 * previous asynchronous invocation.
 */
public class GetPromisedResponse extends AbstractHTTPAction {

    public static Object getPromisedResponse(Environment env, BObject clientObj, BObject pushPromiseObj) {
        HttpClientConnector clientConnector = (HttpClientConnector) clientObj.getNativeData(HttpConstants.CLIENT);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, pushPromiseObj, null);
            Http2PushPromise http2PushPromise = HttpUtil.getPushPromise(pushPromiseObj, null);
            if (http2PushPromise == null) {
                throw HttpUtil.createHttpError("invalid push promise");
            }
            clientConnector.getPushResponse(http2PushPromise).
                    setPushResponseListener(new PushResponseListener(dataContext),
                            http2PushPromise.getPromisedStreamId());
            return getResult(balFuture);
        });
    }

    private static class PushResponseListener implements HttpClientConnectorListener {

        private DataContext dataContext;

        PushResponseListener(DataContext dataContext) {
            this.dataContext = dataContext;
        }

        @Override
        public void onPushResponse(int promisedId, HttpCarbonMessage httpCarbonMessage) {
            dataContext.notifyInboundResponseStatus(
                    HttpUtil.createResponseStruct(httpCarbonMessage), null);
        }

        @Override
        public void onError(Throwable throwable) {
            BError httpConnectorError = HttpUtil.createHttpError(throwable.getMessage());
            dataContext.notifyInboundResponseStatus(null, httpConnectorError);
        }
    }

    private GetPromisedResponse() {
    }
}
