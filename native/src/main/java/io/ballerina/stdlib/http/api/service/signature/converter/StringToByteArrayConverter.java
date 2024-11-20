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

package io.ballerina.stdlib.http.api.service.signature.converter;

import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.nio.charset.StandardCharsets;

import static io.ballerina.runtime.api.creators.ValueCreator.createArrayValue;
import static io.ballerina.runtime.api.creators.ValueCreator.createReadonlyArrayValue;

/**
 * The converter binds the String payload to a Byte array.
 *
 * @since SwanLake update 1
 */
public class StringToByteArrayConverter {

    public static Object convert(ArrayType type, BString dataSource, boolean readonly) {
        Type elementType = type.getElementType();
        if (elementType.getTag() == TypeTags.BYTE_TAG) {
            byte[] values = dataSource.getValue().getBytes(StandardCharsets.UTF_8);
            return readonly ? createReadonlyArrayValue(values) : createArrayValue(values);
        }
        String message = "incompatible array element type found: '" + elementType.toString() + "'";
        throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
    }

    private StringToByteArrayConverter() {

    }
}
