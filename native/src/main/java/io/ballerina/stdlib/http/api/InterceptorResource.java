/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.ErrorType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.NullType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;

import java.util.Collections;
import java.util.List;
import java.util.Locale;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_RESOURCE_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * {@code InterceptorResource} This is the http wrapper for the {@code InterceptorResource} implementation.
 *
 * @since SL beta 4
 */
public class InterceptorResource implements Resource {

    private static final BString HTTP_RESOURCE_CONFIG =
            StringUtils.fromString(ModuleUtils.getHttpPackageIdentifier() + ":" + ANN_NAME_RESOURCE_CONFIG);
    private static final String RETURN_ANNOT_PREFIX = "$returns$";

    private MethodType balResource;
    private List<String> methods;
    private String path;
    private ParamHandler paramHandler;
    private InterceptorService parentService;
    private String wildcardToken;
    private int pathParamCount;
    private boolean treatNilableAsOptional = true;
    private String resourceType = HttpConstants.HTTP_NORMAL;

    protected InterceptorResource(MethodType resource, InterceptorService parentService) {
        this.balResource = resource;
        this.parentService = parentService;
        this.setResourceType(parentService.getServiceType());
        if (balResource instanceof ResourceMethodType) {
            this.validateAndPopulateResourcePath();
            this.validateAndPopulateMethod();
            this.validateReturnType();
        }
    }

    @Override
    public String getName() {
        return balResource.getName();
    }

    @Override
    public Object getCorsHeaders() {
        return null;
    }

    @Override
    public ParamHandler getParamHandler() {
        return paramHandler;
    }

    @Override
    public InterceptorService getParentService() {
        return parentService;
    }

    public ResourceMethodType getBalResource() {
        return (ResourceMethodType) balResource;
    }

    @Override
    public List<String> getMethods() {
        return methods;
    }

    @Override
    public List<String> getConsumes() {
        return null;
    }

    @Override
    public List<String> getProduces() {
        return null;
    }

    @Override
    public List<String> getProducesSubTypes() {
        return null;
    }

    private void validateAndPopulateMethod() {
        String accessor = getBalResource().getAccessor();
        if (HttpConstants.DEFAULT_HTTP_METHOD.equals(accessor.toLowerCase(Locale.getDefault()))) {
            // TODO: Fix this properly
            // setting method as null means that no specific method. Resource is exposed for any method match
            this.methods = null;
        } else {
            if (this.getResourceType().equals(HttpConstants.HTTP_REQUEST_ERROR_INTERCEPTOR)) {
                throw new BallerinaConnectorException("interceptor resources are allowed to have only default " +
                        "method");
            } else {
                this.methods = Collections.singletonList(accessor.toUpperCase(Locale.getDefault()));
            }
        }
    }

    public String getPath() {
        return path;
    }

    private void validateAndPopulateResourcePath() {
        ResourceMethodType resourceFunctionType = getBalResource();
        String[] paths = resourceFunctionType.getResourcePath();
        StringBuilder resourcePath = new StringBuilder();
        int count = 0;
        for (String segment : paths) {
            resourcePath.append(HttpConstants.SINGLE_SLASH);
            if (HttpConstants.STAR_IDENTIFIER.equals(segment)) {
                String pathSegment = resourceFunctionType.getParamNames()[count++];
                resourcePath.append(HttpConstants.OPEN_CURL_IDENTIFIER)
                        .append(pathSegment).append(HttpConstants.CLOSE_CURL_IDENTIFIER);
            } else if (HttpConstants.DOUBLE_STAR_IDENTIFIER.equals(segment)) {
                this.wildcardToken = resourceFunctionType.getParamNames()[count++];
                resourcePath.append(HttpConstants.STAR_IDENTIFIER);
            } else if (HttpConstants.DOT_IDENTIFIER.equals(segment)) {
                // default set as "/"
                break;
            } else {
                resourcePath.append(HttpUtil.unescapeAndEncodeValue(segment));
            }
        }
        this.path = resourcePath.toString().replaceAll(HttpConstants.REGEX, SINGLE_SLASH);
        if (this.getResourceType().equals(HttpConstants.HTTP_REQUEST_ERROR_INTERCEPTOR) &&
                !this.path.equals(HttpConstants.DEFAULT_SUB_PATH)) {
            throw new BallerinaConnectorException("interceptor resources are not allowed to have specific " +
                    "base path");
        }
        this.pathParamCount = count;
    }

    @Override
    public boolean isTreatNilableAsOptional() {
        return treatNilableAsOptional;
    }

    public void setResourceType(String resourceType) {
        this.resourceType = resourceType;
    }

    public String getResourceType() {
        return this.resourceType;
    }

    public static InterceptorResource buildInterceptorResource(MethodType resource, InterceptorService
            interceptorService) {
        InterceptorResource interceptorResource = new InterceptorResource(resource, interceptorService);
        BMap resourceConfigAnnotation = getResourceConfigAnnotation(resource);

        if (checkConfigAnnotationAvailability(resourceConfigAnnotation)) {
            throw new BallerinaConnectorException("Resource Config annotation is not supported in " +
                    "interceptor resource");
        }

        interceptorResource.prepareAndValidateSignatureParams();
        return interceptorResource;
    }

    /**
     * Get the `BMap` resource configuration of the given resource.
     *
     * @param resource The resource
     * @return the resource configuration of the given resource
     */
    public static BMap getResourceConfigAnnotation(MethodType resource) {
        return (BMap) resource.getAnnotation(HTTP_RESOURCE_CONFIG);
    }

    private void prepareAndValidateSignatureParams() {
        paramHandler = new ParamHandler(getBalResource(), this.pathParamCount);
    }

    @Override
    public String getWildcardToken() {
        return wildcardToken;
    }

    private void validateReturnType() {
        Type returnType = getBalResource().getType().getReturnType();
        if (!(checkReturnType(returnType))) {
            throw new BallerinaConnectorException("interceptor resources are not allowed to return " +
                    returnType.toString());
        }
    }

    private boolean checkReturnType(Type returnType) {
        if (returnType instanceof UnionType) {
            List<Type> members = ((UnionType) returnType).getMemberTypes();
            for (Type member : members) {
                if (!checkReturnTypeForObject(member)) {
                    return false;
                }
            }
            return true;
        } else {
            return checkReturnTypeForObject(returnType);
        }
    }

    private boolean checkReturnTypeForObject(Type returnType) {
        if (returnType instanceof ServiceType) {
            return true;
        } else if (returnType instanceof ErrorType) {
            return true;
        } else if (returnType instanceof NullType) {
            return true;
        } else {
            return false;
        }
    }
}
