/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_PARAM;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castEnumParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castFiniteParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.isEnumParamType;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.isFiniteParamType;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.parseParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.parseParamArray;

/**
 * {@code {@link AllHeaderParams }} holds all the header parameters in the resource signature.
 *
 * @since sl-alpha3
 */
public class AllHeaderParams implements Parameter {

    private final List<HeaderParam> allHeaderParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HEADER_PARAM;
    }

    public void add(HeaderParam headerParam) {
        allHeaderParams.add(headerParam);
    }

    boolean isNotEmpty() {
        return !allHeaderParams.isEmpty();
    }

    public List<HeaderParam> getAllHeaderParams() {
        return this.allHeaderParams;
    }

    public HeaderParam get(String token) {
        for (HeaderParam headerParam : allHeaderParams) {
            if (token.equals(headerParam.getToken())) {
                return headerParam;
            }
        }
        return null;
    }

    public void populateFeed(HttpCarbonMessage httpCarbonMessage, Object[] paramFeed, boolean treatNilableAsOptional) {
        HttpHeaders httpHeaders = httpCarbonMessage.getHeaders();
        for (HeaderParam headerParam : this.getAllHeaderParams()) {
            int index = headerParam.getIndex();
            if (headerParam.isRecord()) {
                BMap<BString, Object> recordValue = processHeaderRecord(headerParam, httpHeaders,
                        treatNilableAsOptional);
                paramFeed[index++] = ValueUtils.convert(recordValue, headerParam.getOriginalType());
                paramFeed[index] = true;
                continue;
            }
            String token = headerParam.getHeaderName();
            List<String> headerValues = httpHeaders.getAll(token);
            if (headerValues.isEmpty()) {
                if (headerParam.isNilable() && treatNilableAsOptional) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    String message = "no header value found for '" + token + "'";
                    throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message);
                }
            }
            if (headerValues.size() == 1 && headerValues.get(0).isEmpty()) {
                if (headerParam.isNilable()) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    String message = "no header value found for '" + token + "'";
                    throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message);
                }
            }
            Type headerParamType = headerParam.getReferredType();
            Object parsedValue;
            try {
                if (headerParamType.getTag() == ARRAY_TAG) {
                    parsedValue = parseHeaderParamArray(headerParam, token, headerValues, (ArrayType) headerParamType);
                } else {
                    parsedValue = parseHeaderParam(token, headerValues, headerParamType);
                }
                paramFeed[index++] = ValueUtils.convert(parsedValue, headerParam.getOriginalType());
                paramFeed[index] = true;
            } catch (Exception ex) {
                String message = "header binding failed for parameter: '" + token + "'";
                throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message, null,
                        HttpUtil.createError(ex));
            }
        }
    }

    private static Object parseHeaderParam(String token, List<String> headerValues, Type headerParamType) {
        Object parsedValue;
        if (isEnumParamType(headerParamType)) {
            parsedValue = castEnumParam((UnionType) headerParamType,
                    StringUtils.fromString(headerValues.get(0)), token, HEADER_PARAM);
        } else if (isFiniteParamType(headerParamType)) {
            parsedValue = castFiniteParam((FiniteType) headerParamType, headerValues.get(0),
                    token, HEADER_PARAM);
        } else {
            parsedValue = parseParam(headerParamType.getTag(), headerValues.get(0));
        }
        return parsedValue;
    }

    private static Object parseHeaderParamArray(HeaderParam headerParam, String token, List<String> headerValues,
                                                ArrayType headerParamType) {
        Object parsedValue;
        Type elementType = headerParamType.getElementType();
        BArray bArray = ValueCreator.createArrayValue(headerParamType);
        if (isEnumParamType(elementType)) {
            for (String headerValue : headerValues) {
                bArray.append(castEnumParam((UnionType) elementType, StringUtils.fromString(headerValue),
                        token, HEADER_PARAM));
            }
        } else if (isFiniteParamType(elementType)) {
            for (String headerValue : headerValues) {
                bArray.append(castFiniteParam((FiniteType) elementType, headerValue, token, HEADER_PARAM));
            }
        } else {
            bArray = parseParamArray(elementType, headerValues.toArray(new String[0]));
        }

        if (headerParam.isReadonly()) {
            bArray.freezeDirect();
        }
        parsedValue = bArray;
        return parsedValue;
    }

    private BMap<BString, Object> processHeaderRecord(HeaderParam headerParam, HttpHeaders httpHeaders,
                                                      boolean treatNilableAsOptional) {
        HeaderRecordParam headerRecordParam = headerParam.getRecordParam();
        RecordType recordType = headerRecordParam.getReferredType();
        BMap<BString, Object> recordValue = ValueCreator.createRecordValue(recordType);
        List<String> keys = headerRecordParam.getKeys();
        int i = 0;
        for (String key : keys) {
            HeaderRecordParam.FieldParam field = headerRecordParam.getField(i++);
            List<String> headerValues = httpHeaders.getAll(key);
            Type fieldType = field.getType();
            if (headerValues.isEmpty()) {
                if (field.isNilable() && treatNilableAsOptional) {
                    recordValue.put(StringUtils.fromString(key), null);
                    continue;
                } else if (headerParam.isNilable()) {
                    return null;
                } else {
                    String message = "no header value found for '" + key + "'";
                    throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message);
                }
            }
            if (headerValues.size() == 1 && headerValues.get(0).isEmpty()) {
                if (field.isNilable()) {
                    recordValue.put(StringUtils.fromString(key), null);
                    continue;
                } else if (headerParam.isNilable()) {
                    return null;
                } else {
                    String message = "no header value found for '" + key + "'";
                    throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message);
                }
            }
            try {
                if (fieldType.getTag() == ARRAY_TAG) {
                    Type elementType = ((ArrayType) fieldType).getElementType();
                    BArray paramArray = ValueCreator.createArrayValue((ArrayType) fieldType);
                    if (isEnumParamType(elementType)) {
                        for (String headerValue : headerValues) {
                            paramArray.append(castEnumParam((UnionType) elementType,
                                    StringUtils.fromString(headerValue), key, HEADER_PARAM));
                        }
                    } else if (isFiniteParamType(elementType)) {
                        for (String headerValue : headerValues) {
                            paramArray.append(castFiniteParam((FiniteType) elementType, headerValue,
                                    key, HEADER_PARAM));
                        }
                    } else {
                        paramArray = parseParamArray(elementType, headerValues.toArray(new String[0]));
                    }
                    if (field.isReadonly()) {
                        paramArray.freezeDirect();
                    }
                    recordValue.put(StringUtils.fromString(key), paramArray);
                } else {
                    Object parsedValue;
                    if (isEnumParamType(fieldType)) {
                        parsedValue = castEnumParam((UnionType) fieldType, StringUtils.fromString(headerValues.get(0)),
                                key, HEADER_PARAM);
                    } else if (isFiniteParamType(fieldType)) {
                        parsedValue = castFiniteParam((FiniteType) fieldType, headerValues.get(0), key, HEADER_PARAM);
                    } else {
                        parsedValue = parseParam(fieldType.getTag(), headerValues.get(0));
                    }
                    recordValue.put(StringUtils.fromString(key), parsedValue);
                }
            } catch (Exception ex) {
                String message = "header binding failed for parameter: '" + key + "'";
                throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message, null,
                        HttpUtil.createError(ex));
            }
        }
        if (headerParam.isReadonly()) {
            recordValue.freezeDirect();
        }
        return recordValue;
    }
}
