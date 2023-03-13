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
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParam;
import static io.ballerina.stdlib.http.api.service.signature.ParamUtils.castParamArray;

/**
 * {@code {@link AllHeaderParams }} holds all the header parameters in the resource signature.
 *
 * @since sl-alpha3
 */
public class AllHeaderParams implements Parameter {

    private final List<HeaderParam> allHeaderParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HttpConstants.HEADER_PARAM;
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
                paramFeed[index++] = recordValue;
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
            int typeTag = headerParam.getType().getTag();
            try {
                if (typeTag == ARRAY_TAG) {
                    int elementTypeTag = ((ArrayType) headerParam.getType()).getElementType().getTag();
                    BArray bArray = castParamArray(elementTypeTag, headerValues.toArray(new String[0]));
                    if (headerParam.isReadonly()) {
                        bArray.freezeDirect();
                    }
                    paramFeed[index++] = bArray;
                } else {
                    paramFeed[index++] = castParam(typeTag, headerValues.get(0));
                }
            } catch (Exception ex) {
                String message = "header binding failed for parameter: '" + token + "'";
                throw HttpUtil.createHttpStatusCodeError(HEADER_BINDING_ERROR, message, null,
                        HttpUtil.createError(ex));
            }
            paramFeed[index] = true;
        }
    }

    private BMap<BString, Object> processHeaderRecord(HeaderParam headerParam, HttpHeaders httpHeaders,
                                                      boolean treatNilableAsOptional) {
        HeaderRecordParam headerRecordParam = headerParam.getRecordParam();
        RecordType recordType = headerRecordParam.getType();
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
            if (fieldType.getTag() == ARRAY_TAG) {
                int elementTypeTag = ((ArrayType) fieldType).getElementType().getTag();
                BArray paramArray = castParamArray(elementTypeTag, headerValues.toArray(new String[0]));
                if (field.isReadonly()) {
                    paramArray.freezeDirect();
                }
                recordValue.put(StringUtils.fromString(key), paramArray);
            } else {
                recordValue.put(StringUtils.fromString(key), castParam(fieldType.getTag(), headerValues.get(0)));
            }
        }
        if (headerParam.isReadonly()) {
            recordValue.freezeDirect();
        }
        return recordValue;
    }
}
