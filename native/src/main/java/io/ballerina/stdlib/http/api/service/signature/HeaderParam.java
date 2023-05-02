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

import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_PARAM;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_VALIDATION_ERROR;

/**
 * {@code {@link HeaderParam }} represents a inbound request header parameter details.
 *
 * @since sl-alpha3
 */
public class HeaderParam {

    private final String token;
    private int index;
    private Type originalType;
    private String headerName;
    private HeaderRecordParam recordParam;
    private int effectiveTypeTag;
    private boolean nilable;
    private boolean isArray;
    private boolean requireConstraintValidation;

    HeaderParam(String token) {
        this.token = token;
    }

    public void init(Type originalType, int index, boolean requireConstraintValidation) {
        this.originalType = originalType;
        this.index = index;
        this.nilable = originalType.isNilable();
        this.requireConstraintValidation = requireConstraintValidation;
        populateHeaderParamTypeTag(originalType);
    }

    private void populateHeaderParamTypeTag(Type type) {
        RecordType headerRecordType = ParamUtils.getRecordType(type);
        if (headerRecordType != null) {
            this.effectiveTypeTag = RECORD_TYPE_TAG;
            Map<String, Field> recordFields = headerRecordType.getFields();
            List<String> keys = new ArrayList<>();
            HeaderRecordParam.FieldParam[] fields = new HeaderRecordParam.FieldParam[recordFields.size()];
            int i = 0;
            for (Map.Entry<String, Field> field : recordFields.entrySet()) {
                keys.add(field.getKey());
                fields[i++] = new HeaderRecordParam.FieldParam(field.getValue().getFieldType());
            }
            this.recordParam = new HeaderRecordParam(this.token, headerRecordType, keys, fields);
        } else {
            this.effectiveTypeTag = ParamUtils.getEffectiveTypeTag(this.originalType, this.originalType, HEADER_PARAM);
            this.isArray = ParamUtils.isArrayType(originalType);
        }
    }

    public Type getOriginalType() {
        return this.originalType;
    }

    public String getToken() {
        return this.token;
    }

    public boolean isNilable() {
        return this.nilable;
    }

    public int getIndex() {
        return this.index * 2;
    }

    public String getHeaderName() {
        return this.headerName;
    }

    void setHeaderName(String headerName) {
        this.headerName = headerName;
    }

    public HeaderRecordParam getRecordParam() {
        return this.recordParam;
    }

    public boolean isRecord() {
        return getRecordParam() != null;
    }

    public boolean isArray() {
        return this.isArray;
    }

    public int getEffectiveTypeTag() {
        return this.effectiveTypeTag;
    }

    public Object constraintValidation(Object headerValue) {
        if (requireConstraintValidation) {
            Object result = Constraints.validateAfterTypeConversion(headerValue, originalType);
            if (result instanceof BError) {
                String message = "header validation failed: " + HttpUtil.getPrintableErrorMsg((BError) result);
                throw HttpUtil.createHttpStatusCodeError(HEADER_VALIDATION_ERROR, message);
            }
        }
        return headerValue;
    }
}
