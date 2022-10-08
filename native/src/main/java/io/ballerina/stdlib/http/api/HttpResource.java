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

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
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
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_RESOURCE_CONFIG;
import static io.ballerina.stdlib.http.api.HttpConstants.LINK;
import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;
import static io.ballerina.stdlib.http.api.HttpUtil.getParameterTypes;

/**
 * {@code HttpResource} This is the http wrapper for the {@code Resource} implementation.
 *
 * @since 0.94
 */
public class HttpResource implements Resource {

    private static final Logger log = LoggerFactory.getLogger(HttpResource.class);

    private static final BString NAME = StringUtils.fromString("name");
    private static final BString LINKED_TO = StringUtils.fromString("linkedTo");
    private static final BString RELATION = StringUtils.fromString("relation");
    private static final BString METHOD = StringUtils.fromString("method");
    private static final BString CONSUMES_FIELD = StringUtils.fromString("consumes");
    private static final BString PRODUCES_FIELD = StringUtils.fromString("produces");
    private static final BString CORS_FIELD = StringUtils.fromString("cors");
    private static final BString TRANSACTION_INFECTABLE_FIELD = StringUtils.fromString("transactionInfectable");
    private static final BString HTTP_RESOURCE_CONFIG =
            StringUtils.fromString(ModuleUtils.getHttpPackageIdentifier() + ":" + ANN_NAME_RESOURCE_CONFIG);
    private static final String RETURN_ANNOT_PREFIX = "$returns$";
    private static final MapType LINK_MAP_TYPE = TypeCreator.createMapType(TypeCreator.createRecordType(
            LINK, ModuleUtils.getHttpPackage(), 0, false, 0));

    private String resourceLinkName;
    private List<LinkedResourceInfo> linkedResources = new ArrayList<>();
    private BMap<BString, Object> links = ValueCreator.createMapValue(LINK_MAP_TYPE);
    private List<BString> linkedRelations = new ArrayList<>();
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
    private boolean constraintValidation;

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

    public String getResourceLinkName() {
        return resourceLinkName;
    }

    public void setResourceLinkName(String name) {
        this.resourceLinkName = name;
    }

    public List<LinkedResourceInfo> getLinkedResources() {
        return linkedResources;
    }

    public void addLinkedResource(LinkedResourceInfo linkedResourceInfo) {
        this.linkedResources.add(linkedResourceInfo);
    }

    public void addLink(BString relation, BMap link) {
        this.links.put(relation, link);
    }

    public BMap<BString, Object> getLinks() {
        return this.links;
    }

    public boolean hasLinkedRelation(BString relation) {
        return this.linkedRelations.contains(relation);
    }

    public void addLinkedRelation(BString relation) {
        this.linkedRelations.add(relation);
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

    private void populateResourcePath() {
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
            if (Objects.nonNull(resourceConfigAnnotation.getStringValue(NAME))) {
                httpResource.setResourceLinkName(resourceConfigAnnotation.getStringValue(NAME).getValue());
            }
            if (Objects.nonNull(resourceConfigAnnotation.getArrayValue(LINKED_TO))) {
                httpResource.updateLinkedResources(resourceConfigAnnotation.getArrayValue(LINKED_TO).getValues());
            }
            httpResource.setConsumes(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(CONSUMES_FIELD).getStringArray()));
            httpResource.setProduces(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(PRODUCES_FIELD).getStringArray()));
            httpResource.setCorsHeaders(CorsHeaders.buildCorsHeaders(resourceConfigAnnotation.getMapValue(CORS_FIELD)));
            httpResource
                    .setTransactionInfectable(resourceConfigAnnotation.getBooleanValue(TRANSACTION_INFECTABLE_FIELD));
        }
        processResourceCors(httpResource, httpService);
        httpResource.setConstraintValidation(httpService.getConstraintValidation());
        httpResource.prepareAndValidateSignatureParams();
        return httpResource;
    }

    private void setConstraintValidation(boolean constraintValidation) {
        this.constraintValidation = constraintValidation;
    }

    private boolean getConstraintValidation() {
        return this.constraintValidation;
    }

    private void updateLinkedResources(Object[] links) {
        for (Object link : links) {
            BMap linkMap = (BMap) link;
            String name = linkMap.getStringValue(NAME).getValue().toLowerCase(Locale.getDefault());
            String relation = linkMap.getStringValue(RELATION).getValue().toLowerCase(Locale.getDefault());
            String method = Objects.nonNull(linkMap.getStringValue(METHOD)) ?
                            linkMap.getStringValue(METHOD).getValue().toUpperCase(Locale.getDefault()) : null;
            this.addLinkedResource(new LinkedResourceInfo(name, relation, method));
        }
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
        paramHandler = new ParamHandler(getBalResource(), this.pathParamCount, this.getConstraintValidation());
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

    public String getResourcePathSignature() {
        return this.getName().replaceFirst("\\$[^$]*", "");
    }

    // Followings added due to WebSub requirement
    public void setPath(String path) {
        this.path = path;
    }

    public List<Type> getParamTypes() {
        return new ArrayList<>(Arrays.asList(getParameterTypes(this.balResource)));
    }

    public RemoteMethodType getRemoteFunction() {
        return (RemoteMethodType) balResource;
    }

    /**
     * Linked resource information.
     */
    public static class LinkedResourceInfo {
        private final String name;
        private final String relationship;
        private final String method;

        public LinkedResourceInfo(String name, String relationship, String method) {
            this.name = name;
            this.relationship = relationship;
            this.method = method;
        }

        public String getName() {
            return name;
        }

        public String getRelationship() {
            return relationship;
        }

        public String getMethod() {
            return method;
        }
    }
}
