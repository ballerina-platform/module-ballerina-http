/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BNever;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_QUERY_PARAM_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParamArray;

/**
 * {@code {@link AllQueryParams }} holds all the query parameters in the resource signature.
 *
 * @since slp8
 */
public class AllQueryParams implements Parameter {

    private final List<QueryParam> allQueryParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HttpConstants.QUERY_PARAM;
    }

    public void add(QueryParam queryParam) {
        allQueryParams.add(queryParam);
    }

    boolean isNotEmpty() {
        return !allQueryParams.isEmpty();
    }

    public void populateFeed(HttpCarbonMessage httpCarbonMessage, ParamHandler paramHandler, Object[] paramFeed,
                             boolean treatNilableAsOptional) {
        BMap<BString, Object> urlQueryParams = paramHandler
                .getQueryParams(httpCarbonMessage.getProperty(HttpConstants.RAW_QUERY_STR));
        for (QueryParam queryParam : allQueryParams) {
            String token = queryParam.getToken();
            int index = queryParam.getIndex();
            boolean queryExist = urlQueryParams.containsKey(StringUtils.fromString(token));
            Object queryValue = urlQueryParams.get(StringUtils.fromString(token));
            if (queryValue == null) {
                if (queryParam.isDefaultable()) {
                    queryParam.validateConstraints(queryParam.getOriginalType().getZeroValue());
                    paramFeed[index] = BNever.getValue();
                    continue;
                } else if (queryParam.isNilable() && (treatNilableAsOptional || queryExist)) {
                    paramFeed[index] = null;
                    continue;
                } else {
                    String message = "no query param value found for '" + token + "'";
                    throw HttpUtil.createHttpStatusCodeError(INTERNAL_QUERY_PARAM_BINDING_ERROR, message);
                }
            }
            Object castedQueryValue;
            try {
                BArray queryValueArr = (BArray) queryValue;
                Object parsedQueryValue;
                if (queryParam.isArray()) {
                    parsedQueryValue = castParamArray(queryParam.getEffectiveTypeTag(),
                            queryValueArr.getStringArray());
                } else {
                    parsedQueryValue = castParam(queryParam.getEffectiveTypeTag(),
                            queryValueArr.getBString(0).getValue());
                }
                castedQueryValue = ValueUtils.convert(parsedQueryValue, queryParam.getOriginalType());
            } catch (Exception ex) {
                String message = "error in casting query param : '" + token + "'";
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_QUERY_PARAM_BINDING_ERROR, message, null,
                        HttpUtil.createError(ex));
            }

            paramFeed[index] = queryParam.validateConstraints(castedQueryValue);
        }
    }
}
