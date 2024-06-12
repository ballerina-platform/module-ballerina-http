package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.AnnotatableType;
import io.ballerina.runtime.api.types.ReferenceType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.uri.DispatcherUtil;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

public class HttpServiceFromContract extends HttpService {

    private ReferenceType serviceContractType;

    protected HttpServiceFromContract(BObject service, String basePath, ReferenceType httpServiceContractType) {
        super(service, basePath);
        this.serviceContractType = httpServiceContractType;
    }

    public static HttpService buildHttpService(BObject service, String basePath,
                                               ReferenceType serviceContractType) {
        HttpService httpService = new HttpServiceFromContract(service, basePath, serviceContractType);
        BMap serviceConfig = getHttpServiceConfigAnnotation(serviceContractType);
        if (checkConfigAnnotationAvailability(serviceConfig)) {
            httpService.setCompressionConfig(
                    (BMap<BString, Object>) serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_COMPRESSION));
            httpService.setChunkingConfig(serviceConfig.get(HttpConstants.ANN_CONFIG_ATTR_CHUNKING).toString());
            httpService.setCorsHeaders(CorsHeaders.buildCorsHeaders(serviceConfig.getMapValue(CORS_FIELD)));
            httpService.setHostName(serviceConfig.getStringValue(HOST_FIELD).getValue().trim());
            httpService.setIntrospectionPayload(serviceConfig.getArrayValue(OPENAPI_DEF_FIELD).getByteArray());
            if (serviceConfig.containsKey(MEDIA_TYPE_SUBTYPE_PREFIX)) {
                httpService.setMediaTypeSubtypePrefix(serviceConfig.getStringValue(MEDIA_TYPE_SUBTYPE_PREFIX)
                        .getValue().trim());
            }
            httpService.setTreatNilableAsOptional(serviceConfig.getBooleanValue(TREAT_NILABLE_AS_OPTIONAL));
            httpService.setConstraintValidation(serviceConfig.getBooleanValue(DATA_VALIDATION));
        } else {
            httpService.setHostName(HttpConstants.DEFAULT_HOST);
        }
        processResources(httpService);
        httpService.setAllAllowedMethods(DispatcherUtil.getAllResourceMethods(httpService));
        return httpService;
    }

    public static BMap getHttpServiceConfigAnnotation(ReferenceType serviceContractType) {
        String packagePath = ModuleUtils.getHttpPackageIdentifier();
        String annotationName = HttpConstants.ANN_NAME_HTTP_SERVICE_CONFIG;
        String key = packagePath.replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH);
        if (!(serviceContractType instanceof AnnotatableType annotatableServiceContractType)) {
            return null;
        }
        return (BMap) annotatableServiceContractType.getAnnotation(fromString(key + ":" + annotationName));
    }

    @Override
    protected ResourceMethodType[] getResourceMethods() {
        return ((ServiceType) TypeUtils.getReferredType(serviceContractType)).getResourceMethods();
    }
}
