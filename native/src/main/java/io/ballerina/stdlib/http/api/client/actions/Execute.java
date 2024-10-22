/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.Locale;
import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code Execute} action can be used to invoke execute a http call with any httpVerb.
 */
public class Execute extends AbstractHTTPAction {
    @SuppressWarnings("unchecked")
    public static Object execute(Environment env, BObject httpClient, BString verb, BString path, BObject requestObj) {
        String url = (String) httpClient.getNativeData(CLIENT_ENDPOINT_SERVICE_URI);
        BMap<BString, Object> config = (BMap<BString, Object>) httpClient.getNativeData(CLIENT_ENDPOINT_CONFIG);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(config, url, verb.getValue(), path.getValue(),
                requestObj);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, requestObj, outboundRequestMsg);
            executeNonBlockingAction(dataContext, false);
            return getResult(balFuture);
        });
    }

    protected static HttpCarbonMessage createOutboundRequestMsg(BMap<BString, Object> config, String serviceUri,
                                                                String httpVerb, String path, BObject requestObj) {
        HttpCarbonMessage outboundRequestMsg = HttpUtil
                .getCarbonMsg(requestObj, HttpUtil.createHttpCarbonMessage(true));

        HttpUtil.checkEntityAvailability(requestObj);
        HttpUtil.enrichOutboundMessage(outboundRequestMsg, requestObj);
        prepareOutboundRequest(serviceUri, path, outboundRequestMsg, isNoEntityBodyRequest(requestObj),
                isHostHeaderSet(requestObj));

        String verb = "";
        if (!httpVerb.isEmpty()) {
            verb = httpVerb;
        } else if (outboundRequestMsg.getHttpMethod() != null) {
            verb = outboundRequestMsg.getHttpMethod();
        } else {
            throw HttpUtil.createHttpError("HTTP Verb cannot be empty", HttpErrorType.GENERIC_CLIENT_ERROR);
        }
        outboundRequestMsg.setHttpMethod(verb.trim().toUpperCase(Locale.getDefault()));
        handleAcceptEncodingHeader(outboundRequestMsg, getCompressionConfigFromEndpointConfig(config));
        return outboundRequestMsg;
    }
}
