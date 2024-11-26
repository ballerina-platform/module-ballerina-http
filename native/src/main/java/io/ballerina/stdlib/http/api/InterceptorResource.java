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

import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;

import java.util.Collections;
import java.util.List;
import java.util.Locale;

import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;

/**
 * {@code InterceptorResource} This is the http wrapper for the {@code InterceptorResource} implementation.
 *
 * @since SL Beta 4
 */
public class InterceptorResource implements Resource {

    private MethodType balResource;
    private List<String> methods;
    private String path;
    private ParamHandler paramHandler;
    private InterceptorService parentService;
    private String wildcardToken;
    private int pathParamCount;
    private boolean treatNilableAsOptional = true;

    protected InterceptorResource(MethodType resource, InterceptorService parentService, boolean fromListener) {
        this.balResource = resource;
        this.parentService = parentService;
        if (balResource instanceof ResourceMethodType) {
            this.validateAndPopulateResourcePath(fromListener);
            this.validateAndPopulateMethod();
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
        if (HttpUtil.isDefaultResource(accessor)) {
            // TODO: Fix this properly
            // setting method as null means that no specific method. Resource is exposed for any method match
            this.methods = null;
        } else {
            this.methods = Collections.singletonList(accessor.toUpperCase(Locale.getDefault()));
        }
    }

    public String getPath() {
        return path;
    }

    private void validateAndPopulateResourcePath(boolean fromListener) {
        ResourceMethodType resourceFunctionType = getBalResource();
        String[] paths = resourceFunctionType.getResourcePath();
        StringBuilder resourcePath = new StringBuilder();
        int count = 0;
        for (String segment : paths) {
            resourcePath.append(HttpConstants.SINGLE_SLASH);
            if (HttpConstants.PATH_PARAM_IDENTIFIER.equals(segment)) {
                String pathSegment = resourceFunctionType.getParamNames()[count++];
                resourcePath.append(HttpConstants.OPEN_CURL_IDENTIFIER)
                        .append(pathSegment).append(HttpConstants.CLOSE_CURL_IDENTIFIER);
            } else if (HttpConstants.PATH_REST_PARAM_IDENTIFIER.equals(segment)) {
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
        if (fromListener && !this.path.equals(HttpConstants.DEFAULT_SUB_PATH)) {
            throw new BallerinaConnectorException("interceptor services engaged in listener level can only support "
                    + "resource method with default path([string... path])");
        }
        this.pathParamCount = count;
    }

    @Override
    public boolean isTreatNilableAsOptional() {
        return treatNilableAsOptional;
    }

    public static InterceptorResource buildInterceptorResource(MethodType resource, InterceptorService
            interceptorService, boolean fromListener) {
        InterceptorResource interceptorResource = new InterceptorResource(resource, interceptorService, fromListener);
        interceptorResource.prepareAndValidateSignatureParams();
        return interceptorResource;
    }

    private void prepareAndValidateSignatureParams() {
        paramHandler = new ParamHandler(getBalResource(), this.pathParamCount, false, false);
    }

    @Override
    public String getWildcardToken() {
        return wildcardToken;
    }

}
