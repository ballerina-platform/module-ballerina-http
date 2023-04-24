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
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * {@code {@link HeaderParam }} represents a inbound request header parameter details.
 *
 * @since sl-alpha3
 */
public class HeaderParam {

    private final String token;
    private boolean nilable;
    private int index;
    private Type referredType;
    private Type originalType;
    private String headerName;
    private boolean readonly;
    private HeaderRecordParam recordParam;

    HeaderParam(String token) {
        this.token = token;
    }

    public void init(Type originalType, Type referredType, int index) {
        this.originalType = originalType;
        this.referredType = referredType;
        this.index = index;
        validateHeaderParamType(this.referredType);
    }

    private void validateHeaderParamType(Type paramType) {

        if (paramType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            paramType = TypeUtils.getReferredType(paramType);
        }

        if (paramType instanceof UnionType) {
            List<Type> memberTypes = ((UnionType) paramType).getMemberTypes();
            this.nilable = true;
            for (Type type : memberTypes) {
                Type referredType =  TypeUtils.getReferredType(type);
                if (referredType.getTag() == TypeTags.NULL_TAG) {
                    continue;
                }
                if (referredType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                    validateHeaderParamType(type);
                    return;
                }
                setReferredType(type);
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
                Type referredType =  TypeUtils.getReferredType(type);

                if (referredType.getTag() == TypeTags.READONLY_TAG) {
                    continue;
                }
                if (referredType.getTag() == TypeTags.UNION_TAG || referredType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                    validateHeaderParamType(type);
                    return;
                }
                setReferredType(type);
                break;
            }
        } else if (paramType instanceof RecordType) {
            this.referredType = paramType;
            Map<String, Field> recordFields = ((RecordType) paramType).getFields();
            List<String> keys = new ArrayList<>();
            HeaderRecordParam.FieldParam[] fields = new HeaderRecordParam.FieldParam[recordFields.size()];
            int i = 0;
            for (Map.Entry<String, Field> field : recordFields.entrySet()) {
                keys.add(field.getKey());
                fields[i++] = new HeaderRecordParam.FieldParam(field.getValue().getFieldType());
            }
            this.recordParam = new HeaderRecordParam(this.token, this.referredType, keys, fields);
        } else {
            setReferredType(paramType);
        }
    }

    public Type getReferredType() {
        return this.referredType;
    }

    public Type getOriginalType() {
        return this.originalType;
    }

    private void setReferredType(Type referredType) {
        this.referredType = referredType;
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

    public String getHeaderName() {
        return this.headerName;
    }

    void setHeaderName(String headerName) {
        this.headerName = headerName;
    }

    public boolean isReadonly() {
        return this.readonly;
    }

    public HeaderRecordParam getRecordParam() {
        return this.recordParam;
    }

    public boolean isRecord() {
        return getRecordParam() != null;
    }
}
