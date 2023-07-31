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

import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;

import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_PARAM;

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

    public RecordType getOriginalType() {
        return (RecordType) this.type;
    }

    public List<String> getKeys() {
        return this.keys;
    }

    public HeaderRecordParam.FieldParam getField(int index) {
        return this.fields[index];
    }

    static class FieldParam {
        private final boolean nilable;
        private final int effectiveTypeTag;
        private final boolean isArray;

        public FieldParam(Type fieldType) {
            this.nilable = fieldType.isNilable();
            this.effectiveTypeTag = ParamUtils.getEffectiveTypeTag(fieldType, fieldType, HEADER_PARAM);
            this.isArray = ParamUtils.isArrayType(fieldType);
        }

        public boolean isNilable() {
            return nilable;
        }

        public int getEffectiveTypeTag() {
            return effectiveTypeTag;
        }

        public boolean isArray() {
            return isArray;
        }
    }
}
