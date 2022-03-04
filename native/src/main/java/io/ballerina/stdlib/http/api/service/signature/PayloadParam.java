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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXml;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import org.ballerinalang.langlib.value.CloneWithType;

import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
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
    private static final MapType STRING_MAP = TypeCreator.createMapType(PredefinedTypes.TYPE_STRING);

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
            switch (payloadType.getTag()) {
                case STRING_TAG:
                    BString stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
                    EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
                    paramFeed[index++] = stringDataSource;
                    break;
                case MAP_TAG:
                    Type constrainedType = ((MapType) payloadType).getConstrainedType();
                    if (constrainedType.getTag() != STRING_TAG) {
                        throw ErrorCreator.createError(StringUtils.fromString(
                                "invalid map constrained type. Expected: 'map<string>'"));
                    }
                    stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
                    EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
                    BMap<BString, Object> formParamMap = getFormParamMap(stringDataSource);
                    if (this.readonly) {
                        formParamMap.freezeDirect();
                    }
                    paramFeed[index++] = formParamMap;
                    break;
                case TypeTags.JSON_TAG:
                    Object bjson = EntityBodyHandler.constructJsonDataSource(inRequestEntity);
                    EntityBodyHandler.addJsonMessageDataSource(inRequestEntity, bjson);
                    if (this.readonly && bjson instanceof BRefValue) {
                        ((BRefValue) bjson).freezeDirect();
                    }
                    paramFeed[index++] = bjson;
                    break;
                case TypeTags.XML_TAG:
                    BXml bxml = EntityBodyHandler.constructXmlDataSource(inRequestEntity);
                    EntityBodyHandler.addMessageDataSource(inRequestEntity, bxml);
                    if (this.readonly) {
                        bxml.freezeDirect();
                    }
                    paramFeed[index++] = bxml;
                    break;
                case ARRAY_TAG:
                    Type elementType = ((ArrayType) payloadType).getElementType();
                    if (elementType.getTag() == TypeTags.BYTE_TAG) {
                        BArray blobDataSource = EntityBodyHandler.constructBlobDataSource(inRequestEntity);
                        EntityBodyHandler.addMessageDataSource(inRequestEntity, blobDataSource);
                        if (this.readonly) {
                            blobDataSource.freezeDirect();
                        }
                        paramFeed[index++] = blobDataSource;
                    } else if (elementType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                        Object recordEntity = getRecordEntity(inRequestEntity, payloadType);
                        if (this.readonly && recordEntity instanceof BRefValue) {
                            ((BRefValue) recordEntity).freezeDirect();
                        }
                        paramFeed[index++] = recordEntity;
                    } else {
                        throw new BallerinaConnectorException("Incompatible Element type found inside an array " +
                                                                      elementType.getName());
                    }
                    break;
                case TypeTags.RECORD_TYPE_TAG:
                    Object recordEntity = getRecordEntity(inRequestEntity, payloadType);
                    if (this.readonly && recordEntity instanceof BRefValue) {
                        ((BRefValue) recordEntity).freezeDirect();
                    }
                    paramFeed[index++] = recordEntity;
                    break;
//            case TypeTags.INTERSECTION_TAG:
//                // Assumes that only intersected with readonly
//                Type pureType = ((IntersectionType) payloadType).getEffectiveType();
//                index = populateParamFeed(paramFeed, inRequestEntity, index, pureType);
//                paramFeed[index - 1] = getCloneReadOnlyValue(paramFeed[index - 1]);
//                break;
                default:
                    //Do nothing
            }
//            return index;
//            index = populateParamFeed(paramFeed, inRequestEntity, index, payloadType);
            // Set the entity obj in case it is read by an interceptor
            httpCarbonMessage.setProperty(HttpConstants.ENTITY_OBJ, inRequestEntity);
            return index;
        } catch (BError | IOException ex) {
            httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
            throw new BallerinaConnectorException("data binding failed: " + ex.toString());
        }
    }

    private static BMap<BString, Object> getFormParamMap(Object stringDataSource) {
        try {
            String formData = ((BString) stringDataSource).getValue();
            BMap<BString, Object> formParamsMap = ValueCreator.createMapValue(STRING_MAP);
            if (formData.isEmpty()) {
                return formParamsMap;
            }
            Map<String, String> tempParamMap = new HashMap<>();
            String decodedValue = URLDecoder.decode(formData, StandardCharsets.UTF_8);

            if (!decodedValue.contains("=")) {
                throw new BallerinaConnectorException("Datasource does not contain form data");
            }
            String[] formParamValues = decodedValue.split("&");
            for (String formParam : formParamValues) {
                int index = formParam.indexOf('=');
                if (index == -1) {
                    if (!tempParamMap.containsKey(formParam)) {
                        tempParamMap.put(formParam, null);
                    }
                    continue;
                }
                String formParamName = formParam.substring(0, index).trim();
                String formParamValue = formParam.substring(index + 1).trim();
                tempParamMap.put(formParamName, formParamValue);
            }

            for (Map.Entry<String, String> entry : tempParamMap.entrySet()) {
                String entryValue = entry.getValue();
                if (entryValue != null) {
                    formParamsMap.put(StringUtils.fromString(entry.getKey()), StringUtils.fromString(entryValue));
                } else {
                    formParamsMap.put(StringUtils.fromString(entry.getKey()), null);
                }
            }
            return formParamsMap;
        } catch (Exception ex) {
            throw ErrorCreator.createError(
                    StringUtils.fromString("Could not convert payload to map<string>: " + ex.getMessage()));
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
