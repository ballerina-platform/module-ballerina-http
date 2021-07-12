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

package org.ballerinalang.net.http.service.signature;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpErrorType;
import org.ballerinalang.net.http.HttpUtil;

import java.util.ArrayList;
import java.util.List;

/**
 * {@code {@link PayloadParam }} represents a payload parameter details.
 *
 * @since slp8
 */
public class PayloadParam implements Parameter {

    private int index;
    private Type type;
    private int typeTag;
    private final String token;
    private List<String> mediaTypes = new ArrayList<>();

    PayloadParam(String token) {
        this.token = token;
    }

    public void init(Type type, int index) {
        this.type = type;
        this.typeTag = type.getTag();
        this.index = index;
        validatePayloadParam();
    }

    @Override
    public String getTypeName() {
        return HttpConstants.PAYLOAD_PARAM;
    }

    public int getIndex() {
        return this.index * 2;
    }

    private void validatePayloadParam() {
        if (typeTag == TypeTags.RECORD_TYPE_TAG || typeTag == TypeTags.JSON_TAG || typeTag == TypeTags.XML_TAG ||
                typeTag == TypeTags.STRING_TAG || (typeTag == TypeTags.ARRAY_TAG && validArrayType())) {
            return;
        }
        throw HttpUtil.createHttpError("incompatible payload parameter type : '" + type.getName() + "'",
                                       HttpErrorType.GENERIC_LISTENER_ERROR);
    }

    private boolean validArrayType() {
        return ((ArrayType) type).getElementType().getTag() == TypeTags.BYTE_TAG ||
                ((ArrayType) type).getElementType().getTag() == TypeTags.RECORD_TYPE_TAG;
    }

    public Type getType() {
        return this.type;
    }

    public String getToken() {
        return this.token;
    }

    List<String> getMediaTypes() {
        return mediaTypes;
    }
}
