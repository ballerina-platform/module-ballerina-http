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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.URITemplate;
import io.ballerina.stdlib.http.uri.URITemplateException;
import io.ballerina.stdlib.http.uri.parser.Literal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerina.stdlib.http.api.HttpConstants.CREATE_INTERCEPTORS_FUNCTION_NAME;
import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_BASE_PATH;
import static io.ballerina.stdlib.http.api.HttpConstants.INTERCEPTABLE_SERVICE;
import static io.ballerina.stdlib.http.api.HttpErrorType.GENERIC_LISTENER_ERROR;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;
import static io.ballerina.stdlib.http.api.HttpUtil.getMediaTypeWithPrefix;

/**
 * {@code HttpService} This is the http wrapper for the {@code Service} implementation.
 *
 * @since 0.94
 */
public class HttpService implements Service {

    private static final Logger log = LoggerFactory.getLogger(HttpService.class);

    private static final BString CORS_FIELD = fromString("cors");
    private static final BString HOST_FIELD = fromString("host");
    private static final BString OPENAPI_DEF_FIELD = fromString("openApiDefinition");
    private static final BString MEDIA_TYPE_SUBTYPE_PREFIX = fromString("mediaTypeSubtypePrefix");
    private static final BString TREAT_NILABLE_AS_OPTIONAL = fromString("treatNilableAsOptional");
    private static final BString DATA_VALIDATION = fromString("validation");

    private BObject balService;
    private List<HttpResource> resources;
    private List<String> allAllowedMethods;
    private String basePath;
    private CorsHeaders corsHeaders;
    private URITemplate<Resource, HttpCarbonMessage> uriTemplate;
    private boolean keepAlive = true; //default behavior
    private BMap<BString, Object> compression;
    private String hostName;
    private String chunkingConfig;
    private String mediaTypeSubtypePrefix;
    private List<String> oasResourceLinks = new ArrayList<>();
    private boolean treatNilableAsOptional = true;
    private List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries;
    private BArray balInterceptorServicesArray;
    private byte[] introspectionPayload = new byte[0];
    private Boolean constraintValidation = true;

    protected HttpService(BObject service, String basePath) {
        this.balService = service;
        this.basePath = basePath;
    }

    // Added due to WebSub requirement
    protected HttpService(BObject service) {
        this.balService = service;
    }

    public boolean isKeepAlive() {
        return keepAlive;
    }

    public void setKeepAlive(boolean keepAlive) {
        this.keepAlive = keepAlive;
    }

    protected void setCompressionConfig(BMap<BString, Object> compression) {
        this.compression = compression;
    }

    @Override
    public BMap<BString, Object> getCompressionConfig() {
        return this.compression;
    }

    public void setChunkingConfig(String chunkingConfig) {
        this.chunkingConfig = chunkingConfig;
    }

    @Override
    public String getChunkingConfig() {
        return chunkingConfig;
    }

    public String getName() {
        return HttpUtil.getServiceName(balService);
    }

    public String getPackage() {
        return TypeUtils.getType(balService).getPackage().getName();
    }

    public BObject getBalService() {
        return balService;
    }

    public List<HttpResource> getResources() {
        return resources;
    }

    public void setResources(List<HttpResource> resources) {
        this.resources = resources;
    }

    @Override
    public List<String> getAllAllowedMethods() {
        return allAllowedMethods;
    }

    public void setAllAllowedMethods(List<String> allAllowMethods) {
        this.allAllowedMethods = allAllowMethods;
    }

    public void setHostName(String hostName) {
        this.hostName = hostName;
    }

    public String getHostName() {
        return hostName;
    }

    public void setMediaTypeSubtypePrefix(String mediaTypeSubtypePrefix) {
        this.mediaTypeSubtypePrefix = mediaTypeSubtypePrefix;
    }

    @Override
    public String getMediaTypeSubtypePrefix() {
        return mediaTypeSubtypePrefix;
    }

    public void setTreatNilableAsOptional(boolean treatNilableAsOptional) {
        this.treatNilableAsOptional = treatNilableAsOptional;
    }

    public boolean isTreatNilableAsOptional() {
        return treatNilableAsOptional;
    }

    @Override
    public String getBasePath() {
        return basePath;
    }

