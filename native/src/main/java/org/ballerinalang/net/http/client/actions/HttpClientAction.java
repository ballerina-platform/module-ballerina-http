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

package org.ballerinalang.net.http.client.actions;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import org.ballerinalang.net.http.DataContext;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpErrorType;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.message.Http2PushPromise;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import java.util.HashMap;
import java.util.Map;

import static io.ballerina.runtime.observability.ObservabilityConstants.KEY_OBSERVER_CONTEXT;
import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static org.ballerinalang.net.http.HttpConstants.CURRENT_TRANSACTION_CONTEXT_PROPERTY;
import static org.ballerinalang.net.http.HttpConstants.ORIGIN_HOST;
import static org.ballerinalang.net.http.HttpConstants.POOLED_BYTE_BUFFER_FACTORY;
import static org.ballerinalang.net.http.HttpConstants.REMOTE_ADDRESS;
import static org.ballerinalang.net.http.HttpConstants.SRC_HANDLER;

/**
 * Utilities related to HTTP client actions.
 *
 * @since 1.1.0
 */
public class HttpClientAction extends AbstractHTTPAction {

    public static Object executeClientAction(Environment env, BObject httpClient, BString path,
                                             BObject requestObj, BString httpMethod) {
        String url = (String) httpClient.getNativeData(CLIENT_ENDPOINT_SERVICE_URI);
        BMap<BString, Object> config = (BMap<BString, Object>) httpClient.getNativeData(CLIENT_ENDPOINT_CONFIG);
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

    public static Object post(Environment env, BObject client, BString path, Object message, Object headers,
                              Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPost");
    }

    public static Object put(Environment env, BObject client, BString path, Object message, Object headers,
                             Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPut");
    }

    public static Object patch(Environment env, BObject client, BString path, Object message, Object headers,
                               Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPatch");
    }

    public static Object delete(Environment env, BObject client, BString path, Object message, Object headers,
                                Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processDelete");
    }

    public static Object get(Environment env, BObject client, BString path, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, headers, targetType, "processGet");
    }

    public static Object options(Environment env, BObject client, BString path, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, headers, targetType, "processOptions");
    }

    public static Object execute(Environment env, BObject client, BString httpVerb, BString path, Object message,
                                 Object headers, Object mediaType, BTypedesc targetType) {
        Object[] paramFeed = new Object[12];
        paramFeed[0] = httpVerb;
        paramFeed[1] = true;
        paramFeed[2] = path;
        paramFeed[3] = true;
        paramFeed[4] = message;
        paramFeed[5] = true;
        paramFeed[6] = targetType;
        paramFeed[7] = true;
        paramFeed[8] = mediaType;
        paramFeed[9] = true;
        paramFeed[10] = headers;
        paramFeed[11] = true;
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

    private static Object invokeClientMethod(Environment env, BObject client, BString path, Object message,
                                             Object mediaType, Object headers, BTypedesc targetType,
                                             String methodName) {
        Object[] paramFeed = new Object[10];
        paramFeed[0] = path;
        paramFeed[1] = true;
        paramFeed[2] = message;
        paramFeed[3] = true;
        paramFeed[4] = targetType;
        paramFeed[5] = true;
        paramFeed[6] = mediaType;
        paramFeed[7] = true;
        paramFeed[8] = headers;
        paramFeed[9] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        Future balFuture = env.markAsync();
        Map<String, Object> propertyMap = getPropertiesToPropagate(env);
        env.getRuntime().invokeMethodAsync(client, methodName, null, null, new Callback() {
            @Override
            public void notifySuccess(Object result) {
                balFuture.complete(result);
            }

            @Override
            public void notifyFailure(BError bError) {
                BError invocationError =
                        HttpUtil.createHttpError("client method invocation failed: " + bError.getErrorMessage(),
                                                 HttpErrorType.CLIENT_ERROR, bError);
                balFuture.complete(invocationError);
            }
        }, propertyMap, PredefinedTypes.TYPE_NULL, paramFeed);
        return null;
    }

    private static Map<String, Object> getPropertiesToPropagate(Environment env) {
        String[] keys = {CURRENT_TRANSACTION_CONTEXT_PROPERTY, KEY_OBSERVER_CONTEXT, SRC_HANDLER,
                POOLED_BYTE_BUFFER_FACTORY, REMOTE_ADDRESS, ORIGIN_HOST};
        Map<String, Object> subMap = new HashMap<>();
        for (String key : keys) {
            Object value = env.getStrandLocal(key);
            if (value != null) {
                subMap.put(key, value);
            }
        }
        return subMap;
    }

    private HttpClientAction() {
    }
}
