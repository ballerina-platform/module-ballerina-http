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

/**
 * {@code {@link QueryParam }} represents a query parameter details.
 *
 * @since slp8
 */
public class QueryParam {

    private final String token;
    private final boolean nilable;
    private final boolean readonly;
    private final boolean defaultable;
    private final int index;
    private final Type type;

    QueryParam(Type type, String token, int index, boolean nilable, boolean readonly, boolean defaultable) {
        this.type = type;
        this.token = token;
        this.index = index;
        this.nilable = nilable;
        this.readonly = readonly;
        this.defaultable = defaultable;
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

    public Type getType() {
        return this.type;
    }

    public boolean isReadonly() {
        return this.readonly;
    }

    public boolean isDefaultable() {
        return defaultable;
    }
}
