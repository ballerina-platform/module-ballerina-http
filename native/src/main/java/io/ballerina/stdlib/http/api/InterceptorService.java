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
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.service.signature.RemoteMethodParamHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.URITemplate;
import io.ballerina.stdlib.http.uri.URITemplateException;
import io.ballerina.stdlib.http.uri.parser.Literal;

import java.io.UnsupportedEncodingException;
import java.util.List;

/**
 * {@code InterceptorService} This is the http wrapper for the {@code InterceptorService} implementation.
 *
 * @since SL Beta 4
 */
public class InterceptorService implements Service {

    private final BObject balService;
    private InterceptorResource interceptorResource;
    private List<String> allAllowedMethods;
    private final String basePath;
    private URITemplate<Resource, HttpCarbonMessage> uriTemplate;
    private String hostName;
    private String serviceType;
    private RemoteMethodType remoteMethod;
    private RemoteMethodParamHandler remoteMethodParamHandler;

    protected InterceptorService(BObject service, String basePath) {
        this.balService = service;
        this.basePath = basePath;
    }

    public BObject getBalService() {
        return balService;
    }

    public InterceptorResource getResource() {
        return interceptorResource;
    }

    public void setInterceptorResource(InterceptorResource resource) {
        this.interceptorResource = resource;
    }

    @Override
    public List<String> getAllAllowedMethods() {
        return allAllowedMethods;
    }

    @Override
    public String getOasResourceLink() {
        return null;
    }

    public void setAllAllowedMethods(List<String> allAllowedMethods) {
        this.allAllowedMethods = allAllowedMethods;
    }

    public void setHostName(String hostName) {
        this.hostName = hostName;
    }

    public String getHostName() {
        return hostName;
    }

    @Override
    public String getBasePath() {
        return basePath;
    }

    public void setServiceType(String serviceType) {
        this.serviceType = serviceType;
    }

    public String getServiceType() {
        return this.serviceType;
    }

    @Override
    public BMap<BString, Object> getCompressionConfig() {
        return null;
    }

    @Override
    public String getChunkingConfig() {
        return null;
    }

    @Override
    public String getMediaTypeSubtypePrefix() {
        return null;
    }

    @Override
    public URITemplate<Resource, HttpCarbonMessage> getUriTemplate() throws URITemplateException {
        if (uriTemplate == null) {
            uriTemplate = new URITemplate<>(new Literal<>(new ResourceDataElement(), "/"));
        }
        return uriTemplate;
    }

    public static InterceptorService buildHttpService(BObject service, String basePath, String serviceType,
                                                      boolean fromListener) {
        InterceptorService interceptorService = new InterceptorService(service, basePath);
        interceptorService.setServiceType(serviceType);
        interceptorService.setHostName(HttpConstants.DEFAULT_HOST);
        if (serviceType.equals(HttpConstants.REQUEST_INTERCEPTOR) ||
                serviceType.equals(HttpConstants.REQUEST_ERROR_INTERCEPTOR)) {
            processInterceptorResource(interceptorService, fromListener);
            interceptorService.setAllAllowedMethods(DispatcherUtil.getInterceptorResourceMethods(
                    interceptorService));
        } else {
            processInterceptorRemoteMethod(interceptorService);
        }
        return interceptorService;
    }

    private static void processInterceptorResource(InterceptorService interceptorService, boolean fromListener) {
        MethodType[] resourceMethods = ((ServiceType) TypeUtils.getType(interceptorService.getBalService()))
                .getResourceMethods();
        if (resourceMethods.length == 1) {
            MethodType resource = resourceMethods[0];
            updateInterceptorResourceTree(interceptorService,
                    InterceptorResource.buildInterceptorResource(resource, interceptorService, fromListener));
        }
    }

    private static void processInterceptorRemoteMethod(InterceptorService interceptorService) {
        RemoteMethodType[] remoteMethods = ((ServiceType) TypeUtils.getType(interceptorService.getBalService()))
                .getRemoteMethods();
        if (remoteMethods.length == 1) {
            RemoteMethodType remoteMethod = remoteMethods[0];
            if (remoteMethod.getName().equals(HttpConstants.INTERCEPT_RESPONSE) ||
                    remoteMethod.getName().equals(HttpConstants.INTERCEPT_RESPONSE_ERROR)) {
                interceptorService.setRemoteMethodParamHandler(remoteMethod);
            }
        }
    }

    public void setRemoteMethodParamHandler(RemoteMethodType remoteMethod) {
        this.remoteMethod = remoteMethod;
        this.remoteMethodParamHandler = new RemoteMethodParamHandler(remoteMethod);
    }

    public RemoteMethodParamHandler getRemoteMethodParamHandler() {
        return this.remoteMethodParamHandler;
    }

    public RemoteMethodType getRemoteMethod() {
        return this.remoteMethod;
    }

    private static void updateInterceptorResourceTree(InterceptorService httpService,
                                                      InterceptorResource httpInterceptorResource) {
        try {
            httpService.getUriTemplate().parse(httpInterceptorResource.getPathSegments(), httpInterceptorResource,
                    new ResourceElementFactory());
        } catch (URITemplateException | UnsupportedEncodingException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
        httpService.setInterceptorResource(httpInterceptorResource);
    }
}
