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
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.nativeimpl.ExternUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_PARAM;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_HEADER_VALIDATION_LISTENER_ERROR;

/**
 * {@code {@link HeaderParam }} represents a inbound request header parameter details.
 *
 * @since sl-alpha3
 */
public class HeaderParam extends SignatureParam {

    private String headerName;
    private HeaderRecordParam recordParam;
    private boolean nilable;

    HeaderParam(String token) {
        super(token);
    }

    public void initHeaderParam(Type originalType, int index, boolean requireConstraintValidation) {
        init(originalType, index, requireConstraintValidation);
        this.nilable = originalType.isNilable();
        populateHeaderParamTypeTag(originalType);
    }

    private void populateHeaderParamTypeTag(Type type) {
        RecordType headerRecordType = ParamUtils.getRecordType(type);
        if (headerRecordType != null) {
            setEffectiveTypeTag(RECORD_TYPE_TAG);
            Map<String, Field> recordFields = headerRecordType.getFields();
            List<String> keys = new ArrayList<>();
            HeaderRecordParam.FieldParam[] fields = new HeaderRecordParam.FieldParam[recordFields.size()];
            int i = 0;
            for (Map.Entry<String, Field> field : recordFields.entrySet()) {
                keys.add(ExternUtils.getName(StringUtils.fromString(field.getKey()), headerRecordType,
                        ANN_NAME_HEADER).getValue());
                fields[i++] = new HeaderRecordParam.FieldParam(field.getValue().getFieldType());
            }
            this.recordParam = new HeaderRecordParam(getToken(), headerRecordType, keys, fields);
        } else {
            setEffectiveTypeTag(ParamUtils.getEffectiveTypeTag(getOriginalType(), getOriginalType(), HEADER_PARAM));
            setArray(ParamUtils.isArrayType(getOriginalType()));
        }
    }

    public boolean isNilable() {
        return this.nilable;
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

    public Object validateConstraints(Object headerValue) {
        if (requireConstraintValidation()) {
            Object result = Constraints.validateAfterTypeConversion(headerValue, getOriginalType());
            if (result instanceof BError) {
                String message = "header validation failed: " + HttpUtil.getPrintableErrorMsg((BError) result);
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_HEADER_VALIDATION_LISTENER_ERROR, message);
            }
        }
        return headerValue;
    }
}
