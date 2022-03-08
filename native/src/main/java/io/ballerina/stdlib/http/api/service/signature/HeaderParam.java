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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.List;

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
    private Type type;
    private String headerName;
    private boolean readonly;

    HeaderParam(String token) {
        this.token = token;
    }

    public void init(Type type, int index) {
        this.type = type;
        this.typeTag = type.getTag();
        this.index = index;
        validateHeaderParamType(this.type);
    }

    private void validateHeaderParamType(Type paramType) {
        if (paramType instanceof UnionType) {
            List<Type> memberTypes = ((UnionType) paramType).getMemberTypes();
            this.nilable = true;
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.NULL_TAG) {
                    continue;
                }
                validateBasicType(type);
                break;
            }
        } else if (paramType instanceof IntersectionType) {
            // Assumes that the only intersection type is readonly
            List<Type> memberTypes = ((IntersectionType) paramType).getConstituentTypes();
            int size = memberTypes.size();
            if (size > 2) {
                throw HttpUtil.createHttpError(
                        "invalid header param type '" + paramType.getName() +
                                "': only readonly intersection is allowed");
            }
            this.readonly = true;
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.READONLY_TAG) {
                    continue;
                }
                if (type.getTag() == TypeTags.UNION_TAG) {
                    validateHeaderParamType(type);
                    return;
                }
                validateBasicType(type);
                break;
            }
        } else {
            validateBasicType(paramType);
        }
    }

    // Note the validation is only done for the non-object header params. i.e for the string, string[] types
    private void validateBasicType(Type type) {
        if (isValidBasicType(type.getTag()) || (type.getTag() == TypeTags.ARRAY_TAG && isValidBasicType(
                ((ArrayType) type).getElementType().getTag()))) {
            // Assign element type as the type of header param
            this.type = type;
            this.typeTag = type.getTag();
        }
    }

    private boolean isValidBasicType(int typeTag) {
        return typeTag == TypeTags.STRING_TAG;
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
        return this.headerName;
    }

    void setHeaderName(String headerName) {
        this.headerName = headerName;
    }

    public boolean isReadonly() {
        return this.readonly;
    }
}
