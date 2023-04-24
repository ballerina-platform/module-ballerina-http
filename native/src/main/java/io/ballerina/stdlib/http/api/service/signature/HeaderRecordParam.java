/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.List;

/**
 * {@code {@link HeaderRecordParam }} represents a inbound request header record parameter details.
 *
 * @since sl-update1
 */
public class HeaderRecordParam extends HeaderParam {
    private final List<String> keys;
    private final HeaderRecordParam.FieldParam[] fields;
    private final Type type;

    public HeaderRecordParam(String token, Type type, List<String> keys, HeaderRecordParam.FieldParam[] fields) {
        super(token);
        this.type = type;
        this.keys = keys;
        this.fields = fields.clone();
    }

    public RecordType getReferredType() {
        return (RecordType) this.type;
    }

    public List<String> getKeys() {
        return this.keys;
    }

    public HeaderRecordParam.FieldParam getField(int index) {
        return this.fields[index];
    }

    static class FieldParam {
        private final Type type;
        private final boolean readonly;
        private final boolean nilable;

        public FieldParam(Type fieldType) {
            this.type = getEffectiveType(fieldType);
            this.readonly = fieldType.isReadOnly();
            this.nilable = fieldType.isNilable();
        }

        Type getEffectiveType(Type paramType) {
            if (paramType instanceof UnionType) {
                List<Type> memberTypes = ((UnionType) paramType).getMemberTypes();
                for (Type type : memberTypes) {
                    if (type.getTag() == TypeTags.NULL_TAG) {
                        continue;
                    }
                    return type;
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
                for (Type type : memberTypes) {
                    if (type.getTag() == TypeTags.READONLY_TAG) {
                        continue;
                    }
                    if (type.getTag() == TypeTags.UNION_TAG) {
                        return getEffectiveType(type);
                    }
                    return type;
                }
            }
            return paramType;
        }

        public Type getType() {
            return type;
        }

        public boolean isReadonly() {
            return readonly;
        }

        public boolean isNilable() {
            return nilable;
        }
    }
}
