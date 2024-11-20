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

package io.ballerina.stdlib.http.api.client.actions;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.api.HttpConstants.AND_SIGN;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_QUERY;
import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static io.ballerina.stdlib.http.api.HttpConstants.COLON;
import static io.ballerina.stdlib.http.api.HttpConstants.EMPTY;
import static io.ballerina.stdlib.http.api.HttpConstants.EQUAL_SIGN;
import static io.ballerina.stdlib.http.api.HttpConstants.ESCAPE_SLASH;
import static io.ballerina.stdlib.http.api.HttpConstants.QUESTION_MARK;
import static io.ballerina.stdlib.http.api.HttpConstants.QUOTATION_MARK;
import static io.ballerina.stdlib.http.api.HttpConstants.REGEX_FOR_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

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
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, clientConnector, requestObj, outboundRequestMsg);
            executeNonBlockingAction(dataContext, false);
            return getResult(balFuture);
        });
    }

    public static void rejectPromise(BObject clientObj, BObject pushPromiseObj) {
        Http2PushPromise http2PushPromise = HttpUtil.getPushPromise(pushPromiseObj, null);
        if (http2PushPromise == null) {
            throw HttpUtil.createHttpError("invalid push promise");
        }
        HttpClientConnector clientConnector = (HttpClientConnector) clientObj.getNativeData(HttpConstants.CLIENT);
        clientConnector.rejectPushResponse(http2PushPromise);
    }

    public static Object postResource(Environment env, BObject client, BArray path, Object message, Object headers,
                                      Object mediaType, BTypedesc targetType, BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), message, mediaType, headers,
                                  targetType, "processPost");
    }

    public static Object post(Environment env, BObject client, BString path, Object message, Object headers,
                              Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPost");
    }

    public static Object putResource(Environment env, BObject client, BArray path, Object message, Object headers,
                                      Object mediaType, BTypedesc targetType, BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), message, mediaType, headers,
                                  targetType, "processPut");
    }

    public static Object put(Environment env, BObject client, BString path, Object message, Object headers,
                             Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPut");
    }

    public static Object patchResource(Environment env, BObject client, BArray path, Object message, Object headers,
                                      Object mediaType, BTypedesc targetType, BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), message, mediaType, headers,
                                  targetType, "processPatch");
    }

    public static Object patch(Environment env, BObject client, BString path, Object message, Object headers,
                               Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processPatch");
    }

    public static Object deleteResource(Environment env, BObject client, BArray path, Object message, Object headers,
                                      Object mediaType, BTypedesc targetType, BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), message, mediaType, headers,
                                  targetType, "processDelete");
    }

    public static Object delete(Environment env, BObject client, BString path, Object message, Object headers,
                                Object mediaType, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, message, mediaType, headers, targetType, "processDelete");
    }

    public static Object getResource(Environment env, BObject client, BArray path, Object headers, BTypedesc targetType,
                                     BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), headers, targetType, "processGet");
    }

    public static Object get(Environment env, BObject client, BString path, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, headers, targetType, "processGet");
    }

    public static Object headResource(Environment env, BObject client, BArray path, Object headers, BMap params) {
        Object[] paramFeed = new Object[2];
        paramFeed[0] = constructRequestPath(path, params);
        paramFeed[1] = headers;
        return invokeClientMethod(env, client, "head", paramFeed);
    }

    public static Object optionsResource(Environment env, BObject client, BArray path, Object headers,
                                         BTypedesc targetType, BMap params) {
        return invokeClientMethod(env, client, constructRequestPath(path, params), headers, targetType,
                                  "processOptions");
    }

    public static Object options(Environment env, BObject client, BString path, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, headers, targetType, "processOptions");
    }

    public static Object execute(Environment env, BObject client, BString httpVerb, BString path, Object message,
                                 Object headers, Object mediaType, BTypedesc targetType) {
        Object[] paramFeed = new Object[6];
        paramFeed[0] = httpVerb;
        paramFeed[1] = path;
        paramFeed[2] = message;
        paramFeed[3] = targetType;
        paramFeed[4] = mediaType;
        paramFeed[5] = headers;
        return invokeClientMethod(env, client, "processExecute", paramFeed);
    }

    public static Object forward(Environment env, BObject client, BString path, BObject message, BTypedesc targetType) {
        Object[] paramFeed = new Object[3];
        paramFeed[0] = path;
        paramFeed[1] = message;
        paramFeed[2] = targetType;
        return invokeClientMethod(env, client, "processForward", paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, BString path, Object message,
                                             BTypedesc targetType, String methodName) {
        Object[] paramFeed = new Object[3];
        paramFeed[0] = path;
        paramFeed[1] = message;
        paramFeed[2] = targetType;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, BString path, Object message,
                                             Object mediaType, Object headers, BTypedesc targetType,
                                             String methodName) {
        Object[] paramFeed = new Object[5];
        paramFeed[0] = path;
        paramFeed[1] = message;
        paramFeed[2] = targetType;
        paramFeed[3] = mediaType;
        paramFeed[4] = headers;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        return env.yieldAndRun(() -> {
            try {
                return env.getRuntime().callMethod(client, methodName, null, paramFeed);
            } catch (BError bError) {
                return HttpUtil.createHttpError("client method invocation failed: " + bError.getErrorMessage(),
                        HttpErrorType.CLIENT_ERROR, bError);
            }
        });
    }

    private static BString constructRequestPath(BArray pathArray, BMap params) {
        String joinedPath = SINGLE_SLASH + String.join(SINGLE_SLASH, getPathStringArray(pathArray));
        String queryParams = constructQueryString(params);
        if (queryParams.isEmpty()) {
            return StringUtils.fromString(joinedPath);
        } else {
            return StringUtils.fromString(joinedPath + QUESTION_MARK + queryParams);
        }
    }

    private static String[] getPathStringArray(BArray pathArray) {
        int tag = pathArray.getElementType().getTag();
        switch (tag) {
            case TypeTags.STRING_TAG:
                return Arrays.stream(pathArray.getStringArray()).map(String::valueOf).toArray(String[]::new);
            case TypeTags.INT_TAG:
                return Arrays.stream(pathArray.getIntArray()).mapToObj(String::valueOf).toArray(String[]::new);
            case TypeTags.FLOAT_TAG:
                return Arrays.stream(pathArray.getFloatArray()).mapToObj(String::valueOf).toArray(String[]::new);
            case TypeTags.BOOLEAN_TAG:
                boolean[] booleanArray = pathArray.getBooleanArray();
                String[] booleanStringArray = new String[booleanArray.length];
                for (int i = 0; i < booleanArray.length; i++) {
                    booleanStringArray[i] = String.valueOf(booleanArray[i]);
                }
                return booleanStringArray;
            default:
                return Arrays.stream(pathArray.getValues()).filter(Objects::nonNull).map(String::valueOf)
                        .toArray(String[]::new);
        }
    }

    private static String constructQueryString(BMap params) {
        List<String> queryParams = new ArrayList<>();
        Map<String, String> annotationValues = getQueryNameMapping(params);
        BString[] keys = (BString[]) params.getKeys();
        if (keys.length == 0) {
            return "";
        }
        for (BString key : keys) {
            Object value = params.get(key);
            String queryName = key.getValue();
            queryName = annotationValues.getOrDefault(queryName, queryName);
            String valueString = value.toString();
            if (value instanceof BArray) {
                valueString = valueString.substring(1, valueString.length() - 1);
                valueString = valueString.replace(QUOTATION_MARK, EMPTY);
            }
            queryParams.add(queryName + EQUAL_SIGN + valueString);
        }
        return String.join(AND_SIGN, queryParams);
    }

    /**
     * This util function extracts the query name with the query annotation.
     *
     * @param params - Parameter map
     * @return Map of string with overridden query param names
     */
    private static Map<String, String> getQueryNameMapping(BMap params) {
        Map<String, String> annotationValues = new HashMap<>();
        RecordType queryRecord = (RecordType) params.getType();
        BMap<BString, Object> queryFields = queryRecord.getAnnotations();

        for (Map.Entry<BString, Object> qField: queryFields.entrySet()) {
            BMap value = (BMap) qField.getValue();
            Object[] keys = value.getKeys();
            for (Object annotRef: keys) {
                String refRegex = ModuleUtils.getHttpPackageIdentifier() + COLON + ANN_NAME_QUERY;
                Pattern pattern = Pattern.compile(refRegex);
                Matcher matcher = pattern.matcher(annotRef.toString());
                if (matcher.find()) {
                    BMap refValue = (BMap) value.get(annotRef);
                    extractedFieldName(annotationValues, qField, refValue);
                }
            }
        }
        return annotationValues;
    }

    private static void extractedFieldName(Map<String, String> annotationValues, Map.Entry<BString, Object> qField,
                                           BMap value) {
        String[] parts = Pattern.compile(REGEX_FOR_FIELD).split(qField.getKey().getValue());
        String fieldName = unescapeIdentifier(parts[1]);
        Object overrideValue = value.get(HttpConstants.ANN_FIELD_NAME);
        if (!(overrideValue instanceof BString overrideName)) {
            return;
        }
        annotationValues.put(fieldName, overrideName.getValue());
    }

    public static String unescapeIdentifier(String parameterName) {
        return parameterName.replaceAll(ESCAPE_SLASH, EMPTY);
    }

    private HttpClientAction() {
    }
}