    // Added due to WebSub requirement
    public void setBasePath(String basePath) {
        if (basePath == null || basePath.trim().isEmpty()) {
            String serviceName = this.getName();
            this.basePath = DEFAULT_BASE_PATH.concat(serviceName.startsWith(HttpConstants.DOLLAR) ? "" : serviceName);
        } else {
            this.basePath = HttpUtil.sanitizeBasePath(basePath);
        }
    }

    public CorsHeaders getCorsHeaders() {
        return corsHeaders;
    }

    public void setCorsHeaders(CorsHeaders corsHeaders) {
        this.corsHeaders = corsHeaders;
        if (this.corsHeaders == null || !this.corsHeaders.isAvailable()) {
            return;
        }
        if (this.corsHeaders.getAllowOrigins() == null) {
            this.corsHeaders.setAllowOrigins(Stream.of("*").collect(Collectors.toList()));
        }
        if (this.corsHeaders.getAllowMethods() == null) {
            this.corsHeaders.setAllowMethods(Stream.of("*").collect(Collectors.toList()));
        }
    }

    public void setIntrospectionPayload(byte[] introspectionPayload) {
        if (this.introspectionPayload.length == 0) {
            this.introspectionPayload = introspectionPayload.clone();
        }
    }

    public byte[] getIntrospectionPayload() {
        return this.introspectionPayload.clone();
    }

    @Override
    public URITemplate<Resource, HttpCarbonMessage> getUriTemplate() throws URITemplateException {
        if (uriTemplate == null) {
            uriTemplate = new URITemplate<>(new Literal<>(new ResourceDataElement(), "/"));
        }
        return uriTemplate;
    }

    public static HttpService buildHttpService(BObject service, String basePath) {
        HttpService httpService = new HttpService(service, basePath);
        BMap serviceConfig = getHttpServiceConfigAnnotation(service);
        httpService.populateIntrospectionPayload();
        httpService.populateServiceConfig(serviceConfig);
        return httpService;
    }

