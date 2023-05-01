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

import static io.ballerina.stdlib.http.api.HttpConstants.PATH_PARAM;

/**
 * {@code {@link PathParam }} represents a path parameter details.
 */
public class PathParam {

    private final String token;
    private final int index;
    private final Type originalType;
    private final int effectiveTypeTag;
    private final boolean isArray;

    PathParam(Type originalType, String token, int index) {
        this.originalType = originalType;
        this.token = token;
        this.index = index;
        this.effectiveTypeTag = ParamUtils.getEffectiveTypeTag(originalType, originalType, PATH_PARAM);
        this.isArray = ParamUtils.isArrayType(originalType);
    }

    public String getToken() {
        return token;
    }

    public int getIndex() {
        return index * 2;
    }

    public Type getOriginalType() {
        return originalType;
    }

    public int getEffectiveTypeTag() {
        return effectiveTypeTag;
    }

    public boolean isArray() {
        return isArray;
    }
}
