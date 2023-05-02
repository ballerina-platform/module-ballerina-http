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

import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.http.api.HttpUtil;

import static io.ballerina.stdlib.http.api.HttpConstants.QUERY_PARAM;
import static io.ballerina.stdlib.http.api.HttpErrorType.QUERY_PARAM_VALIDATION_ERROR;

/**
 * {@code {@link QueryParam }} represents a query parameter details.
 *
 * @since slp8
 */
public class QueryParam {

    private final String token;
    private final boolean nilable;
    private final boolean defaultable;
    private final int index;
    private final Type originalType;
    private final int effectiveTypeTag;
    private final boolean isArray;
    private final boolean requireConstraintValidation;

    QueryParam(Type originalType, String token, int index, boolean defaultable, boolean requireConstraintValidation) {
        this.originalType = originalType;
        this.token = token;
        this.index = index;
        this.nilable = originalType.isNilable();
        this.defaultable = defaultable;
        this.effectiveTypeTag = ParamUtils.getEffectiveTypeTag(originalType, originalType, QUERY_PARAM);
        this.isArray = ParamUtils.isArrayType(originalType);
        this.requireConstraintValidation = requireConstraintValidation;
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

    public Type getOriginalType() {
        return this.originalType;
    }

    public boolean isDefaultable() {
        return defaultable;
    }

    public int getEffectiveTypeTag() {
        return effectiveTypeTag;
    }

    public boolean isArray() {
        return isArray;
    }

    public Object constraintValidation(Object queryValue) {
        if (requireConstraintValidation) {
            Object result = Constraints.validateAfterTypeConversion(queryValue, originalType);
            if (result instanceof BError) {
                String message = "query validation failed: " + HttpUtil.getPrintableErrorMsg((BError) result);
                throw HttpUtil.createHttpStatusCodeError(QUERY_PARAM_VALIDATION_ERROR, message);
            }
        }
        return queryValue;
    }
}
