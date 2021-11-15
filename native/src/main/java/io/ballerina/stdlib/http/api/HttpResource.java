/*
*  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing,
*  software distributed under the License is distributed on an
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
*  KIND, either express or implied.  See the License for the
*  specific language governing permissions and limitations
*  under the License.
*/
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_RESOURCE_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * {@code HttpResource} This is the http wrapper for the {@code Resource} implementation.
 *
 * @since 0.94
 */
public class HttpResource implements Resource {

    private static final Logger log = LoggerFactory.getLogger(HttpResource.class);

    private static final BString CONSUMES_FIELD = StringUtils.fromString("consumes");
    private static final BString PRODUCES_FIELD = StringUtils.fromString("produces");
    private static final BString CORS_FIELD = StringUtils.fromString("cors");
    private static final BString TRANSACTION_INFECTABLE_FIELD = StringUtils.fromString("transactionInfectable");
    private static final BString HTTP_RESOURCE_CONFIG =
            StringUtils.fromString(ModuleUtils.getHttpPackageIdentifier() + ":" + ANN_NAME_RESOURCE_CONFIG);
    private static final String RETURN_ANNOT_PREFIX = "$returns$";

    private MethodType balResource;
    private List<String> methods;
    private String path;
    private String entityBodyAttribute;
    private List<String> consumes;
    private List<String> produces;
    private List<String> producesSubTypes;
    private CorsHeaders corsHeaders;
    private ParamHandler paramHandler;
    private HttpService parentService;
    private boolean transactionInfectable = true; //default behavior
    private String wildcardToken;
    private int pathParamCount;
    private String returnMediaType;
    private BMap cacheConfig;
    private boolean treatNilableAsOptional;

    protected HttpResource(MethodType resource, HttpService parentService) {
        this.balResource = resource;
        this.parentService = parentService;
        this.producesSubTypes = new ArrayList<>();
        if (balResource instanceof ResourceMethodType) {
            this.populateResourcePath();
            this.populateMethod();
            this.populateReturnAnnotationData();
        }
    }

    protected HttpResource() {

    }

    @Override
    public String getName() {
        return balResource.getName();
    }

    public String getServiceName() {
        return balResource.getParentObjectType().getName();
    }

    @Override
    public ParamHandler getParamHandler() {
        return paramHandler;
    }

    @Override
    public HttpService getParentService() {
        return parentService;
    }

    @Override
    public ResourceMethodType getBalResource() {
        return (ResourceMethodType) balResource;
    }

    @Override
    public List<String> getMethods() {
        return methods;
    }

