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

package io.ballerina.stdlib.http.api.service.signature.builder;

import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.service.signature.converter.StringToByteArrayConverter;
import io.ballerina.stdlib.http.api.service.signature.converter.UrlEncodedStringToMapConverter;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.util.List;

/**
 * The string type payload builder.
 *
 * @since SwanLake update 1
 */
public class StringPayloadBuilder extends AbstractPayloadBuilder {
    private final Type payloadType;

    public StringPayloadBuilder(Type payloadType) {
        this.payloadType = payloadType;
    }

    @Override
    public Object getValue(BObject entity, boolean readonly) {
        BString dataSource = EntityBodyHandler.constructStringDataSource(entity);
        EntityBodyHandler.addMessageDataSource(entity, dataSource);
        return createValue(payloadType, readonly, dataSource);
    }

    private Object createValue(Type payloadType, boolean readonly, BString dataSource) {
        if (payloadType.getTag() == TypeTags.STRING_TAG || payloadType.getTag() == TypeTags.CHAR_STRING_TAG ||
                payloadType.getTag() == TypeTags.FINITE_TYPE_TAG) {
            return dataSource;
        } else if (payloadType.getTag() == TypeTags.ARRAY_TAG) {
            return StringToByteArrayConverter.convert((ArrayType) payloadType, dataSource, readonly);
        } else if (payloadType.getTag() == TypeTags.MAP_TAG) {
            return UrlEncodedStringToMapConverter.convert((MapType) payloadType, dataSource, readonly);
        } else if (payloadType.getTag() == TypeTags.UNION_TAG) {
            List<Type> memberTypes = ((UnionType) payloadType).getMemberTypes();
            for (Type memberType : memberTypes) {
                try {
                    return createValue(memberType, readonly, dataSource);
                } catch (BError ignored) {
                    // thrown errors are ignored until all the types are iterated
                }
            }
        }
        String message = "incompatible type found: '" + payloadType.toString() + "'";
        throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
    }
}
