/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.AnnotatableType;
import io.ballerina.runtime.api.types.ReferenceType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;

import java.util.Objects;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * Represents an HTTP service built from a service contract type.
 *
 * @since 2.0.0
 */
public class HttpServiceFromContract extends HttpService {

    private final ReferenceType serviceContractType;

    protected HttpServiceFromContract(BObject service, String basePath, ReferenceType httpServiceContractType) {
        super(service, basePath);
        this.serviceContractType = httpServiceContractType;
    }

    public static HttpService buildHttpService(BObject service, String basePath,
                                               ReferenceType serviceContractType) {
        HttpService httpService = new HttpServiceFromContract(service, basePath, serviceContractType);
        BMap serviceConfig = getHttpServiceConfigAnnotation(serviceContractType);
        httpService.populateServiceConfig(serviceConfig);
        return httpService;
    }

    @Override
    protected void populateServiceConfig(BMap serviceConfig) {
        if (checkConfigAnnotationAvailability(serviceConfig)) {
            Object basePathFromAnnotation = serviceConfig.get(HttpConstants.ANN_CONFIG_BASE_PATH);
            if (Objects.nonNull(basePathFromAnnotation)) {
                this.setBasePath(basePathFromAnnotation.toString());
            }
        }
        super.populateServiceConfig(serviceConfig);
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
