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

import io.ballerina.runtime.api.types.Type;

/**
 * {@code {@link HeaderParam }} represents a inbound request header parameter details.
 *
 * @since sl-alpha3
 */
public class HeaderParam {

    private int typeTag;
    private final String token;
    private boolean nilable;
    private int index;
    private String headerName;

    HeaderParam(String token) {
        this.token = token;
    }

    public void init(Type type, int index) {
        this.typeTag = type.getTag();
        this.index = index;
        this.nilable = type.isNilable();
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

    public String getHeaderName() {
        return headerName;
    }

    void setHeaderName(String headerName) {
        this.headerName = headerName;
    }
}
