/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpResourceArguments;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.Resource;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.api.HttpConstants.EXTRA_PATH_INDEX;
import static io.ballerina.stdlib.http.api.HttpConstants.PERCENTAGE;
import static io.ballerina.stdlib.http.api.HttpConstants.PERCENTAGE_ENCODED;
import static io.ballerina.stdlib.http.api.HttpConstants.PLUS_SIGN;
import static io.ballerina.stdlib.http.api.HttpConstants.PLUS_SIGN_ENCODED;
import static io.ballerina.stdlib.http.api.HttpErrorType.RESOURCE_NOT_FOUND_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParamArray;

/**
 * {@code {@link AllPathParams }} holds all the path parameters in the resource signature.
 */
public class AllPathParams implements Parameter {

    private final List<PathParam> allPathParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HttpConstants.PATH_PARAM;
    }

    public void add(PathParam pathParam) {
        allPathParams.add(pathParam);
    }

    public boolean isNotEmpty() {
        return !allPathParams.isEmpty();
    }

    public void populateFeed(Object[] paramFeed, HttpCarbonMessage httpCarbonMessage, Resource resource) {
        if (allPathParams.isEmpty()) {
            return;
        }
        HttpResourceArguments resourceArgumentValues =
                (HttpResourceArguments) httpCarbonMessage.getProperty(HttpConstants.RESOURCE_ARGS);
        updateWildcardToken(resource.getWildcardToken(), allPathParams.size() - 1, resourceArgumentValues.getMap());
        for (PathParam pathParam : allPathParams) {
            String paramToken = pathParam.getToken();
            Type paramType = pathParam.getOriginalType();
            int paramTypeTag = pathParam.getEffectiveTypeTag();
            int index = pathParam.getIndex();
            String argumentValue = resourceArgumentValues.getMap().get(paramToken).get(index / 2);
            if (argumentValue.endsWith(PERCENTAGE)) {
                argumentValue = argumentValue.replaceAll(PERCENTAGE, PERCENTAGE_ENCODED);
            }

            Object castedPathValue;
            try {
                Object parsedValue;
                if (pathParam.isArray()) {
                    String[] segments = Stream.of(argumentValue.substring(1).split(HttpConstants.SINGLE_SLASH))
                            .map(AllPathParams::decodePathSegment).toArray(String[]::new);
                    parsedValue = castParamArray(paramTypeTag, segments);
                } else {
                    parsedValue = castParam(paramTypeTag, decodePathSegment(argumentValue));
                }
                castedPathValue = ValueUtils.convert(parsedValue, paramType);
            } catch (Exception ex) {
                String message = "error in casting path parameter : '" + paramToken + "'";
                if (ParamUtils.isFiniteType(paramType)) {
                    message = "no matching resource found for path : " +
                            httpCarbonMessage.getProperty(HttpConstants.TO) +
                            " , method : " + httpCarbonMessage.getHttpMethod();
                    throw HttpUtil.createHttpStatusCodeError(RESOURCE_NOT_FOUND_ERROR, message);
                } else {
                    throw HttpUtil.createHttpStatusCodeError(HttpErrorType.PATH_PARAM_BINDING_ERROR, message,
                            null, HttpUtil.createError(ex));
                }
            }

            paramFeed[index++] = pathParam.validateConstraints(castedPathValue);
            paramFeed[index] = true;
        }
    }

    private static String decodePathSegment(String pathSegment) {
        return URLDecoder.decode(pathSegment.replaceAll(PLUS_SIGN, PLUS_SIGN_ENCODED), StandardCharsets.UTF_8);
    }

    private static void updateWildcardToken(String wildcardToken, int wildCardIndex,
                                            Map<String, Map<Integer, String>> arguments) {
        if (wildcardToken == null) {
            return;
        }
        String wildcardPathSegment = arguments.get(HttpConstants.EXTRA_PATH_INFO).get(EXTRA_PATH_INDEX);
        if (arguments.containsKey(wildcardToken)) {
            Map<Integer, String> indexValueMap = arguments.get(wildcardToken);
            indexValueMap.put(wildCardIndex, wildcardPathSegment);
        } else {
            arguments.put(wildcardToken, Collections.singletonMap(wildCardIndex, wildcardPathSegment));
        }
    }
}