    private void populateMethod() {
        String accessor = getBalResource().getAccessor();
        if (HttpConstants.DEFAULT_HTTP_METHOD.equals(accessor.toLowerCase(Locale.getDefault()))) {
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

    private void populateResourcePath() {
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
        this.pathParamCount = count;
    }

    @Override
    public List<String> getConsumes() {
        return consumes;
    }

    public void setConsumes(List<String> consumes) {
        this.consumes = consumes;
    }

    @Override
    public List<String> getProduces() {
        return produces;
    }

    public void setProduces(List<String> produces) {
        this.produces = produces;

        if (produces != null) {
            List<String> subAttributeValues = produces.stream()
                                                .map(mediaType -> mediaType.trim().substring(0, mediaType.indexOf('/')))
                                                .distinct()
                                                .collect(Collectors.toList());
            setProducesSubTypes(subAttributeValues);
        }
    }

    @Override
    public List<String> getProducesSubTypes() {
        return producesSubTypes;
    }

    public void setProducesSubTypes(List<String> producesSubTypes) {
        this.producesSubTypes = producesSubTypes;
    }

    @Override
    public CorsHeaders getCorsHeaders() {
        return corsHeaders;
    }

    public void setCorsHeaders(CorsHeaders corsHeaders) {
        this.corsHeaders = corsHeaders;
    }

    public boolean isTransactionInfectable() {
        return transactionInfectable;
    }

    public void setTransactionInfectable(boolean transactionInfectable) {
        this.transactionInfectable = transactionInfectable;
    }

    public void setTreatNilableAsOptional(boolean treatNilableAsOptional) {
        this.treatNilableAsOptional = treatNilableAsOptional;
    }

    @Override
    public boolean isTreatNilableAsOptional() {
        return treatNilableAsOptional;
    }

    public static HttpResource buildHttpResource(MethodType resource, HttpService httpService) {
        HttpResource httpResource = new HttpResource(resource, httpService);
        BMap resourceConfigAnnotation = getResourceConfigAnnotation(resource);

        if (checkConfigAnnotationAvailability(resourceConfigAnnotation)) {
            httpResource.setConsumes(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(CONSUMES_FIELD).getStringArray()));
            httpResource.setProduces(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(PRODUCES_FIELD).getStringArray()));
            httpResource.setCorsHeaders(CorsHeaders.buildCorsHeaders(resourceConfigAnnotation.getMapValue(CORS_FIELD)));
            httpResource
                    .setTransactionInfectable(resourceConfigAnnotation.getBooleanValue(TRANSACTION_INFECTABLE_FIELD));
        }
        processResourceCors(httpResource, httpService);
        httpResource.prepareAndValidateSignatureParams();
        return httpResource;
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

    private static List<String> getAsStringList(Object[] values) {
        if (values == null) {
            return null;
        }
        List<String> valuesList = new ArrayList<>();
        for (Object val : values) {
            valuesList.add(val.toString().trim());
        }
        return !valuesList.isEmpty() ? valuesList : null;
    }

    private static void processResourceCors(HttpResource resource, HttpService service) {
        CorsHeaders corsHeaders = resource.getCorsHeaders();
        if (corsHeaders == null || !corsHeaders.isAvailable()) {
            //resource doesn't have CORS headers, hence use service CORS
            resource.setCorsHeaders(service.getCorsHeaders());
            return;
        }

        if (corsHeaders.getAllowOrigins() == null) {
            corsHeaders.setAllowOrigins(Stream.of("*").collect(Collectors.toList()));
        }

        if (corsHeaders.getAllowMethods() != null) {
            return;
        }

        if (resource.getMethods() != null) {
            corsHeaders.setAllowMethods(resource.getMethods());
            return;
        }
        corsHeaders.setAllowMethods(DispatcherUtil.addAllMethods());
    }

    private void prepareAndValidateSignatureParams() {
        paramHandler = new ParamHandler(getBalResource(), this.pathParamCount);
    }

    @Override
    public String getWildcardToken() {
        return wildcardToken;
    }

    private void populateReturnAnnotationData() {
        BMap annotations = (BMap) getBalResource().getAnnotation(StringUtils.fromString(RETURN_ANNOT_PREFIX));
        if (annotations == null) {
            return;
        }
        Object[] annotationsKeys = annotations.getKeys();
        for (Object objKey : annotationsKeys) {
            BString key = ((BString) objKey);
            if (ParamHandler.PAYLOAD_ANNOTATION.equals(key.getValue())) {
                Object mediaType = annotations.getMapValue(key).get(HttpConstants.ANN_FIELD_MEDIA_TYPE);
                if (mediaType instanceof BString) {
                    this.returnMediaType = ((BString) mediaType).getValue();
                } else if (mediaType instanceof BArray) {
                    BArray mediaTypeArr = (BArray) mediaType;
                    if (mediaTypeArr.getLength() != 0) {
                        // When user provides an array of mediaTypes, the first element is considered for `Content-Type`
                        // of the response assuming the priority order.
                        this.returnMediaType = ((BArray) mediaType).get(0).toString();
                    }
                }
            }
            if (ParamHandler.CACHE_ANNOTATION.equals(key.getValue())) {
                this.cacheConfig = annotations.getMapValue(key);
            }
        }
    }

    String getReturnMediaType() {
        return returnMediaType;
    }

    BMap getResponseCacheConfig() {
        return cacheConfig;
    }

    protected String getAbsoluteResourcePath() {
        return (parentService.getBasePath() + getPath()).replaceAll("/+", SINGLE_SLASH);
    }

    // Followings added due to WebSub requirement
    public void setPath(String path) {
        this.path = path;
    }

    public List<Type> getParamTypes() {
        return new ArrayList<>(Arrays.asList(this.balResource.getParameterTypes()));
    }

    public RemoteMethodType getRemoteFunction() {
        return (RemoteMethodType) balResource;
    }
}
