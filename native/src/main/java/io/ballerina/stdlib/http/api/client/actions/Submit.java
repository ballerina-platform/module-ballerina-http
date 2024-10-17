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
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code Submit} action can be used to invoke a http call with any httpVerb in asynchronous manner.
 */
public class Submit extends Execute {
    @SuppressWarnings("unchecked")
    public static Object submit(Environment env, BObject httpClient, BString httpVerb, BString path,
                                BObject requestObj) {
        String url = (String) httpClient.getNativeData(CLIENT_ENDPOINT_SERVICE_URI);
        BMap<BString, Object> config = (BMap<BString, Object>) httpClient.getNativeData(CLIENT_ENDPOINT_CONFIG);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(url, config, path.getValue(), requestObj);
        outboundRequestMsg.setHttpMethod(httpVerb.getValue());
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, requestObj, outboundRequestMsg);
            executeNonBlockingAction(dataContext, true);
            return getResult(balFuture);
        });
    }
}
