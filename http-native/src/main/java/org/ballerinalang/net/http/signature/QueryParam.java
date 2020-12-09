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

package org.ballerinalang.net.http.signature;

import io.ballerina.runtime.api.types.Type;


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
    }

    public String getToken() {
        return token;
    }

    public int getTypeTag() {
        return typeTag;
    }

    public boolean isNilable() {
        return nilable;
    }

    public int getIndex() {
        return index * 2;
    }

    public Type getType() {
        return type;
    }
}
