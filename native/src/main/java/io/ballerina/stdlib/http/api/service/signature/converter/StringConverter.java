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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.nio.charset.StandardCharsets;

/**
 * The string type payload converter.
 *
 * @since SwanLake update 1
 */
public class StringConverter extends AbstractPayloadConverter {
    Type payloadType;

    public StringConverter(Type payloadType) {
        this.payloadType = payloadType;
    }

    @Override
    public int getValue(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index) {
        BString stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
        EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
        if (payloadType.getTag() == TypeTags.STRING_TAG) {
            paramFeed[index++] = stringDataSource;
        } else if (payloadType.getTag() == TypeTags.ARRAY_TAG) {
            Type elementType = ((ArrayType) payloadType).getElementType();
            if (elementType.getTag() == TypeTags.BYTE_TAG) {
                paramFeed[index++] =
                        ValueCreator.createArrayValue(stringDataSource.getValue().getBytes(StandardCharsets.UTF_8));
            } else {
                throw HttpUtil.createHttpError(
                        "Incompatible Element type found inside an array " + elementType.getName(),
                        HttpErrorType.GENERIC_LISTENER_ERROR);
            }
        } else {
            throw HttpUtil.createHttpError("incompatible type found: '" + payloadType.getName() + "'",
                                           HttpErrorType.GENERIC_LISTENER_ERROR);
        }
        return index;
    }
}
