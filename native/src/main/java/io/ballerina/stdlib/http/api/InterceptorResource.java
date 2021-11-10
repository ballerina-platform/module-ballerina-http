package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

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
public class InterceptorResource implements HttpResource {

    private static final Logger log = LoggerFactory.getLogger(InterceptorResource.class);

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
            this.populateResourcePath();
            this.validateAndPopulateMethod();
            this.validateReturnType();
        }
    }

    public String getName() {
        return balResource.getName();
    }

    public ParamHandler getParamHandler() {
        return paramHandler;
    }

    public InterceptorService getParentService() {
        return parentService;
    }

    public ResourceMethodType getBalResource() {
        return (ResourceMethodType) balResource;
    }

    public List<String> getMethods() {
        return methods;
    }

    private void validateAndPopulateMethod() {
        String accessor = getBalResource().getAccessor();
        if (HttpConstants.DEFAULT_HTTP_METHOD.equals(accessor.toLowerCase(Locale.getDefault()))) {
            // TODO: Fix this properly
            // setting method as null means that no specific method. Resource is exposed for any method match
            this.methods = null;
        } else {
            if (this.getResourceType().equals(HttpConstants.HTTP_REQUEST_ERROR_INTERCEPTOR)) {
                throw new BallerinaConnectorException("HTTP interceptor resources are allowed to have only default " +
                        "method");
            } else {
                this.methods = Collections.singletonList(accessor.toUpperCase(Locale.getDefault()));
            }
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

    public String getWildcardToken() {
        return wildcardToken;
    }

    private void validateReturnType() {
        Type returnType = getBalResource().getReturnType();
        log.info(returnType.toString());
    }
}
