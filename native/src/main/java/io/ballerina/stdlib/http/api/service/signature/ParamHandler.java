/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.uri.URIUtil;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_FIELD_RESPOND_TYPE;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_CACHE;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_CALLER_INFO;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_PAYLOAD;
import static io.ballerina.stdlib.http.api.HttpConstants.COLON;
import static io.ballerina.stdlib.http.api.HttpConstants.PROTOCOL_HTTP;
import static io.ballerina.stdlib.http.api.HttpUtil.getParameterTypes;

/**
 * This class holds the resource signature parameters.
 *
 * @since 0.963.0
 */
public class ParamHandler {

    private final Type[] paramTypes;
    private final int pathParamCount;
    private Type callerInfoType = null;
    private ResourceMethodType resource;
    private String[] pathParamTokens = new String[0];
    private List<Parameter> otherParamList = new ArrayList<>();
    private PayloadParam payloadParam = null;
    private NonRecurringParam callerParam = null;
    private NonRecurringParam requestParam = null;
    private NonRecurringParam headerObjectParam = null;
    private NonRecurringParam requestContextParam = null;
    private NonRecurringParam interceptorErrorParam = null;
    private AllQueryParams queryParams = new AllQueryParams();
    private AllHeaderParams headerParams = new AllHeaderParams();

