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
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.service.signature.builder.AbstractPayloadBuilder;
import io.ballerina.stdlib.http.api.service.signature.converter.JsonToRecordConverter;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import io.ballerina.stdlib.mime.util.MimeConstants;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_PAYLOAD_VALIDATION_LISTENER_ERROR;
import static io.ballerina.stdlib.http.api.service.signature.builder.AbstractPayloadBuilder.getBuilder;
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
    private boolean nilable;
    private final List<String> mediaTypes = new ArrayList<>();
    private Type customParameterType;
    private final boolean requireConstraintValidation;

    PayloadParam(String token, boolean constraintValidation) {
        this.token = token;
        this.requireConstraintValidation = constraintValidation;
    }

    public void init(Type type, Type customParameterType, int index) {
        this.type = type;
        this.customParameterType = customParameterType;
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
                throw HttpUtil.createHttpError("invalid payload param type '" + parameterType.getName() +
                                "': only readonly intersection is allowed");
            }
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.READONLY_TAG) {
                    this.readonly = true;
                    continue;
                }
                parameterType = type;
            }
        }

        if (parameterType instanceof UnionType) {
            List<Type> memberTypes = ((UnionType) parameterType).getMemberTypes();
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.INTERSECTION_TAG) {
                    this.readonly = true;
                    continue;
                }
                if (type.getTag() == TypeTags.NULL_TAG) {
                    this.nilable = true;
                }
            }
        }
        this.type = parameterType;
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
            populateFeedWithAlreadyBuiltPayload(paramFeed, inRequestEntity, index, payloadType, dataSource);
        } else {
            populateFeedWithFreshPayload(httpCarbonMessage, paramFeed, inRequestEntity, index, payloadType);
        }
    }

    private void populateFeedWithAlreadyBuiltPayload(Object[] paramFeed, BObject inRequestEntity, int index,
                                                    Type payloadType, Object dataSource) {
        try {
            switch (payloadType.getTag()) {
                case ARRAY_TAG:
                    int actualTypeTag = TypeUtils.getReferredType(((ArrayType) payloadType).getElementType()).getTag();
                    if (actualTypeTag == TypeTags.BYTE_TAG) {
                        paramFeed[index] = validateConstraints(dataSource);
                    } else if (actualTypeTag == TypeTags.RECORD_TYPE_TAG) {
                        dataSource = JsonToRecordConverter.convert(payloadType, inRequestEntity, readonly);
                        paramFeed[index]  = validateConstraints(dataSource);
                    } else {
                        throw HttpUtil.createHttpError("incompatible element type found inside an array " +
                                                       ((ArrayType) payloadType).getElementType().getName());
                    }
                    break;
                case TypeTags.RECORD_TYPE_TAG:
                    dataSource = JsonToRecordConverter.convert(payloadType, inRequestEntity, readonly);
                    paramFeed[index]  = validateConstraints(dataSource);
                    break;
                default:
                    paramFeed[index] = validateConstraints(dataSource);
            }
        } catch (BError ex) {
            String message = "data binding failed: " + HttpUtil.getPrintableErrorMsg(ex);
            throw HttpUtil.createHttpStatusCodeError(INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
        }
    }

    private void populateFeedWithFreshPayload(HttpCarbonMessage inboundMessage, Object[] paramFeed,
                                             BObject inRequestEntity, int index, Type payloadType) {
        try {
            String contentType = HttpUtil.getContentTypeFromTransportMessage(inboundMessage);
            AbstractPayloadBuilder payloadBuilder = getBuilder(contentType, payloadType);
            Object payloadBuilderValue = payloadBuilder.getValue(inRequestEntity, this.readonly);
            paramFeed[index] = validateConstraints(payloadBuilderValue);
            inboundMessage.setProperty(HttpConstants.ENTITY_OBJ, inRequestEntity);
        } catch (BError ex) {
            String typeName = ex.getType().getName();
            if (MimeConstants.NO_CONTENT_ERROR.equals(typeName) && this.nilable) {
                paramFeed[index] = null;
            }
            if (INTERNAL_PAYLOAD_VALIDATION_LISTENER_ERROR.getErrorName().equals(typeName)) {
                throw ex;
            }
            String message = "data binding failed: " + HttpUtil.getPrintableErrorMsg(ex);
            throw HttpUtil.createHttpStatusCodeError(INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
        }
    }

    private Object validateConstraints(Object payloadBuilderValue) {
        if (requireConstraintValidation) {
            Object result = Constraints.validate(payloadBuilderValue,
                                                 ValueCreator.createTypedescValue(this.customParameterType));
            if (result instanceof BError) {
                String message = "payload validation failed: " + HttpUtil.getPrintableErrorMsg((BError) result);
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_PAYLOAD_VALIDATION_LISTENER_ERROR, message);
            }
        }
        return payloadBuilderValue;
    }
}
