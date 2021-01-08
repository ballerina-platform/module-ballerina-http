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

package org.ballerinalang.net.http.signature;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpErrorType;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.uri.URIUtil;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.ballerinalang.net.http.HttpConstants.ANN_NAME_CALLER_INFO;
import static org.ballerinalang.net.http.HttpConstants.ANN_NAME_PAYLOAD;
import static org.ballerinalang.net.http.HttpConstants.COLON;
import static org.ballerinalang.net.http.HttpConstants.PROTOCOL_HTTP;
import static org.ballerinalang.net.http.HttpConstants.PROTOCOL_PACKAGE_HTTP;

/**
 * This class holds the resource signature parameters.
 *
 * @since 0.963.0
 */
public class ParamHandler {

    private final Type[] paramTypes;
    private final int pathParamCount;
    private ResourceMethodType resource;
    private String[] pathParamTokens = new String[0];
    private List<Parameter> otherParamList = new ArrayList<>();
    private PayloadParam payloadParam = null;
    private NonRecurringParam callerParam = null;
    private NonRecurringParam requestParam = null;
    private AllQueryParams queryParams = new AllQueryParams();

    private static final String PARAM_ANNOT_PREFIX = "$param$.";
    private static final MapType MAP_TYPE = TypeCreator.createMapType(
            TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
    private static final String CALLER_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.CALLER;
    private static final String REQ_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.REQUEST;
    private static final String PAYLOAD_ANNOTATION = PROTOCOL_PACKAGE_HTTP + COLON + ANN_NAME_PAYLOAD;
    private static final String CALLER_ANNOTATION = PROTOCOL_PACKAGE_HTTP + COLON + ANN_NAME_CALLER_INFO;

    public ParamHandler(ResourceMethodType resource, int pathParamCount) {
        this.resource = resource;
        this.pathParamCount = pathParamCount;
        this.paramTypes = resource.getParameterTypes();
        populatePathParamTokens(resource, pathParamCount);
        populatePayloadAndHeaderParamTokens(resource);
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
        for (int index = pathParamCount; index < paramTypes.length; index++) {
            Type parameterType = resource.getParameterTypes()[index];
            String typeName = parameterType.toString();
            switch (typeName) {
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
                default:
                    // TODO handle query, payload, header params
                    String paramName = resource.getParamNames()[index];
                    if (payloadParam != null && paramName.equals(payloadParam.getToken())) {
                        payloadParam.init(parameterType, index);
                        getOtherParamList().add(payloadParam);
                    } else {
                        validateQueryParam(index, resource, parameterType);
                    }
            }
        }
        if (queryParams.isNotEmpty()) {
            getOtherParamList().add(this.queryParams);
        }
    }

    private void populatePayloadAndHeaderParamTokens(ResourceMethodType balResource) {
        for (String paramName : balResource.getParamNames()) {
            BMap annotations = (BMap) balResource.getAnnotation(StringUtils.fromString(PARAM_ANNOT_PREFIX + paramName));
            if (annotations == null) {
                continue;
            }
            Object[] annotationsKeys = annotations.getKeys();
            validateForMultipleHTTPAnnotations(annotationsKeys, paramName);
            for (Object objKey : annotationsKeys) {
                String key = ((BString) objKey).getValue();
                if (PAYLOAD_ANNOTATION.equals(key)) {
                    if (payloadParam == null) {
                        createPayloadParam(paramName, annotations);
                    } else {
                        throw HttpUtil.createHttpError(
                                "invalid multiple '" + PROTOCOL_HTTP + COLON + ANN_NAME_PAYLOAD + "' annotation usage");
                    }
                }
            }
        }
    }

    private void validateForMultipleHTTPAnnotations(Object[] annotationsKeys, String paramName) {
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
        return PAYLOAD_ANNOTATION.equals(key) || CALLER_ANNOTATION.equals(key);
    }

    private void createPayloadParam(String paramName, BMap annotations) {
        this.payloadParam = new PayloadParam(paramName);
        BMap mapValue = annotations.getMapValue(StringUtils.fromString(PAYLOAD_ANNOTATION));
        Object mediaType = mapValue.get(StringUtils.fromString("mediaType"));
        if (mediaType instanceof BString) {
            String value = ((BString) mediaType).getValue();
            if (!value.isEmpty()) {
                this.payloadParam.getMediaTypes().add(value);
            }
        } else {
            String[] value = ((BArray) mediaType).getStringArray();
            if (value.length != 0) {
                this.payloadParam.getMediaTypes().add(Arrays.toString(value));
            }
        }
    }

    private void validateQueryParam(int index, ResourceMethodType balResource, Type parameterType) {
        if (parameterType instanceof UnionType) {
            List<Type> memberTypes = ((UnionType) parameterType).getMemberTypes();
            int size = memberTypes.size();
            if (size > 2 || !parameterType.isNilable()) {
                throw HttpUtil.createHttpError(
                        "invalid query param type '" + parameterType.getName() + "': a basic type or an array " +
                                "of a basic type can only be union with '()' Eg: string|() or string[]|()");
            }
            for (Type type : memberTypes) {
                if (type.getTag() == TypeTags.NULL_TAG) {
                    continue;
                }
                QueryParam queryParam = new QueryParam(type, balResource.getParamNames()[index], index, true);
                this.queryParams.add(queryParam);
                break;
            }
        } else {
            QueryParam queryParam = new QueryParam(parameterType, balResource.getParamNames()[index], index, false);
            this.queryParams.add(queryParam);
        }
    }

    private void validatePathParam(ResourceMethodType resource, int pathParamCount) {
        Type[] parameterTypes = resource.getParameterTypes();
        Arrays.stream(parameterTypes, 0, pathParamCount).forEach(type -> {
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

    public String[] getPathParamTokens() {
        return pathParamTokens;
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
}
