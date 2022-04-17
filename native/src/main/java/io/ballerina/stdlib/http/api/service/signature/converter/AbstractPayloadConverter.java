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
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.Locale;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.runtime.api.TypeTags.XML_TAG;

/**
 * The abstract class to convert the payload based on the content-type header. If the content type is not standard,
 * the parameter type is used to infer the converter.
 *
 * @since SwanLake update 1
 */
public abstract class AbstractPayloadConverter {

    public static AbstractPayloadConverter getConverter(HttpCarbonMessage httpCarbonMessage,
                                                        Type payloadType) {
        String contentType = HttpUtil.getContentTypeFromTransportMessage(httpCarbonMessage);
        if (contentType == null || contentType.isEmpty()) {
            return getConverterFromType(payloadType);
        }
        contentType = contentType.toLowerCase(Locale.getDefault());
        if (contentType.contains("xml")) {
            return new XmlConverter(payloadType);
        } else if (contentType.contains("text")) {
            return new StringConverter(payloadType);
        } else if (contentType.contains("x-www-form-urlencoded")) {
            if (payloadType.getTag() == MAP_TAG) {
                return new MapConverter(payloadType, true);
            }
            return new StringConverter(payloadType);
        } else if (contentType.contains("octet-stream")) {
            return new ArrayConverter(payloadType);
        }  else if (contentType.contains("json")) {
            return new JsonConverter(payloadType);
        } else {
            return getConverterFromType(payloadType);
        }
    }

    private static AbstractPayloadConverter getConverterFromType(Type payloadType) {
        switch (payloadType.getTag()) {
            case STRING_TAG:
                return new StringConverter(payloadType);
            case XML_TAG:
                return new XmlConverter(payloadType);
            case ARRAY_TAG:
                return new ArrayConverter(payloadType);
            case MAP_TAG:
                return new MapConverter(payloadType);
            default:
                return new JsonConverter(payloadType);
        }
    }

    public abstract int getValue(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index);
}
