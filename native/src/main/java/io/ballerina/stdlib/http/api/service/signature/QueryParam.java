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
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_QUERY_PARAM_VALIDATION_ERROR;

/**
 * {@code {@link QueryParam }} represents a query parameter details.
 *
 * @since slp8
 */
public class QueryParam extends SignatureParam {
    private final boolean nilable;
    private final boolean defaultable;

    QueryParam(Type originalType, String token, int index, boolean defaultable, boolean requireConstraintValidation) {
        super(originalType, token, index, requireConstraintValidation, QUERY_PARAM);
        this.nilable = originalType.isNilable();
        this.defaultable = defaultable;
    }

    public boolean isNilable() {
        return this.nilable;
    }

    public boolean isDefaultable() {
        return defaultable;
    }

    public Object validateConstraints(Object queryValue) {
        if (requireConstraintValidation()) {
            Object result = Constraints.validateAfterTypeConversion(queryValue, getOriginalType());
            if (result instanceof BError) {
                String message = "query validation failed: " + HttpUtil.getPrintableErrorMsg((BError) result);
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_QUERY_PARAM_VALIDATION_ERROR, message);
            }
        }
        return queryValue;
    }
}
