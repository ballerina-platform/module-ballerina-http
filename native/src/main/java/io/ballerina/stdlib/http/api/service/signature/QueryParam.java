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
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

/**
 * {@code {@link QueryParam }} represents a query parameter details.
 *
 * @since slp8
 */
public class QueryParam {

    private final int typeTag;
    private final String token;
    private final boolean nilable;
    private final int index;
    private final Type type;

    QueryParam(Type type, String token, int index, boolean nilable) {
        this.type = type;
        this.typeTag = type.getTag();
        this.token = token;
        this.index = index;
        this.nilable = nilable;
        validateQueryParamType();
    }

    private void validateQueryParamType() {
        if (isValidBasicType(typeTag) || (typeTag == TypeTags.ARRAY_TAG && isValidBasicType(
                ((ArrayType) type).getElementType().getTag()))) {
            return;
        }
        throw HttpUtil.createHttpError("incompatible query parameter type: '" + type.getName() + "'",
                                       HttpErrorType.GENERIC_LISTENER_ERROR);
    }

    private boolean isValidBasicType(int typeTag) {
        return typeTag == TypeTags.STRING_TAG || typeTag == TypeTags.INT_TAG || typeTag == TypeTags.FLOAT_TAG ||
                typeTag == TypeTags.BOOLEAN_TAG || typeTag == TypeTags.DECIMAL_TAG || typeTag == TypeTags.JSON_TAG;
    }

    public String getToken() {
        return this.token;
    }

    public int getTypeTag() {
        return this.typeTag;
    }

    public boolean isNilable() {
        return this.nilable;
    }

    public int getIndex() {
        return this.index * 2;
    }

    public Type getType() {
        return this.type;
    }
}
