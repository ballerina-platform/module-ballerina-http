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
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BXml;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

/**
 * The xml type payload converter.
 *
 * @since SwanLake update 1
 */
public class XmlConverter extends AbstractPayloadConverter {
    Type payloadType;

    public XmlConverter(Type payloadType) {
        this.payloadType = payloadType;
    }

    @Override
    public int getValue(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index) {
        if (payloadType.getTag() == TypeTags.XML_TAG) {
            BXml bxml = EntityBodyHandler.constructXmlDataSource(inRequestEntity);
            EntityBodyHandler.addMessageDataSource(inRequestEntity, bxml);
            if (readonly) {
                bxml.freezeDirect();
            }
            paramFeed[index++] = bxml;
            return index;
        } else {
            throw HttpUtil.createHttpError("incompatible type found: '" + payloadType.getName() + "'",
                                           HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }
}
