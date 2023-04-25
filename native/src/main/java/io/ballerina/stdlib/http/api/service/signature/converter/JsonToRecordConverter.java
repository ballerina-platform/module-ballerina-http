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

import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

/**
 * The converter binds the JSON payload to a record.
 *
 * @since SwanLake update 1
 */
public class JsonToRecordConverter {

    public static Object convert(Type type, BObject entity, boolean readonly) {
        Object recordEntity = getRecordEntity(entity, type);
        if (readonly && recordEntity instanceof BRefValue) {
            ((BRefValue) recordEntity).freezeDirect();
        }
        return recordEntity;
    }

    private static Object getRecordEntity(BObject entity, Type entityBodyType) {
        Object bjson = EntityBodyHandler.getMessageDataSource(entity) == null ? getBJsonValue(entity)
                : EntityBodyHandler.getMessageDataSource(entity);
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
     * @param bJson          Represents the json value that needs to be converted
     * @return the relevant ballerina record or object
     */
    private static Object getRecord(Type entityBodyType, Object bJson) {
        try {
            return ValueUtils.convert(bJson, entityBodyType);
        } catch (NullPointerException ex) {
            throw new BallerinaConnectorException("cannot convert payload to record type: " +
                                                          entityBodyType.getName());
        }
    }

    /**
     * Given an inbound request entity construct the ballerina json.
     *
     * @param entity Represents inbound request entity
     * @return a ballerina json value
     */
    private static Object getBJsonValue(BObject entity) {
        Object bjson = EntityBodyHandler.constructJsonDataSource(entity);
        EntityBodyHandler.addJsonMessageDataSource(entity, bjson);
        return bjson;
    }

    private JsonToRecordConverter() {

    }
}
