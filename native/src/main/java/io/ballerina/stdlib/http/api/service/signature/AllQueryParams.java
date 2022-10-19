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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParam;

/**
 * {@code {@link AllQueryParams }} holds all the query parameters in the resource signature.
 *
 * @since slp8
 */
public class AllQueryParams implements Parameter {

    private final List<QueryParam> allQueryParams = new ArrayList<>();
    private static final MapType MAP_TYPE = TypeCreator.createMapType(PredefinedTypes.TYPE_JSON);

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

    public List<QueryParam> getAllQueryParams() {
        return this.allQueryParams;
    }

    public void populateFeed(HttpCarbonMessage httpCarbonMessage, ParamHandler paramHandler, Object[] paramFeed,
                             boolean treatNilableAsOptional) {
        BMap<BString, Object> urlQueryParams = paramHandler
                .getQueryParams(httpCarbonMessage.getProperty(HttpConstants.RAW_QUERY_STR));
        for (QueryParam queryParam : this.getAllQueryParams()) {
            String token = queryParam.getToken();
            int index = queryParam.getIndex();
            boolean queryExist = urlQueryParams.containsKey(StringUtils.fromString(token));
            Object queryValue = urlQueryParams.get(StringUtils.fromString(token));
            if (queryValue == null) {
                if (queryParam.isDefaultable()) {
                    paramFeed[index++] = queryParam.getType().getZeroValue();
                    paramFeed[index] = false;
                    continue;
                } else if (queryParam.isNilable() && (treatNilableAsOptional || queryExist)) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw HttpUtil.createHttpError("no query param value found for '" + token + "'",
                                                   HttpErrorType.QUERY_PARAM_BINDING_ERROR);
                }
            }
            try {
                BArray queryValueArr = (BArray) queryValue;
                Type paramType = queryParam.getType();
                if (paramType.getTag() == ARRAY_TAG) {
                    Type elementType = ((ArrayType) paramType).getElementType();
                    int elementTypeTag = TypeUtils.getReferredType(elementType).getTag();
                    BArray paramArray = ParamUtils.castParamArray(elementTypeTag, queryValueArr.getStringArray());
                    if (queryParam.isReadonly()) {
                        paramArray.freezeDirect();
                    }
                    paramFeed[index++] = paramArray;
                } else if (paramType.getTag() == MAP_TAG) {
                    Object json = JsonUtils.parse(queryValueArr.getBString(0).getValue());
                    BMap<BString, ?> paramMap =  JsonUtils.convertJSONToMap(json, MAP_TYPE);
                    if (queryParam.isReadonly()) {
                        paramMap.freezeDirect();
                    }
                    paramFeed[index++] = paramMap;
                } else {
                    Object param = castParam(paramType.getTag(), queryValueArr.getBString(0).getValue());
                    paramFeed[index++] = param;
                }
                paramFeed[index] = true;
            } catch (Exception ex) {
                httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                throw HttpUtil.createHttpError("error in casting query param : '" + token + "'",
                                               HttpErrorType.QUERY_PARAM_BINDING_ERROR, HttpUtil.createError(ex));
            }
        }
    }
}
