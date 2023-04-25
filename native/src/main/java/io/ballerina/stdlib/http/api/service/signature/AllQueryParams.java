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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.runtime.api.TypeTags.UNION_TAG;
import static io.ballerina.stdlib.http.api.HttpErrorType.QUERY_PARAM_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParam;

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
                    String message = "no query param value found for '" + token + "'";
                    throw HttpUtil.createHttpStatusCodeError(QUERY_PARAM_BINDING_ERROR, message);
                }
            }

            try {
                BArray queryValueArr = (BArray) queryValue;
                Type paramType = TypeUtils.getReferredType(queryParam.getType());
                if (paramType.getTag() == ARRAY_TAG) {
                    Type elementType = ((ArrayType) paramType).getElementType();
                    BArray paramArray;
                    if (isEnumQueryParamType(elementType)) {
                        paramArray = ValueCreator.createArrayValue((ArrayType) paramType);
                        for (int i = 0; i < queryValueArr.size(); i++) {
                            paramArray.append(castEnumQueryParam((UnionType) elementType, queryValueArr.getBString(i),
                                    token));
                        }
                    } else {
                        paramArray = ParamUtils.castParamArray(TypeUtils.getReferredType(elementType),
                                queryValueArr.getStringArray());
                    }
                    if (queryParam.isReadonly()) {
                        paramArray.freezeDirect();
                    }
                    paramFeed[index++] = paramArray;
                } else if (paramType.getTag() == MAP_TAG || paramType.getTag() == RECORD_TYPE_TAG) {
                    Object json = JsonUtils.parse(queryValueArr.getBString(0).getValue());
                    Object param =  ValueUtils.convert(json, paramType);
                    if (queryParam.isReadonly() && param instanceof BRefValue) {
                        ((BRefValue) param).freezeDirect();
                    }
                    paramFeed[index++] = param;
                } else if (isEnumQueryParamType(paramType)) {
                    Object param = castEnumQueryParam((UnionType) paramType, queryValueArr.getBString(0), token);
                    paramFeed[index++] = param;
                } else {
                    Object param = castParam(paramType.getTag(), queryValueArr.getBString(0).getValue());
                    paramFeed[index++] = param;
                }
                paramFeed[index] = true;
            } catch (Exception ex) {
                String message = "error in casting query param : '" + token + "'";
                throw HttpUtil.createHttpStatusCodeError(QUERY_PARAM_BINDING_ERROR, message, null,
                        HttpUtil.createError(ex));
            }
        }
    }

    private boolean isEnumQueryParamType(Type paramType) {
        return TypeUtils.getReferredType(paramType).getTag() == UNION_TAG &&
                ((UnionType) paramType).getMemberTypes()
                        .stream().allMatch(type -> type.getTag() == TypeTags.FINITE_TYPE_TAG);
    }

    private Object castEnumQueryParam(UnionType paramType, BString queryValue, String token) {
        if (paramType.getMemberTypes().stream().anyMatch(memberType ->
                ((FiniteType) memberType).getValueSpace().contains(queryValue))) {
            return queryValue;
        }
        throw new IllegalArgumentException("query param value '" + token + "' does not match enum type");
    }
}
