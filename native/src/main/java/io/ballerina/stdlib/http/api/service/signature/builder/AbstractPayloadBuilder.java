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
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.Locale;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.runtime.api.TypeTags.XML_TAG;

/**
 * The abstract class to build and convert the payload based on the content-type header. If the content type is not
 * standard, the parameter type is used to infer the builder.
 *
 * @since SwanLake update 1
 */
public abstract class AbstractPayloadBuilder {

    private static final String JSON_PATTERN = "^.*json.*$";
    private static final String XML_PATTERN = "^.*xml.*$";
    private static final String TEXT_PATTERN = "^.*text.*$";
    private static final String OCTET_STREAM_PATTERN = "^.*octet-stream.*$";
    private static final String URL_ENCODED_PATTERN = "^.*x-www-form-urlencoded.*$";

    /**
     * Build the inbound payload, bind it to the respective type and return the next signature param index.
     *
     * @param inRequestEntity inbound request entity
     * @param readonly        readonly status of parameter
     * @param paramFeed       array of signature parameters
     * @param index           current signature parameter index
     * @return the next index of the signature parameter
     */
    public abstract int build(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index);

    public static AbstractPayloadBuilder getBuilder(HttpCarbonMessage inboundMessage, Type payloadType) {
        String contentType = HttpUtil.getContentTypeFromTransportMessage(inboundMessage);
        if (contentType == null || contentType.isEmpty()) {
            return getBuilderFromType(payloadType);
        }
        contentType = contentType.toLowerCase(Locale.getDefault());
        if (contentType.matches(XML_PATTERN)) {
            return new XmlPayloadBuilder(payloadType);
        } else if (contentType.matches(TEXT_PATTERN)) {
            return new StringPayloadBuilder(payloadType);
        } else if (contentType.matches(URL_ENCODED_PATTERN)) {
            return new StringPayloadBuilder(payloadType);
        } else if (contentType.matches(OCTET_STREAM_PATTERN)) {
            return new ArrayBuilder(payloadType);
        } else if (contentType.matches(JSON_PATTERN)) {
            return new JsonPayloadBuilder(payloadType);
        } else {
            return getBuilderFromType(payloadType);
        }
    }

    private static AbstractPayloadBuilder getBuilderFromType(Type payloadType) {
        switch (payloadType.getTag()) {
            case STRING_TAG:
                return new StringPayloadBuilder(payloadType);
            case XML_TAG:
                return new XmlPayloadBuilder(payloadType);
            case ARRAY_TAG:
                return new ArrayBuilder(payloadType);
            default:
                return new JsonPayloadBuilder(payloadType);
        }
    }
}
