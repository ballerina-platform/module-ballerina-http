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
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BXml;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.util.Arrays;
import java.util.List;

/**
 * The xml type payload builder.
 *
 * @since SwanLake update 1
 */
public class XmlPayloadBuilder extends AbstractPayloadBuilder {
    private final Type payloadType;
    private static final List<Integer> allowedList = Arrays.asList(
            TypeTags.XML_TAG, TypeTags.XML_ELEMENT_TAG, TypeTags.XML_COMMENT_TAG, TypeTags.XML_PI_TAG,
            TypeTags.XML_TEXT_TAG);

    public XmlPayloadBuilder(Type payloadType) {
        this.payloadType = payloadType;
    }

    @Override
    public Object getValue(BObject entity, boolean readonly) {
        if (allowedList.stream().anyMatch(allowedTag -> isSubtypeOfAllowedType(payloadType, allowedTag))) {
            BXml bxml = EntityBodyHandler.constructXmlDataSource(entity);
            EntityBodyHandler.addMessageDataSource(entity, bxml);
            if (readonly) {
                bxml.freezeDirect();
            }
            return bxml;
        }
        String message = "incompatible type found: '" + payloadType.toString() + "'";
        throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
    }
}
