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

import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.StringUtils;
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

import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_BASE_PATH;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * {@code HttpService} This is the http wrapper for the {@code Service} implementation.
 *
 * @since 0.94
 */
public class BaseService implements HttpService {

    private static final Logger log = LoggerFactory.getLogger(BaseService.class);

    protected static final BString BASE_PATH_FIELD = StringUtils.fromString("basePath");
    private static final BString CORS_FIELD = StringUtils.fromString("cors");
    private static final BString VERSIONING_FIELD = StringUtils.fromString("versioning");
    private static final BString HOST_FIELD = StringUtils.fromString("host");
    private static final BString MEDIA_TYPE_SUBTYPE_PREFIX = StringUtils.fromString("mediaTypeSubtypePrefix");
    private static final BString TREAT_NILABLE_AS_OPTIONAL = StringUtils.fromString("treatNilableAsOptional");

    private BObject balService;
    private List<BaseResource> resources;
    private List<String> allAllowedMethods;
    private String basePath;
    private CorsHeaders corsHeaders;
    private URITemplate<BaseResource, HttpCarbonMessage> uriTemplate;
    private boolean keepAlive = true; //default behavior
    private BMap<BString, Object> compression;
    private String hostName;
    private String chunkingConfig;
    private String mediaTypeSubtypePrefix;
    private String introspectionResourcePath;
    private boolean treatNilableAsOptional = true;

    protected BaseService(BObject service, String basePath) {
        this.balService = service;
        this.basePath = basePath;
    }

    // Added due to WebSub requirement
    protected BaseService(BObject service) {
        this.balService = service;
    }

    public boolean isKeepAlive() {
        return keepAlive;
    }

    public void setKeepAlive(boolean keepAlive) {
        this.keepAlive = keepAlive;
    }

    private void setCompressionConfig(BMap<BString, Object> compression) {
        this.compression = compression;
    }

    public BMap<BString, Object> getCompressionConfig() {
        return this.compression;
    }

    public void setChunkingConfig(String chunkingConfig) {
        this.chunkingConfig = chunkingConfig;
    }

    public String getChunkingConfig() {
        return chunkingConfig;
    }

    public String getName() {
        return HttpUtil.getServiceName(balService);
    }

    public String getPackage() {
        return balService.getType().getPackage().getName();
    }

    public BObject getBalService() {
        return balService;
    }

    public List<BaseResource> getResources() {
        return resources;
    }

    public void setResources(List<BaseResource> resources) {
        this.resources = resources;
    }

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

    public String getMediaTypeSubtypePrefix() {
        return mediaTypeSubtypePrefix;
    }

    public void setTreatNilableAsOptional(boolean treatNilableAsOptional) {
        this.treatNilableAsOptional = treatNilableAsOptional;
    }

    public boolean isTreatNilableAsOptional() {
        return treatNilableAsOptional;
    }

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

    public URITemplate<BaseResource, HttpCarbonMessage> getUriTemplate() throws URITemplateException {
        if (uriTemplate == null) {
            uriTemplate = new URITemplate<>(new Literal<>(new BaseResourceDataElement(), "/"));
        }
        return uriTemplate;
    }

    public static BaseService buildHttpService(BObject service, String basePath) {
        BaseService baseService = new BaseService(service, basePath);
        BMap serviceConfig = getHttpServiceConfigAnnotation(service);
        if (checkConfigAnnotationAvailability(serviceConfig)) {
            baseService.setCompressionConfig(
                    (BMap<BString, Object>) serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_COMPRESSION));
            baseService.setChunkingConfig(serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_CHUNKING).toString());
            baseService.setCorsHeaders(CorsHeaders.buildCorsHeaders(serviceConfig.getMapValue(CORS_FIELD)));
            baseService.setHostName(serviceConfig.getStringValue(HOST_FIELD).getValue().trim());
            if (serviceConfig.containsKey(MEDIA_TYPE_SUBTYPE_PREFIX)) {
                baseService.setMediaTypeSubtypePrefix(serviceConfig.getStringValue(MEDIA_TYPE_SUBTYPE_PREFIX)
                        .getValue().trim());
            }
            baseService.setTreatNilableAsOptional(serviceConfig.getBooleanValue(TREAT_NILABLE_AS_OPTIONAL));
        } else {
            baseService.setHostName(HttpConstants.DEFAULT_HOST);
        }
        processResources(baseService);
        baseService.setAllAllowedMethods(DispatcherUtil.getAllResourceMethods(baseService));
        return baseService;
    }

    private static void processResources(BaseService baseService) {
        List<BaseResource> baseResources = new ArrayList<>();
        for (MethodType resource : ((ServiceType) baseService.getBalService().getType()).getResourceMethods()) {
            if (!SymbolFlags.isFlagOn(resource.getFlags(), SymbolFlags.RESOURCE)) {
                continue;
            }
            updateResourceTree(baseService, baseResources, BaseResource.buildHttpResource(resource, baseService));
        }

        baseService.getIntrospectionDocName().ifPresent(openApiDocName -> {
            String filePath = "resources/ballerina/http/" + openApiDocName + ".json";
            URL resourceUrl = HttpIntrospectionResource.class.getClassLoader().getResource(filePath);
            if (Objects.nonNull(resourceUrl)) {
                updateResourceTree(baseService, baseResources, new HttpIntrospectionResource(baseService, filePath));
            } else {
                log.debug("OpenAPI specification document does not exist in path: '" + filePath + "'");
            }
        });
        baseService.setResources(baseResources);
    }

    private static void updateResourceTree(BaseService baseService, List<BaseResource> baseResources,
                                           BaseResource baseResource) {
        try {
            baseService.getUriTemplate().parse(baseResource.getPath(), baseResource, new BaseResourceElementFactory());
        } catch (URITemplateException | UnsupportedEncodingException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
        baseResource.setTreatNilableAsOptional(baseService.isTreatNilableAsOptional());
        baseResources.add(baseResource);
    }

    private static BMap getHttpServiceConfigAnnotation(BObject service) {
        return getServiceConfigAnnotation(service, ModuleUtils.getHttpPackageIdentifier(),
                                          HttpConstants.ANN_NAME_HTTP_SERVICE_CONFIG);
    }

    protected static BMap getServiceConfigAnnotation(BObject service, String packagePath,
                                                     String annotationName) {
        String key = packagePath.replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH);
        return (BMap) (service.getType()).getAnnotation(StringUtils.fromString(key + ":" + annotationName));
    }

    public String getIntrospectionResourcePathHeaderValue() {
        return this.introspectionResourcePath;
    }

    protected void setIntrospectionResourcePathHeaderValue(String introspectionResourcePath) {
        this.introspectionResourcePath = introspectionResourcePath;
    }

    protected Optional<String> getIntrospectionDocName() {
        ObjectType objType = this.balService.getType();
        if (Objects.nonNull(objType)) {
            return objType.getAnnotations().entrySet().stream()
                    .filter(e -> e.getKey().toString().contains(HttpConstants.ANN_NAME_HTTP_INTROSPECTION_DOC_CONFIG))
                    .findFirst()
                    .map(Map.Entry::getValue)
                    .filter(e -> e instanceof BMap)
                    .map(e -> ((BMap) e).getStringValue(HttpConstants.ANN_FIELD_DOC_NAME).getValue().trim());
        }
        return Optional.empty();
    }
}
