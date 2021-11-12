package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.MethodType;
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

import java.io.UnsupportedEncodingException;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * {@code InterceptorService} This is the http wrapper for the {@code InterceptorService} implementation.
 *
 * @since SL Beta 4
 */
public class InterceptorService implements Service {

    private BObject balService;
    private InterceptorResource interceptorResource;
    private List<String> allAllowedMethods;
    private String basePath;
    private URITemplate<Resource, HttpCarbonMessage> uriTemplate;
    private String hostName;
    private String serviceType;

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
    public String getIntrospectionResourcePathHeaderValue() {
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

    public static InterceptorService buildHttpService(BObject service, String basePath, String serviceType) {
        InterceptorService interceptorService = new InterceptorService(service, basePath);
        interceptorService.setServiceType(serviceType);
        BMap serviceConfig = getHttpServiceConfigAnnotation(service);
        if (checkConfigAnnotationAvailability(serviceConfig)) {
            // Redundant since compiler validation does not allow service config annotation for service objects
            throw new BallerinaConnectorException("Service Config annotation is not supported " +
                    "for interceptor services");
        }
        interceptorService.setHostName(HttpConstants.DEFAULT_HOST);
        processInterceptorResource(interceptorService);
        interceptorService.setAllAllowedMethods(DispatcherUtil.getInterceptorResourceMethods(
                interceptorService));
        return interceptorService;
    }

    private static void processInterceptorResource(InterceptorService interceptorService) {
        MethodType[] resourceMethods = ((ServiceType) interceptorService.getBalService().getType())
                .getResourceMethods();
        if (resourceMethods.length == 1) {
            MethodType resource = resourceMethods[0];
            updateInterceptorResourceTree(interceptorService,
                    InterceptorResource.buildInterceptorResource(resource, interceptorService));
        } else {
            throw new BallerinaConnectorException("HTTP interceptor services are allowed to have only " +
                    "one resource method");
        }
    }

    private static void updateInterceptorResourceTree(InterceptorService httpService,
                                                      InterceptorResource httpInterceptorResource) {
        try {
            httpService.getUriTemplate().parse(httpInterceptorResource.getPath(), httpInterceptorResource,
                    new ResourceElementFactory());
        } catch (URITemplateException | UnsupportedEncodingException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
        httpService.setInterceptorResource(httpInterceptorResource);
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
}
