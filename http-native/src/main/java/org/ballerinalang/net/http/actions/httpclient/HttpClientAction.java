/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.http.actions.httpclient;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import org.ballerinalang.net.http.DataContext;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.message.Http2PushPromise;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;

/**
 * Utilities related to HTTP client actions.
 *
 * @since 1.1.0
 */
public class HttpClientAction extends AbstractHTTPAction {

    public static Object executeClientAction(Environment env, BObject httpClient, BString path,
                                             BObject requestObj, BString httpMethod) {
        String url = httpClient.getStringValue(CLIENT_ENDPOINT_SERVICE_URI).getValue();
        BMap<BString, Object> config = (BMap<BString, Object>) httpClient.get(CLIENT_ENDPOINT_CONFIG);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(url, config, path.getValue().
                replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH), requestObj);
        outboundRequestMsg.setHttpMethod(httpMethod.getValue());
        DataContext dataContext = new DataContext(env, clientConnector, requestObj, outboundRequestMsg);
        executeNonBlockingAction(dataContext, false);
        return null;
    }

    public static void rejectPromise(BObject clientObj, BObject pushPromiseObj) {
        Http2PushPromise http2PushPromise = HttpUtil.getPushPromise(pushPromiseObj, null);
        if (http2PushPromise == null) {
            throw HttpUtil.createHttpError("invalid push promise");
        }
        HttpClientConnector clientConnector = (HttpClientConnector) clientObj.getNativeData(HttpConstants.CLIENT);
        clientConnector.rejectPushResponse(http2PushPromise);
    }

    public static Object post(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processPost");
    }

    public static Object put(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processPut");
    }

    public static Object patch(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processPatch");
    }

    public static Object delete(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processDelete");
    }

    public static Object get(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processGet");
    }

    public static Object options(Environment env, BObject client, BString path, Object message, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, targetType, "processOptions");
    }

    public static Object execute(Environment env, BObject client, BString httpVerb, BString path, Object message,
                                 BTypedesc targetType) {
        Object[] paramFeed = new Object[8];
        paramFeed[0] = httpVerb;
        paramFeed[1] = true;
        paramFeed[2] = path;
        paramFeed[3] = true;
        paramFeed[4] = message;
        paramFeed[5] = true;
        paramFeed[6] = targetType;
        paramFeed[7] = true;
        return invokeClientMethod(env, client, "processExecute", paramFeed);
    }

    public static Object forward(Environment env, BObject client, BString path, BObject message, BTypedesc targetType) {
        Object[] paramFeed = new Object[6];
        paramFeed[0] = path;
        paramFeed[1] = true;
        paramFeed[2] = message;
        paramFeed[3] = true;
        paramFeed[4] = targetType;
        paramFeed[5] = true;
        return invokeClientMethod(env, client, "processForward", paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, BString path, Object message,
                                             BTypedesc targetType, String methodName) {
        Object[] paramFeed = new Object[6];
        paramFeed[0] = path;
        paramFeed[1] = true;
        paramFeed[2] = message;
        paramFeed[3] = true;
        paramFeed[4] = targetType;
        paramFeed[5] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        Future balFuture = env.markAsync();
        env.getRuntime().invokeMethodAsync(client, methodName, null, null, new Callback() {
            @Override
            public void notifySuccess(Object result) {
                balFuture.complete(result);
            }

            @Override
            public void notifyFailure(BError bError) {
                balFuture.complete(bError);
            }
        }, paramFeed);
        return null;
    }
}
