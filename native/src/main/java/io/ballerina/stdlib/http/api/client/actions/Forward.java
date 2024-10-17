/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.client.actions;

import io.ballerina.runtime.api.Environment;
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

import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static io.ballerina.stdlib.http.api.HttpUtil.checkRequestBodySizeHeadersAvailability;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code Forward} action can be used to invoke an http call with incoming request httpVerb.
 */
public class Forward extends AbstractHTTPAction {
    @SuppressWarnings("unchecked")
    public static Object forward(Environment env, BObject httpClient, BString path, BObject requestObj) {
        String url = (String) httpClient.getNativeData(CLIENT_ENDPOINT_SERVICE_URI);
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(url, path.getValue(), requestObj);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, requestObj, outboundRequestMsg);
            executeNonBlockingAction(dataContext, false);
            return getResult(balFuture);
        });
    }

    protected static HttpCarbonMessage createOutboundRequestMsg(String serviceUri, String path, BObject requestObj) {
        if (requestObj.getNativeData(HttpConstants.REQUEST) == null &&
                !HttpUtil.isEntityDataSourceAvailable(requestObj)) {
            throw HttpUtil.createHttpError("invalid inbound request parameter",
                    HttpErrorType.GENERIC_CLIENT_ERROR);
        }
        HttpCarbonMessage outboundRequestMsg = HttpUtil
                .getCarbonMsg(requestObj, HttpUtil.createHttpCarbonMessage(true));

        if (HttpUtil.isEntityDataSourceAvailable(requestObj)) {
            HttpUtil.enrichOutboundMessage(outboundRequestMsg, requestObj);
            prepareOutboundRequest(serviceUri, path, outboundRequestMsg,
                    !checkRequestBodySizeHeadersAvailability(outboundRequestMsg), isHostHeaderSet(requestObj));
            outboundRequestMsg.setHttpMethod(requestObj.get(HttpConstants.HTTP_REQUEST_METHOD).toString());
        } else {
            prepareOutboundRequest(serviceUri, path, outboundRequestMsg,
                    !checkRequestBodySizeHeadersAvailability(outboundRequestMsg), isHostHeaderSet(requestObj));
            String httpVerb = outboundRequestMsg.getHttpMethod();
            outboundRequestMsg.setHttpMethod(httpVerb.trim().toUpperCase(Locale.getDefault()));
        }
        return outboundRequestMsg;
    }

    private Forward() {
    }
}
