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
package org.ballerinalang.net.http;

import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.transactions.TransactionConstants;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.ballerinalang.net.http.HttpConstants.ANN_NAME_RESOURCE_CONFIG;
import static org.ballerinalang.net.http.HttpConstants.PROTOCOL_PACKAGE_HTTP;
import static org.ballerinalang.net.http.HttpUtil.checkConfigAnnotationAvailability;

/**
 * {@code HttpResource} This is the http wrapper for the {@code Resource} implementation.
 *
 * @since 0.94
 */
public class HttpResource {

    private static final Logger log = LoggerFactory.getLogger(HttpResource.class);

    private static final BString METHODS_FIELD = StringUtils.fromString("methods");
    private static final BString PATH_FIELD = StringUtils.fromString("path");
    private static final BString BODY_FIELD = StringUtils.fromString("body");
    private static final BString CONSUMES_FIELD = StringUtils.fromString("consumes");
    private static final BString PRODUCES_FIELD = StringUtils.fromString("produces");
    private static final BString CORS_FIELD = StringUtils.fromString("cors");
    private static final BString TRANSACTION_INFECTABLE_FIELD = StringUtils.fromString("transactionInfectable");
    private static final BString HTTP_RESOURCE_CONFIG =
            StringUtils.fromString(PROTOCOL_PACKAGE_HTTP + ":" + ANN_NAME_RESOURCE_CONFIG);
//    private static final BString HTTP_PARAM_ORDER_CONFIG =
//            StringUtils.fromString(PROTOCOL_PACKAGE_HTTP + ":" + ANN_NAME_PARAM_ORDER_CONFIG);
    private static final List<String> ALL_STANDARD_ACCESSORS =
            Arrays.asList(HttpConstants.HTTP_METHOD_GET, HttpConstants.HTTP_METHOD_HEAD,
                          HttpConstants.HTTP_METHOD_PATCH, HttpConstants.HTTP_METHOD_OPTIONS,
                          HttpConstants.HTTP_METHOD_POST, HttpConstants.HTTP_METHOD_DELETE,
                          HttpConstants.HTTP_METHOD_PUT);

    private ResourceFunctionType balResource;
    private List<String> methods;
    private String path;
    private String entityBodyAttribute;
    private List<String> consumes;
    private List<String> produces;
    private List<String> producesSubTypes;
    private CorsHeaders corsHeaders;
    private SignatureParams signatureParams;
    private HttpService parentService;
    private boolean transactionInfectable = true; //default behavior
    private boolean transactionAnnotated = false;
    private String wildcardToken;
    private int pathParamCount;

    protected HttpResource(ResourceFunctionType resource, HttpService parentService) {
        this.balResource = resource;
        this.parentService = parentService;
        this.producesSubTypes = new ArrayList<>();
        this.populateResourcePath();
        this.populateMethod();
    }

    public boolean isTransactionAnnotated() {
        return transactionAnnotated;
    }

    public String getName() {
        return balResource.getName();
    }

    public String getServiceName() {
        return balResource.getParentObjectType().getName();
    }

    public SignatureParams getSignatureParams() {
        return signatureParams;
    }

    public HttpService getParentService() {
        return parentService;
    }

    public ResourceFunctionType getBalResource() {
        return balResource;
    }

    public List<String> getMethods() {
        return methods;
    }

    public void populateMethod() {
        String accessor = balResource.getAccessor();
        if (HttpConstants.DEFAULT_HTTP_METHOD.equals(accessor.toLowerCase(Locale.getDefault()))) {
            this.methods = ALL_STANDARD_ACCESSORS;
        } else {
            this.methods = Collections.singletonList(accessor.toUpperCase(Locale.getDefault()));
        }
    }

    public String getPath() {
        return path;
    }

