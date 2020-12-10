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
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpErrorType;
import org.ballerinalang.net.http.HttpResource;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.uri.URIUtil;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.ballerinalang.net.http.compiler.ResourceSignatureValidator.COMPULSORY_PARAM_COUNT;

/**
 * This class holds the resource signature parameters.
 *
 * @since 0.963.0
 */
public class ParamHandler {

    private final int pathParamCount;
    private String[] pathParamTokens = new String[0];
    private HttpResource resource;
    private final Type[] paramTypes;
    private Type entityBody;
    private List<Type> pathParamTypes;
    private int paramCount = COMPULSORY_PARAM_COUNT;
    private List<Parameter> otherParamList = new ArrayList<>();
    private NonRecurringParam callerParam = null;
    private NonRecurringParam requestParam = null;
    private AllQueryParams queryParams = new AllQueryParams();

    private static final MapType MAP_TYPE = TypeCreator.createMapType(
            TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
    private static final String CALLER_TYPE = HttpConstants.PROTOCOL_HTTP + HttpConstants.COLON + HttpConstants.CALLER;
    private static final String REQ_TYPE = HttpConstants.PROTOCOL_HTTP + HttpConstants.COLON + HttpConstants.REQUEST;

    public ParamHandler(HttpResource resource, int pathParamCount) {
        this.resource = resource;
        this.pathParamCount = pathParamCount;
        this.paramTypes = resource.getBalResource().getParameterTypes();
        populatePathParamTokens(resource, pathParamCount);
        validateSignatureParams();
    }

    private void populatePathParamTokens(HttpResource resource, int pathParamCount) {
        if (pathParamCount == 0) {
            return;
        }
        this.pathParamTokens = Arrays.copyOfRange(resource.getBalResource().getParamNames(), 0, pathParamCount);
    }

    void validateSignatureParams() {
        if (paramTypes.length == pathParamCount) {
            return;
        }

        for (int index = pathParamCount; index < paramTypes.length; index++) {
            ResourceFunctionType balResource = resource.getBalResource();
            Type parameterType = balResource.getParameterTypes()[index];
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
                    validateQueryParam(index, balResource, parameterType);
            }
        }
        if (queryParams.isNotEmpty()) {
            getOtherParamList().add(this.queryParams);
        }




//        if (resource.getEntityBodyAttributeValue() == null ||
//                resource.getEntityBodyAttributeValue().isEmpty()) {
//            validatePathParam(paramTypes.subList(COMPULSORY_PARAM_COUNT, paramTypes.size()));
//        } else {
//            int lastParamIndex = paramTypes.size() - 1;
//            validatePathParam(paramTypes.subList(COMPULSORY_PARAM_COUNT, lastParamIndex));
//            validateEntityBodyParam(paramTypes.get(lastParamIndex));
//        }
    }

    private void validateQueryParam(int index, ResourceFunctionType balResource, Type parameterType) {
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

    private void validatePathParam(List<Type> paramDetails) {
        for (Type paramType : paramDetails) {
            int varTag = paramType.getTag();
            if (varTag != TypeTags.STRING_TAG && varTag != TypeTags.INT_TAG && varTag != TypeTags.BOOLEAN_TAG &&
                    varTag != TypeTags.FLOAT_TAG) {
                throw HttpUtil.createHttpError("incompatible resource signature parameter type",
                                               HttpErrorType.GENERIC_LISTENER_ERROR);
            }
            paramCount++;
        }
        this.pathParamTypes = paramDetails;
    }

    private void validateEntityBodyParam(Type entityBodyParamType) {
        int type = entityBodyParamType.getTag();
        if (type == TypeTags.RECORD_TYPE_TAG || type == TypeTags.JSON_TAG || type == TypeTags.XML_TAG ||
                type == TypeTags.STRING_TAG || (type == TypeTags.ARRAY_TAG && validArrayType(entityBodyParamType))) {
            this.entityBody = entityBodyParamType;
            paramCount++;
        } else {
            throw HttpUtil.createHttpError("incompatible entity-body type : " + entityBodyParamType.getName(),
                                           HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    /**
     * Check the validity of array type in data binding scenario.
     *
     * @param entityBodyParamType Represents resource parameter details
     * @return a boolean indicating the validity of the array type
     */
    private boolean validArrayType(Type entityBodyParamType) {
        return ((ArrayType) entityBodyParamType).getElementType().getTag() == TypeTags.BYTE_TAG ||
                ((ArrayType) entityBodyParamType).getElementType().getTag() == TypeTags.RECORD_TYPE_TAG;
    }

    public Type getEntityBody() {
        return entityBody;
    }

    List<Type> getPathParamTypes() {
        return pathParamTypes;
    }

    int getParamCount() {
        return paramCount;
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
