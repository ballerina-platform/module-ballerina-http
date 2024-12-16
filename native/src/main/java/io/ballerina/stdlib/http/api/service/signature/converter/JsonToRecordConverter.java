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

import io.ballerina.lib.data.jsondata.json.Native;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.util.HashMap;
import java.util.Map;

import static io.ballerina.stdlib.http.api.HttpConstants.ALLOW_DATA_PROJECTION;
import static io.ballerina.stdlib.http.api.HttpConstants.ENABLE_CONSTRAINT_VALIDATION;
import static io.ballerina.stdlib.http.api.HttpConstants.PARSER_AS_TYPE_OPTIONS;
import static io.ballerina.stdlib.http.api.HttpConstants.NIL_AS_OPTIONAL;
import static io.ballerina.stdlib.http.api.HttpConstants.ABSENT_AS_NILABLE;

/**
 * The converter binds the JSON payload to a record.
 *
 * @since SwanLake update 1
 */
public class JsonToRecordConverter {

    public static Object convert(Type type, BObject entity, boolean readonly, boolean laxDataBinding) {
        Object recordEntity = getRecordEntity(entity, type, laxDataBinding);
        if (readonly && recordEntity instanceof BRefValue) {
            ((BRefValue) recordEntity).freezeDirect();
        }
        return recordEntity;
    }

    private static Object getRecordEntity(BObject entity, Type entityBodyType, boolean laxDataBinding) {
        Object bjson = EntityBodyHandler.getMessageDataSource(entity) == null ? getBJsonValue(entity)
                : EntityBodyHandler.getMessageDataSource(entity);
        Object result = getRecord(entityBodyType, bjson, laxDataBinding);
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
    private static Object getRecord(Type entityBodyType, Object bJson, boolean laxDataBinding) {
        try {
            Map<String, Object> valueMap = new HashMap<>();
            Boolean bool = Boolean.FALSE;
            valueMap.put(ENABLE_CONSTRAINT_VALIDATION, Boolean.FALSE);
            BMap<BString, Object> mapValue = ValueCreator.createRecordValue(
                    io.ballerina.lib.data.ModuleUtils.getModule(),
                    PARSER_AS_TYPE_OPTIONS, valueMap);
            if (laxDataBinding) {
                BMap allowDataProjection = mapValue.getMapValue(ALLOW_DATA_PROJECTION);
                allowDataProjection.put(NIL_AS_OPTIONAL, Boolean.TRUE);
                allowDataProjection.put(ABSENT_AS_NILABLE, Boolean.TRUE);
            } else {
                mapValue.put(ALLOW_DATA_PROJECTION, Boolean.FALSE);
            }
            BTypedesc typedescValue = ValueCreator.createTypedescValue(entityBodyType);
            return Native.parseAsType(bJson, mapValue, typedescValue);
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