    protected void populateServiceConfig(BMap serviceConfig) {
        if (checkConfigAnnotationAvailability(serviceConfig)) {
            this.setCompressionConfig(
                    (BMap<BString, Object>) serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_COMPRESSION));
            this.setChunkingConfig(serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_CHUNKING).toString());
            this.setCorsHeaders(CorsHeaders.buildCorsHeaders(serviceConfig.getMapValue(CORS_FIELD)));
            this.setHostName(serviceConfig.getStringValue(HOST_FIELD).getValue().trim());
            // TODO: Remove once the field is removed from the annotation
            this.setIntrospectionPayload(serviceConfig.getArrayValue(OPENAPI_DEF_FIELD).getByteArray());
            if (serviceConfig.containsKey(MEDIA_TYPE_SUBTYPE_PREFIX)) {
                this.setMediaTypeSubtypePrefix(serviceConfig.getStringValue(MEDIA_TYPE_SUBTYPE_PREFIX)
                        .getValue().trim());
            }
            this.setTreatNilableAsOptional(serviceConfig.getBooleanValue(TREAT_NILABLE_AS_OPTIONAL));
            this.setConstraintValidation(serviceConfig.getBooleanValue(DATA_VALIDATION));
        } else {
            this.setHostName(HttpConstants.DEFAULT_HOST);
        }
        processResources(this);
        this.setAllAllowedMethods(DispatcherUtil.getAllResourceMethods(this));
    }

    protected static void processResources(HttpService httpService) {
        List<HttpResource> httpResources = new ArrayList<>();
        for (MethodType resource : httpService.getResourceMethods()) {
            if (!SymbolFlags.isFlagOn(resource.getFlags(), SymbolFlags.RESOURCE)) {
                continue;
            }
            updateResourceTree(httpService, httpResources, HttpResource.buildHttpResource(resource, httpService));
        }

        byte[] introspectionPayload = httpService.getIntrospectionPayload();
        if (introspectionPayload.length > 0) {
            updateResourceTree(httpService, httpResources, new HttpIntrospectionResource(httpService,
                                                                                         introspectionPayload));
            updateResourceTree(
                    httpService, httpResources, new HttpSwaggerUiResource(httpService, introspectionPayload));
        } else {
            log.debug("OpenAPI definition is not available");
        }
        processLinks(httpService, httpResources);
        httpService.setResources(httpResources);
    }

    protected ResourceMethodType[] getResourceMethods() {
        return ((ServiceType) TypeUtils.getType(balService)).getResourceMethods();
    }

    private static void processLinks(HttpService httpService, List<HttpResource> httpResources) {
        for (HttpResource targetResource : httpResources) {
            for (HttpResource.LinkedResourceInfo link : targetResource.getLinkedResources()) {
                HttpResource linkedResource = null;
                for (HttpResource resource : httpResources) {
                    linkedResource = getLinkedResource(link, linkedResource, resource);
                }
                if (Objects.nonNull(linkedResource)) {
                    setLinkToResource(httpService, targetResource, link, linkedResource);
                } else {
                    String msg = "cannot find" + (link.getMethod() != null ? " " + link.getMethod()  : "") +
                                 " resource with resource link name: '" + link.getName() + "'";
                    throw HttpUtil.createHttpError("resource link generation failed: " + msg, GENERIC_LISTENER_ERROR);
                }
            }
        }
    }

    private static HttpResource getLinkedResource(HttpResource.LinkedResourceInfo link, HttpResource linkedResource,
                                                  HttpResource resource) {
        if (Objects.nonNull(resource.getResourceLinkName()) &&
                resource.getResourceLinkName().equalsIgnoreCase(link.getName())) {
            if (Objects.nonNull(link.getMethod())) {
                if (Objects.isNull(resource.getMethods())) {
                    if (Objects.isNull(linkedResource)) {
                        linkedResource = resource;
                    }
                } else if (resource.getMethods().contains(link.getMethod())) {
                    linkedResource = resource;
                }
            } else {
                if (Objects.isNull(linkedResource)) {
                    linkedResource = resource;
                } else {
                    throw HttpUtil.createHttpError("resource link generation failed: cannot resolve resource link " +
                                                   "name: '" + link.getName() + "' since multiple occurrences found",
                                                    GENERIC_LISTENER_ERROR);
                }
            }
        }
        return linkedResource;
    }

    private static void validateResourceName(HttpResource targetResource, List<HttpResource> resources) {
        if (Objects.isNull(targetResource.getResourceLinkName())) {
            return;
        }
        for (HttpResource resource : resources) {
            if (Objects.isNull(resource.getResourceLinkName())) {
                continue;
            }
            if (targetResource.getResourceLinkName().equalsIgnoreCase(resource.getResourceLinkName()) &&
                    !targetResource.getResourcePathSignature().equals(resource.getResourcePathSignature())) {
                throw HttpUtil.createHttpError("resource link generation failed: cannot duplicate resource link name:" +
                                               " '" + targetResource.getResourceLinkName() + "' unless they have the " +
                                               "same path", GENERIC_LISTENER_ERROR);
            }
        }
    }

    private static void setLinkToResource(HttpService httpService, HttpResource targetResource,
                                          HttpResource.LinkedResourceInfo link, HttpResource linkedResource) {
        BMap<BString, Object> linkMap = ValueCreatorUtils.createHTTPRecordValue(HttpConstants.LINK);
        BString relation = fromString(link.getRelationship());
        if (targetResource.hasLinkedRelation(relation)) {
            throw HttpUtil.createHttpError("resource link generation failed: cannot duplicate resource link relation:" +
                                           " '" + relation.getValue() + "'", GENERIC_LISTENER_ERROR);
        }
        targetResource.addLinkedRelation(relation);
        BString href = fromString(linkedResource.getAbsoluteResourcePath());
        linkMap.put(HttpConstants.LINK_HREF, href);
        BArray methods = getMethodsBArray(linkedResource.getMethods());
        linkMap.put(HttpConstants.LINK_METHODS, methods);
        Set<String> returnMediaTypes = linkedResource.getLinkReturnMediaTypes();
        BArray types = ValueCreator.createArrayValue(TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
        for (String returnMediaType : returnMediaTypes) {
            if (Objects.nonNull(returnMediaType)) {
                if (Objects.nonNull(httpService.getMediaTypeSubtypePrefix())) {
                    String specificReturnMediaType = getMediaTypeWithPrefix(httpService.getMediaTypeSubtypePrefix(),
                                                                            returnMediaType);
                    if (Objects.nonNull(specificReturnMediaType)) {
                        returnMediaType = specificReturnMediaType;
                    }
                }
                types.append(fromString(returnMediaType));
            }
        }
        if (!types.isEmpty()) {
            linkMap.put(HttpConstants.LINK_TYPES, types);
        }
        targetResource.addLink(relation, linkMap);
    }

    private static BArray getMethodsBArray(List<String> methods) {
        if (Objects.isNull(methods)) {
            methods = Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD");
        }
        List<BString> methodsAsBString = methods.stream().map(StringUtils::fromString).collect(Collectors.toList());
        return ValueCreator.createArrayValue(methodsAsBString.toArray(BString[]::new));
    }

    private static void updateResourceTree(HttpService httpService, List<HttpResource> httpResources,
                                           HttpResource httpResource) {
        try {
            httpService.getUriTemplate().parse(httpResource.getPath(), httpResource, new ResourceElementFactory());
        } catch (URITemplateException | UnsupportedEncodingException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
        httpResource.setTreatNilableAsOptional(httpService.isTreatNilableAsOptional());
        validateResourceName(httpResource, httpResources);
        httpResources.add(httpResource);
    }

    public static BMap getHttpServiceConfigAnnotation(BObject service) {
        return getServiceConfigAnnotation(service, ModuleUtils.getHttpPackageIdentifier(),
                                          HttpConstants.ANN_NAME_HTTP_SERVICE_CONFIG);
    }

    protected static BMap getServiceConfigAnnotation(BObject service, String packagePath,
                                                     String annotationName) {
        String key = packagePath.replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH);
        return (BMap) ((ObjectType) TypeUtils.getReferredType(TypeUtils.getType(service))).getAnnotation(
                fromString(key + ":" + annotationName));
    }

    private static Optional<String> getOpenApiDocFileName(BObject service) {
        BMap openApiDocMap = (BMap) ((ObjectType) TypeUtils.getReferredType(TypeUtils.getType(service))).getAnnotation(
                fromString("ballerina/lang.annotations:0:IntrospectionDocConfig"));
        if (Objects.isNull(openApiDocMap)) {
            return Optional.empty();
        }
        BString name = openApiDocMap.getStringValue(fromString("name"));
        return Objects.isNull(name) ? Optional.empty() : Optional.of(name.getValue());
    }

    protected void populateIntrospectionPayload() {
        Optional<String> openApiFileNameOpt = getOpenApiDocFileName(balService);
        if (openApiFileNameOpt.isEmpty()) {
            return;
        }
        // Load from resources
        String openApiFileName = openApiFileNameOpt.get();
        String openApiDocPath = String.format("resources/openapi_%s.json",
                openApiFileName.startsWith("-") ? "0" + openApiFileName.substring(1) : openApiFileName);
        try (InputStream is = HttpService.class.getClassLoader().getResourceAsStream(openApiDocPath)) {
            if (Objects.isNull(is)) {
                log.debug("OpenAPI definition is not available in the resources");
                return;
            }
            this.setIntrospectionPayload(is.readAllBytes());
        } catch (IOException e) {
            log.debug("Error while loading OpenAPI definition from resources", e);
        }
    }

    @Override
    public String getOasResourceLink() {
        if (this.oasResourceLinks.isEmpty()) {
            return null;
        }
        return String.join(", ", this.oasResourceLinks);
    }

    protected void addOasResourceLink(String oasResourcePath) {
        this.oasResourceLinks.add(oasResourcePath);
    }

    public void setInterceptorServicesRegistries(List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries) {
        this.interceptorServicesRegistries = interceptorServicesRegistries;
    }

    public List<HTTPInterceptorServicesRegistry> getInterceptorServicesRegistries() {
        return this.interceptorServicesRegistries;
    }

    public void setBalInterceptorServicesArray(BArray interceptorServicesArray) {
        this.balInterceptorServicesArray = interceptorServicesArray;
    }

    public BArray getBalInterceptorServicesArray() {
        return this.balInterceptorServicesArray;
    }

    public static void populateInterceptorServicesRegistries(List<HTTPInterceptorServicesRegistry>
                listenerLevelInterceptors, BArray interceptorsArrayFromListener, HttpService service, Runtime runtime) {
        List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries = new ArrayList<>();
        for (HTTPInterceptorServicesRegistry servicesRegistry : listenerLevelInterceptors) {
            interceptorServicesRegistries.add(servicesRegistry);
        }

        ServiceType balServiceType = (ServiceType) service.getBalService().getOriginalType();
        boolean includesInterceptableService = balServiceType.getTypeIdSet().getIds().stream()
                .anyMatch(typeId -> typeId.getName().equals(INTERCEPTABLE_SERVICE));
        BArray interceptorsArrayFromService;
        if (includesInterceptableService) {
            final Object[] createdInterceptors = new Object[1];
            CountDownLatch latch = new CountDownLatch(1);
            Object result = runtime.call(service.getBalService(), CREATE_INTERCEPTORS_FUNCTION_NAME);
            try {
                latch.await();
            } catch (InterruptedException exception) {
                log.warn("Interrupted before getting the return type");
            }
            if (result instanceof BError error) {
                error.printStackTrace();
                System.exit(1);
            }
            createdInterceptors[0] = result;
            latch.countDown();;

            if (Objects.isNull(createdInterceptors[0]) || (createdInterceptors[0] instanceof BArray &&
                    ((BArray) createdInterceptors[0]).size() == 0)) {
                service.setInterceptorServicesRegistries(interceptorServicesRegistries);
                service.setBalInterceptorServicesArray(interceptorsArrayFromListener);
                return;
            } else if (createdInterceptors[0] instanceof BArray) {
                interceptorsArrayFromService = (BArray) createdInterceptors[0];
            } else {
                interceptorsArrayFromService = ValueCreator.createArrayValue(createdInterceptors,
                        TypeCreator.createArrayType(((BObject) createdInterceptors[0]).getOriginalType()));
            }
        } else {
            service.setInterceptorServicesRegistries(interceptorServicesRegistries);
            service.setBalInterceptorServicesArray(interceptorsArrayFromListener);
            return;
        }

        Object[] interceptors = interceptorsArrayFromService.getValues();
        List<Object> interceptorServices = new ArrayList<>();
        for (Object interceptor: interceptors) {
            if (Objects.isNull(interceptor)) {
                break;
            }
            interceptorServices.add(interceptor);
        }

        // Registering all the interceptor services in separate service registries
        for (int i = 0; i < interceptorServices.size(); i++) {
            BObject interceptorService = (BObject) interceptorServices.get(i);
            HTTPInterceptorServicesRegistry servicesRegistry = new HTTPInterceptorServicesRegistry();
            servicesRegistry.setServicesType(HttpUtil.getInterceptorServiceType(interceptorService));
            servicesRegistry.registerInterceptorService(interceptorService, service.getBasePath(), false);
            servicesRegistry.setRuntime(runtime);
            interceptorServicesRegistries.add(servicesRegistry);
        }

        service.setInterceptorServicesRegistries(interceptorServicesRegistries);
        populateBalInterceptorServicesArray(service, interceptorsArrayFromListener, interceptorsArrayFromService);
    }

    private static void populateBalInterceptorServicesArray(HttpService service, BArray fromListener,
                                                            BArray fromService) {
        if (Objects.isNull(fromListener)) {
            service.setBalInterceptorServicesArray(fromService);
        } else {
            BArray interceptorsArray = ValueCreator.createArrayValue((ArrayType) fromListener.getType());
            for (Object interceptor : fromListener.getValues()) {
                if (Objects.isNull(interceptor)) {
                    break;
                }
                interceptorsArray.append(interceptor);
            }
            for (Object interceptor : fromService.getValues()) {
                if (Objects.isNull(interceptor)) {
                    break;
                }
                interceptorsArray.append(interceptor);
            }
            service.setBalInterceptorServicesArray(interceptorsArray);
        }
    }

    public boolean hasInterceptors() {
        return Objects.nonNull(this.getInterceptorServicesRegistries()) &&
                !this.getInterceptorServicesRegistries().isEmpty();
    }

    public boolean getConstraintValidation() {
        return constraintValidation;
    }

    protected void setConstraintValidation(boolean constraintValidation) {
        this.constraintValidation = constraintValidation;
    }
}
