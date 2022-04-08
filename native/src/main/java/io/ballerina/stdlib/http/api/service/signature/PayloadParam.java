/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.service.signature.converter.AbstractPayloadConverter;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import org.ballerinalang.langlib.value.CloneWithType;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.stdlib.http.api.service.signature.converter.AbstractPayloadConverter.getConverter;
import static io.ballerina.stdlib.mime.util.MimeConstants.REQUEST_ENTITY_FIELD;

/**
 * {@code {@link PayloadParam }} represents a payload parameter details.
 *
 * @since slp8
 */
public class PayloadParam implements Parameter {

    private int index;
    private Type type;
    private final String token;
    private boolean readonly;
    private final List<String> mediaTypes = new ArrayList<>();

    PayloadParam(String token) {
        this.token = token;
    }

    public void init(Type type, int index) {
        this.type = type;
        this.index = index;
        validatePayloadParam(type);
    }

    @Override
    public String getTypeName() {
        return HttpConstants.PAYLOAD_PARAM;
    }

    public int getIndex() {
        return this.index * 2;
    }

    public Type getType() {
        return this.type;
    }

    public String getToken() {
        return this.token;
    }

    List<String> getMediaTypes() {
        return mediaTypes;
    }

    private void validatePayloadParam(Type parameterType) {
        if (parameterType instanceof IntersectionType) {
            // Assumes that the only intersection type is readonly
            List<Type> memberTypes = ((IntersectionType) parameterType).getConstituentTypes();
            int size = memberTypes.size();
            if (size > 2) {
                throw HttpUtil.createHttpError(
                        "invalid payload param type '" + parameterType.getName() +
                                "': only readonly intersection is allowed");
            }
            this.readonly = true;
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.READONLY_TAG) {
                    continue;
                }
                this.type = type;
                break;
            }
        } else {
            this.type = parameterType;
        }
    }

    public void populateFeed(BObject inRequest, HttpCarbonMessage httpCarbonMessage, Object[] paramFeed) {
        BObject inRequestEntity = (BObject) inRequest.get(REQUEST_ENTITY_FIELD);
        HttpUtil.populateEntityBody(inRequest, inRequestEntity, true, true);
        int index = this.getIndex();
        Type payloadType = this.getType();
        Object dataSource = EntityBodyHandler.getMessageDataSource(inRequestEntity);
        // Check if datasource is already available from interceptor service read
        // TODO : Validate the dataSource type with payload type and populate
        if (dataSource != null) {
            index = populateFeedWithAlreadyBuiltPayload(httpCarbonMessage, paramFeed, inRequestEntity, index,
                                                        payloadType, dataSource);
        } else {
            index = populateFeedWithFreshPayload(httpCarbonMessage, paramFeed, inRequestEntity, index, payloadType);
        }
        paramFeed[index] = true;
    }

    private int populateFeedWithAlreadyBuiltPayload(HttpCarbonMessage httpCarbonMessage, Object[] paramFeed,
                                                    BObject inRequestEntity, int index,
                                                    Type payloadType, Object dataSource) {
        try {
            switch (payloadType.getTag()) {
                case ARRAY_TAG:
                    if (((ArrayType) payloadType).getElementType().getTag() == TypeTags.BYTE_TAG) {
                        paramFeed[index++] = dataSource;
                    } else if (((ArrayType) payloadType).getElementType().getTag() == TypeTags.RECORD_TYPE_TAG) {
                        paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                    } else {
                        throw new BallerinaConnectorException("Incompatible Element type found inside an array " +
                                                                      ((ArrayType) payloadType).getElementType()
                                                                              .getName());
                    }
                    break;
                case TypeTags.RECORD_TYPE_TAG:
                    paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                    break;
                default:
                    paramFeed[index++] = dataSource;
            }
        } catch (BError ex) {
            httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
            throw new BallerinaConnectorException("data binding failed: " + ex.toString());
        }
        return index;
    }

    private int populateFeedWithFreshPayload(HttpCarbonMessage httpCarbonMessage, Object[] paramFeed,
                                             BObject inRequestEntity, int index, Type payloadType) {
        try {
            AbstractPayloadConverter converter = getConverter(httpCarbonMessage, payloadType);
            index = converter.getValue(inRequestEntity, this.readonly, paramFeed, index);
            httpCarbonMessage.setProperty(HttpConstants.ENTITY_OBJ, inRequestEntity);
            return index;
        } catch (BError ex) {
            httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
            throw new BallerinaConnectorException("data binding failed: " + ex.toString());
        }
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