    private static final String PARAM_ANNOT_PREFIX = "$param$.";
    private static final MapType MAP_TYPE = TypeCreator.createMapType(
            TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
    private static final String CALLER_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.CALLER;
    private static final String REQ_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.REQUEST;
    private static final String HEADERS_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.HEADERS;
    private static final String REQUEST_CONTEXT_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.REQUEST_CONTEXT;
    private static final String CALLER_ANNOTATION =
            ModuleUtils.getHttpPackageIdentifier() + COLON + ANN_NAME_CALLER_INFO;
    public static final String PAYLOAD_ANNOTATION = ModuleUtils.getHttpPackageIdentifier() + COLON + ANN_NAME_PAYLOAD;
    public static final String HEADER_ANNOTATION = ModuleUtils.getHttpPackageIdentifier() + COLON + ANN_NAME_HEADER;
    public static final String CALLER_INFO_ANNOTATION = ModuleUtils.getHttpPackageIdentifier() + COLON
            + ANN_NAME_CALLER_INFO;
    public static final String CACHE_ANNOTATION = ModuleUtils.getHttpPackageIdentifier() + COLON
            + ANN_NAME_CACHE;

    public ParamHandler(ResourceMethodType resource, int pathParamCount, boolean constraintValidation) {
        this.resource = resource;
        this.pathParamCount = pathParamCount;
        this.paramTypes = getParameterTypes(resource);
        populatePathParamTokens(resource, pathParamCount);
        populatePayloadAndHeaderParamTokens(resource, constraintValidation);
        validateSignatureParams();
    }

    private void populatePathParamTokens(ResourceMethodType resource, int pathParamCount) {
        if (pathParamCount == 0) {
            return;
        }
        this.pathParamTokens = Arrays.copyOfRange(resource.getParamNames(), 0, pathParamCount);
        validatePathParam(resource, pathParamCount);
    }

    private void validateSignatureParams() {
        if (paramTypes.length == pathParamCount) {
            return;
        }
        Type[] customParameterTypes = HttpUtil.getCustomParameterTypes(resource);
        for (int index = pathParamCount; index < paramTypes.length; index++) {
            Type parameterType = this.paramTypes[index];

            String typeName = parameterType.toString();
            switch (typeName) {
                case REQUEST_CONTEXT_TYPE:
                    if (this.requestContextParam == null) {
                        this.requestContextParam = new NonRecurringParam(index, HttpConstants.REQUEST_CONTEXT);
                        getOtherParamList().add(this.requestContextParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + REQUEST_CONTEXT_TYPE
                                                               + "' parameter");
                    }
                    break;
                case HttpConstants.STRUCT_GENERIC_ERROR:
                    if (this.interceptorErrorParam == null) {
                        this.interceptorErrorParam = new NonRecurringParam(index,
                                                                           HttpConstants.STRUCT_GENERIC_ERROR);
                        getOtherParamList().add(this.interceptorErrorParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" +
                                                               HttpConstants.STRUCT_GENERIC_ERROR + "' parameter");
                    }
                    break;
                case CALLER_TYPE:
                    if (this.callerParam == null) {
                        this.callerParam = new NonRecurringParam(index, HttpConstants.CALLER);
                        getOtherParamList().add(this.callerParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + CALLER_TYPE + "' parameter");
                    }
                    break;
                case REQ_TYPE:
                    if (this.requestParam == null) {
                        this.requestParam = new NonRecurringParam(index, HttpConstants.REQUEST);
                        getOtherParamList().add(this.requestParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + REQ_TYPE + "' parameter");
                    }
                    break;
                case HEADERS_TYPE:
                    if (this.headerObjectParam == null) {
                        this.headerObjectParam = new NonRecurringParam(index, HttpConstants.HEADERS);
                        getOtherParamList().add(this.headerObjectParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + HEADERS_TYPE + "' parameter");
                    }
                    break;
                default:
                    String paramName = resource.getParamNames()[index];
                    HeaderParam headerParam;
                    if (payloadParam != null && paramName.equals(payloadParam.getToken())) {
                        payloadParam.init(parameterType, customParameterTypes[index], index);
                        getOtherParamList().add(payloadParam);
                    } else if ((headerParam = headerParams.get(paramName)) != null) {
                        headerParam.init(parameterType, index);
                    } else {
                        validateQueryParam(index, resource, parameterType, false);
                    }
            }
        }
        if (queryParams.isNotEmpty()) {
            getOtherParamList().add(this.queryParams);
        }
        if (headerParams.isNotEmpty()) {
            getOtherParamList().add(this.headerParams);
        }
    }

    private void populatePayloadAndHeaderParamTokens(ResourceMethodType balResource, boolean constraintValidation) {
        for (String paramName : balResource.getParamNames()) {
            BMap annotations = (BMap) balResource.getAnnotation(StringUtils.fromString(PARAM_ANNOT_PREFIX + paramName));
            if (annotations == null) {
                continue;
            }
            Object[] annotationsKeys = annotations.getKeys();
            validateForMultipleHTTPAnnotationsOnSingleParam(annotationsKeys, paramName);
            for (Object objKey : annotationsKeys) {
                String key = ((BString) objKey).getValue();
                if (PAYLOAD_ANNOTATION.equals(key)) {
                    if (payloadParam == null) {
                        createPayloadParam(paramName, annotations, constraintValidation);
                    } else {
                        throw HttpUtil.createHttpError(
                                "invalid multiple '" + PROTOCOL_HTTP + COLON + ANN_NAME_PAYLOAD + "' annotation usage");
                    }
                } else if (HEADER_ANNOTATION.equals(key)) {
                    createHeaderParam(paramName, annotations);
                } else if (CALLER_INFO_ANNOTATION.equals(key)) {
                    BMap callerInfo = annotations.getMapValue(StringUtils.fromString(CALLER_INFO_ANNOTATION));
                    Object respondType = callerInfo.get(ANN_FIELD_RESPOND_TYPE);
                    if (respondType instanceof BTypedesc) {
                        this.callerInfoType = TypeUtils.getReferredType(((BTypedesc) respondType).getDescribingType());
                    }
                }
            }
        }
    }

    private void validateForMultipleHTTPAnnotationsOnSingleParam(Object[] annotationsKeys, String paramName) {
        boolean alreadyAnnotated = false;
        for (Object objKey : annotationsKeys) {
            String key = ((BString) objKey).getValue();
            if (alreadyAnnotated && isAllowedResourceParamAnnotation(key)) {
                throw HttpUtil.createHttpError(
                        "cannot specify more than one http annotation for parameter '" + paramName + "'");
            } else if (!alreadyAnnotated && isAllowedResourceParamAnnotation(key)) {
                alreadyAnnotated = true;
            }
        }
    }

    private boolean isAllowedResourceParamAnnotation(String key) {
        return PAYLOAD_ANNOTATION.equals(key) || CALLER_ANNOTATION.equals(key) || HEADER_ANNOTATION.equals(key);
    }

    private void createPayloadParam(String paramName, BMap annotations, boolean constraintValidation) {
        this.payloadParam = new PayloadParam(paramName, constraintValidation);
        BMap mapValue = annotations.getMapValue(StringUtils.fromString(PAYLOAD_ANNOTATION));
        Object mediaType = mapValue.get(HttpConstants.ANN_FIELD_MEDIA_TYPE);
        if (mediaType instanceof BString) {
            String value = ((BString) mediaType).getValue();
            this.payloadParam.getMediaTypes().add(value);
        } else if (mediaType instanceof BArray) {
            String[] value = ((BArray) mediaType).getStringArray();
            if (value.length != 0) {
                this.payloadParam.getMediaTypes().add(Arrays.toString(value));
            }
        }
    }

    private void createHeaderParam(String paramName, BMap annotations) {
        HeaderParam headerParam = new HeaderParam(paramName);
        BMap mapValue = annotations.getMapValue(StringUtils.fromString(HEADER_ANNOTATION));
        Object headerName = mapValue.get(HttpConstants.ANN_FIELD_NAME);
        if (headerName instanceof BString) {
            String value = ((BString) headerName).getValue();
            headerParam.setHeaderName(value);
        } else {
            // if the name field is not stated, use the param token as header key
            headerParam.setHeaderName(HttpUtil.unescapeAndEncodeValue(paramName));
        }
        this.headerParams.add(headerParam);
    }

    private void validateQueryParam(int index, ResourceMethodType balResource, Type parameterType, boolean readonly) {
        if (parameterType instanceof UnionType) {
            List<Type> memberTypes = ((UnionType) parameterType).getMemberTypes();
            int size = memberTypes.size();
            if (!memberTypes.stream().allMatch(type -> type.getTag() == TypeTags.FINITE_TYPE_TAG) &&
                    (size > 2 || !parameterType.isNilable())) {
                throw HttpUtil.createHttpError(
                        "invalid query param type '" + parameterType.getName() + "': a basic type or an array " +
                                "of a basic type can only be union with '()' Eg: string|() or string[]|()");
            }
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.NULL_TAG) {
                    continue;
                }
                createQueryParam(index, balResource, type, true, readonly);
                break;
            }
        } else if (parameterType instanceof IntersectionType) {
            // Assumes that the only intersection type is readonly
            List<Type> memberTypes = ((IntersectionType) parameterType).getConstituentTypes();
            int size = memberTypes.size();
            if (size > 2) {
                throw HttpUtil.createHttpError(
                        "invalid query param type '" + parameterType.getName() +
                                "': only readonly intersection is allowed");
            }
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.READONLY_TAG) {
                    continue;
                }
                if (type.getTag() == TypeTags.UNION_TAG) {
                    validateQueryParam(index, balResource, type, true);
                    return;
                }
                createQueryParam(index, balResource, type, false, true);
                break;
            }
        } else {
            createQueryParam(index, balResource, parameterType, false, false);
        }
    }

    private void createQueryParam(int index, ResourceMethodType balResource, Type type, boolean nilable,
                                  boolean readonly) {
        io.ballerina.runtime.api.types.Parameter parameter = balResource.getParameters()[index];
        QueryParam queryParam = new QueryParam(type, HttpUtil.unescapeAndEncodeValue(parameter.name), index, nilable,
                                               readonly, parameter.isDefault);
        this.queryParams.add(queryParam);
    }

    private void validatePathParam(ResourceMethodType resource, int pathParamCount) {
        Arrays.stream(this.paramTypes, 0, pathParamCount).forEach(type -> {
            int typeTag = type.getTag();
            if (isValidBasicType(typeTag) || (typeTag == TypeTags.ARRAY_TAG && isValidBasicType(
                    ((ArrayType) type).getElementType().getTag()))) {
                return;
            }
            throw HttpUtil.createHttpError("incompatible path parameter type: '" + type.getName() + "'",
                                           HttpErrorType.GENERIC_LISTENER_ERROR);
        });
    }

    private boolean isValidBasicType(int typeTag) {
        return typeTag == TypeTags.STRING_TAG || typeTag == TypeTags.INT_TAG || typeTag == TypeTags.FLOAT_TAG ||
                typeTag == TypeTags.BOOLEAN_TAG || typeTag == TypeTags.DECIMAL_TAG;
    }

    public boolean isPayloadBindingRequired() {
        return payloadParam != null;
    }

    public List<Parameter> getOtherParamList() {
        return this.otherParamList;
    }

    public int getPathParamTokenLength() {
        return pathParamTokens.length;
    }

    /**
     * Gets the map of query params for given raw query string.
     *
     * @return a map of query params
     */
    public BMap<BString, Object> getQueryParams(Object rawQueryString) {
        BMap<BString, Object> queryParams = ValueCreator.createMapValue(MAP_TYPE);

        if (rawQueryString != null) {
            try {
                URIUtil.populateQueryParamMap((String) rawQueryString, queryParams);
            } catch (UnsupportedEncodingException e) {
                throw HttpUtil.createHttpError("error while retrieving query param from message: " + e.getMessage(),
                                               HttpErrorType.GENERIC_LISTENER_ERROR);
            }
        }
        return queryParams;
    }

    public Type getCallerInfoType() {
        return callerInfoType;
    }
}
