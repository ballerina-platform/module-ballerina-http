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

/**
 * {@code {@link SignatureParam }} represents a signature parameter details.
 */
public abstract class SignatureParam {

    private final String token;
    private int index;
    private Type originalType;
    private int effectiveTypeTag;
    private boolean isArray;
    private boolean requireConstraintValidation;

    public SignatureParam(String token) {
        this.token = token;
    }

    public SignatureParam(Type originalType, String token, int index,
                          boolean requireConstraintValidation, String paramType) {
        this.originalType = originalType;
        this.token = token;
        this.index = index;
        this.effectiveTypeTag = ParamUtils.getEffectiveTypeTag(originalType, originalType, paramType);
        this.isArray = ParamUtils.isArrayType(originalType);
        this.requireConstraintValidation = requireConstraintValidation;
    }

    public void init(Type originalType, int index, boolean requireConstraintValidation) {
        this.originalType = originalType;
        this.index = index;
        this.requireConstraintValidation = requireConstraintValidation;
    }

    public String getToken() {
        return token;
    }

    public int getIndex() {
        return index;
    }

    public Type getOriginalType() {
        return originalType;
    }

    public void setEffectiveTypeTag(int effectiveTypeTag) {
        this.effectiveTypeTag = effectiveTypeTag;
    }

    public int getEffectiveTypeTag() {
        return effectiveTypeTag;
    }

    public void setArray(boolean array) {
        isArray = array;
    }

    public boolean isArray() {
        return isArray;
    }

    public boolean requireConstraintValidation() {
        return requireConstraintValidation;
    }

    public abstract Object validateConstraints(Object queryValue);
}