    private void populateResourcePath() {
        String[] paths = balResource.getResourcePath();
        StringBuilder resourcePath = new StringBuilder();
        int count = 0;
        for (String segment : paths) {
            resourcePath.append(HttpConstants.SINGLE_SLASH);
            if (HttpConstants.STAR_IDENTIFIER.equals(segment)) {
                String pathSegment = balResource.getParamNames()[count++];
                resourcePath.append(HttpConstants.OPEN_CURL_IDENTIFIER)
                        .append(pathSegment).append(HttpConstants.CLOSE_CURL_IDENTIFIER);
            } else if (HttpConstants.DOUBLE_STAR_IDENTIFIER.equals(segment)) {
                this.wildcardToken = balResource.getParamNames()[count++];
                resourcePath.append(HttpConstants.STAR_IDENTIFIER);
            } else if (HttpConstants.DOT_IDENTIFIER.equals(segment)) {
                // default set as "/"
                break;
            } else {
                resourcePath.append(segment);
            }
        }
        this.path = resourcePath.toString().replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH);
        this.pathParamCount = count;
    }

    public List<String> getConsumes() {
        return consumes;
    }

    public void setConsumes(List<String> consumes) {
        this.consumes = consumes;
    }

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

    public List<String> getProducesSubTypes() {
        return producesSubTypes;
    }

    public void setProducesSubTypes(List<String> producesSubTypes) {
        this.producesSubTypes = producesSubTypes;
    }

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

    public String getEntityBodyAttributeValue() {
        return entityBodyAttribute;
    }

    public void setEntityBodyAttributeValue(String entityBodyAttribute) {
        this.entityBodyAttribute = entityBodyAttribute;
    }

    public static HttpResource buildHttpResource(ResourceFunctionType resource, HttpService httpService) {
        HttpResource httpResource = new HttpResource(resource, httpService);
        BMap resourceConfigAnnotation = getResourceConfigAnnotation(resource);

        setupTransactionAnnotations(resource, httpResource);
        if (checkConfigAnnotationAvailability(resourceConfigAnnotation)) {
//            httpResource.setPath(resourceConfigAnnotation.getStringValue(PATH_FIELD).getValue().replaceAll(
//                    HttpConstants.REGEX, HttpConstants.SINGLE_SLASH));
//            httpResource.setMethods(
//                    getAsStringList(resourceConfigAnnotation.getArrayValue(METHODS_FIELD).getStringArray()));
            httpResource.setConsumes(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(CONSUMES_FIELD).getStringArray()));
            httpResource.setProduces(
                    getAsStringList(resourceConfigAnnotation.getArrayValue(PRODUCES_FIELD).getStringArray()));
//            httpResource.setEntityBodyAttributeValue(resourceConfigAnnotation.getStringValue(BODY_FIELD).getValue());
            httpResource.setCorsHeaders(CorsHeaders.buildCorsHeaders(resourceConfigAnnotation.getMapValue(CORS_FIELD)));
            httpResource
                    .setTransactionInfectable(resourceConfigAnnotation.getBooleanValue(TRANSACTION_INFECTABLE_FIELD));

            processResourceCors(httpResource, httpService);
            httpResource.prepareAndValidateSignatureParams();
            return httpResource;
        }

        if (log.isDebugEnabled()) {
            log.debug("resourceConfig not specified in the Resource instance, using default sub path");
        }
//        httpResource.setPath(getResourcePath(((ResourceFunctionType) resource).getResourcePath()));
        httpResource.prepareAndValidateSignatureParams();
        return httpResource;
    }

    private static void setupTransactionAnnotations(ResourceFunctionType resource, HttpResource httpResource) {
        BMap transactionConfigAnnotation = HttpUtil.getTransactionConfigAnnotation(resource,
                        TransactionConstants.TRANSACTION_PACKAGE_PATH);
        if (transactionConfigAnnotation != null) {
            httpResource.transactionAnnotated = true;
        }
    }

    /**
     * Get the `BMap` resource configuration of the given resource.
     *
     * @param resource The resource
     * @return the resource configuration of the given resource
     */
    public static BMap getResourceConfigAnnotation(ResourceFunctionType resource) {
        return (BMap) resource.getAnnotation(HTTP_RESOURCE_CONFIG);
    }

//    protected static BMap getPathParamOrderMap(ResourceFunctionType resource) {
//        Object annotation = resource.getAnnotation(HTTP_PARAM_ORDER_CONFIG);
//        return annotation == null ? ValueCreator.createMapValue() :
//                (BMap<BString, Object>) ((BMap<BString, Object>) annotation).get(ANN_FIELD_PATH_PARAM_ORDER);
//    }
//
//    protected static BArray getAllParamOrderMap(ResourceFunctionType resource) {
//        Object annotation = resource.getAnnotation(HTTP_PARAM_ORDER_CONFIG);
//        return annotation == null ? ValueCreator.createArrayValue(new BString[0]) :
//                (BArray) ((BMap<BString, Object>) annotation).get(ANN_FIELD_ALL_PARAM_ORDER);
//    }

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
        if (!corsHeaders.isAvailable()) {
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

        corsHeaders.setAllowMethods(resource.getMethods());
    }

    private void prepareAndValidateSignatureParams() {
        signatureParams = new SignatureParams(this);
//        signatureParams.validate();
    }

    public List<Type> getParamTypes() {
        List<Type> paramTypes = new ArrayList<>();
        paramTypes.addAll(Arrays.asList(this.balResource.getParameterTypes()));
        return paramTypes;
    }

    public String getWildcardToken() {
        return wildcardToken;
    }

    public int getPathParamCount() {
        return pathParamCount;
    }
}
