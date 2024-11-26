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

import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.stdlib.http.api.service.signature.converter.JsonToRecordConverter;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

/**
 * The json type payload builder.
 *
 * @since SwanLake update 1
 */
public class JsonPayloadBuilder extends AbstractPayloadBuilder {
    private final Type payloadType;
    private final boolean laxDataBinding;

    public JsonPayloadBuilder(Type payloadType, boolean laxDataBinding) {
        this.payloadType = payloadType;
        this.laxDataBinding = laxDataBinding;
    }

    @Override
    public Object getValue(BObject entity, boolean readonly) {
        // Following can be removed based on the solution of
        // https://github.com/ballerina-platform/ballerina-lang/issues/35780
        if (isSubtypeOfAllowedType(payloadType, TypeTags.RECORD_TYPE_TAG)) {
            return JsonToRecordConverter.convert(payloadType, entity, readonly, laxDataBinding);
        }
        Object bJson = EntityBodyHandler.constructJsonDataSource(entity);
        EntityBodyHandler.addJsonMessageDataSource(entity, bJson);
        Object result = ValueUtils.convert(bJson, payloadType);
        if (readonly && result instanceof BRefValue) {
            ((BRefValue) result).freezeDirect();
        }
        return result;
    }
}
