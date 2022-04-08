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
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import org.ballerinalang.langlib.value.CloneWithType;

import java.io.IOException;

/**
 * The array type payload converter.
 *
 * @since SwanLake update 1
 */
public class ArrayConverter extends AbstractPayloadConverter {
    Type payloadType;

    public ArrayConverter(Type payloadType) {
        this.payloadType = payloadType;
    }

    @Override
    public int getValue(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index) {
        Type elementType = ((ArrayType) payloadType).getElementType();
        if (elementType.getTag() == TypeTags.BYTE_TAG) {
            BArray blobDataSource;
            try {
                blobDataSource = EntityBodyHandler.constructBlobDataSource(inRequestEntity);
            } catch (IOException e) {
                throw HttpUtil.createHttpError(e.getMessage(), HttpErrorType.CLIENT_ERROR);
            }
            EntityBodyHandler.addMessageDataSource(inRequestEntity, blobDataSource);
            if (readonly) {
                blobDataSource.freezeDirect();
            }
            paramFeed[index++] = blobDataSource;
        } else if (elementType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            Object recordEntity = getRecordEntity(inRequestEntity, payloadType);
            if (readonly && recordEntity instanceof BRefValue) {
                ((BRefValue) recordEntity).freezeDirect();
            }
            paramFeed[index++] = recordEntity;
        } else {
            throw new BallerinaConnectorException("Incompatible Element type found inside an array " +
                                                          elementType.getName());
        }
        return index;
    }

    private static Object getRecordEntity(BObject inRequestEntity, Type entityBodyType) {
        Object bjson = EntityBodyHandler.getMessageDataSource(inRequestEntity) == null ? getBJsonValue(inRequestEntity)
                : EntityBodyHandler.getMessageDataSource(inRequestEntity);
        Object result = getRecord(entityBodyType, bjson);
        if (result instanceof BError) {
            throw (BError) result;
        }
        return result;
    }

    /**
     * Convert a json to the relevant record type.
     *
     * @param entityBodyType Represents entity body type
     * @param bjson          Represents the json value that needs to be converted
     * @return the relevant ballerina record or object
     */
    private static Object getRecord(Type entityBodyType, Object bjson) {
        try {
            return CloneWithType.convert(entityBodyType, bjson);
        } catch (NullPointerException ex) {
            throw new BallerinaConnectorException("cannot convert payload to record type: " +
                                                          entityBodyType.getName());
        }
    }

    /**
     * Given an inbound request entity construct the ballerina json.
     *
     * @param inRequestEntity Represents inbound request entity
     * @return a ballerina json value
     */
    private static Object getBJsonValue(BObject inRequestEntity) {
        Object bjson = EntityBodyHandler.constructJsonDataSource(inRequestEntity);
        EntityBodyHandler.addJsonMessageDataSource(inRequestEntity, bjson);
        return bjson;
    }
}
