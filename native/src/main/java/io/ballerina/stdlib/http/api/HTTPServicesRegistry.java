/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.ReferenceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_BASE_PATH;
import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_HOST;
import static io.ballerina.stdlib.http.api.HttpUtil.checkConfigAnnotationAvailability;

/**
 * This services registry holds all the services of HTTP + WebSocket. This is a singleton class where all HTTP +
 * WebSocket Dispatchers can access.
 *
 * @since 0.8
 */
public class HTTPServicesRegistry {

    private static final Logger logger = LoggerFactory.getLogger(HTTPServicesRegistry.class);
    private static final BString SERVICE_TYPE = StringUtils.fromString("serviceType");

    protected Map<String, ServicesMapHolder> servicesMapByHost = new ConcurrentHashMap<>();
    protected Map<String, HttpService> servicesByBasePath;
    protected List<String> sortedServiceURIs;
    private Runtime runtime;
    private boolean possibleLastService = true;
    private List<BObject> serviceContractImpls = new ArrayList<>();

    /**
     * Get ServiceInfo instance for given interface and base path.
     *
     * @param basepath basePath of the service.
     * @return the {@link HttpService} instance if exist else null
     */
    public HttpService getServiceInfo(String basepath) {
        return servicesByBasePath.get(basepath);
    }

    /**
     * Get ServicesMapHolder for given host name.
     *
     * @param hostName of the service
     * @return the servicesMapHolder if exists else null
     */
    public ServicesMapHolder getServicesMapHolder(String hostName) {
        return servicesMapByHost.get(hostName);
    }

    /**
     * Get Services map for given host name.
     *
     * @param hostName of the service
     * @return the serviceHost map if exists else null
     */
    public Map<String, HttpService> getServicesByHost(String hostName) {
        return servicesMapByHost.get(hostName).servicesByBasePath;
    }

    /**
     * Get sortedServiceURIs list for given host name.
     *
     * @param hostName of the service
     * @return the sorted basePath list if exists else null
     */
    public List<String> getSortedServiceURIsByHost(String hostName) {
        return servicesMapByHost.get(hostName).sortedServiceURIs;
    }

    /**
     * Register a service into the map.
     *
     * @param service  requested serviceInfo to be registered.
     * @param basePathFromDeclaration absolute resource path of the service
     */
    public void registerService(BObject service, String basePathFromDeclaration) {
        Optional<ReferenceType> serviceContractType = getServiceContractType(service);
        if (serviceContractType.isPresent()) {
            serviceContractImpls.add(service);
            return;
        }
        HttpService httpService = serviceContractType.map(referenceType ->
                HttpServiceFromContract.buildHttpService(service, basePathFromDeclaration,
                        referenceType)).orElseGet(
                                () -> HttpService.buildHttpService(service, basePathFromDeclaration));
        registerBallerinaService(service, httpService);
    }

    public void registerServiceImplementedByContract(BObject service) {
        Optional<ReferenceType> serviceContractType = getServiceContractType(service);
        if (serviceContractType.isEmpty()) {
            return;
        }
        HttpService httpService = HttpServiceFromContract.buildHttpService(service, DEFAULT_BASE_PATH,
                serviceContractType.get());
        registerBallerinaService(service, httpService);
    }

    private void registerBallerinaService(BObject service, HttpService httpService) {
        String basePath = httpService.getBasePath();
        service.addNativeData(HttpConstants.ABSOLUTE_RESOURCE_PATH, basePath);
        String hostName = httpService.getHostName();
        if (servicesMapByHost.get(hostName) == null) {
            servicesByBasePath = new ConcurrentHashMap<>();
            sortedServiceURIs = new CopyOnWriteArrayList<>();
            servicesMapByHost.put(hostName, new ServicesMapHolder(servicesByBasePath, sortedServiceURIs));
        } else {
            servicesByBasePath = getServicesByHost(hostName);
            sortedServiceURIs = getSortedServiceURIsByHost(hostName);
        }

        if (servicesByBasePath.containsKey(basePath)) {
            String errorMessage = hostName.equals(DEFAULT_HOST) ? "'" : "' under host name : '" + hostName + "'";
            throw ErrorCreator.createError(
                    StringUtils.fromString("Service registration failed: two services " +
                                                   "have the same basePath : '" + basePath + errorMessage));
        }
        servicesByBasePath.put(basePath, httpService);
        if (logger.isDebugEnabled()) {
            logger.debug(String.format("Service deployed : %s with context %s", TypeUtils.getType(service).getName(),
                    basePath));
        }

        //basePath will get cached after registering service
        sortedServiceURIs.add(basePath);
        sortedServiceURIs.sort((basePath1, basePath2) -> basePath2.length() - basePath1.length());
    }

    public List<BObject> getServiceContractImpls() {
        return serviceContractImpls;
    }


    private static Optional<ReferenceType> getServiceContractType(BObject service) {
        BMap serviceConfig = HttpService.getHttpServiceConfigAnnotation(service);
        if (!checkConfigAnnotationAvailability(serviceConfig)) {
            return Optional.empty();
        }

        Object serviceType = ((BMap<BString, Object>) serviceConfig).get(SERVICE_TYPE);
        if (Objects.isNull(serviceType) || !(serviceType instanceof BTypedesc serviceTypeDesc)) {
            return Optional.empty();
        }

        Type serviceContractType = serviceTypeDesc.getDescribingType();
        if (Objects.isNull(serviceContractType) ||
                !(serviceContractType instanceof ReferenceType serviceContractRefType)) {
            return Optional.empty();
        }
        return Optional.of(serviceContractRefType);
    }

    public String findTheMostSpecificBasePath(String requestURIPath, Map<String, HttpService> services,
                                              List<String> sortedServiceURIs) {
        for (Object key : sortedServiceURIs) {
            if (!requestURIPath.toLowerCase(Locale.getDefault()).contains(
                    key.toString().toLowerCase(Locale.getDefault()))) {
                continue;
            }
            if (requestURIPath.length() <= key.toString().length()) {
                return key.toString();
            }
            if (requestURIPath.startsWith(key.toString().concat("/"))) {
                return key.toString();
            }
        }
        if (services.containsKey(HttpConstants.DEFAULT_BASE_PATH)) {
            return HttpConstants.DEFAULT_BASE_PATH;
        }
        return null;
    }

    public Runtime getRuntime() {
        return runtime;
    }

    public void setRuntime(Runtime runtime) {
        this.runtime = runtime;
    }

    public Map<String, ServicesMapHolder> getServicesMapByHost() {
        return this.servicesMapByHost;
    }

    public boolean isPossibleLastService() {
        return possibleLastService;
    }

    public void setPossibleLastService(boolean possibleLastService) {
        this.possibleLastService = possibleLastService;
    }

    /**
     * Holds both serviceByBasePath map and sorted Service basePath list.
     */
    protected static class ServicesMapHolder {
        private Map<String, HttpService> servicesByBasePath;
        private List<String> sortedServiceURIs;

        public ServicesMapHolder(Map<String, HttpService> servicesByBasePath, List<String> sortedServiceURIs) {
            this.servicesByBasePath = servicesByBasePath;
            this.sortedServiceURIs = sortedServiceURIs;
        }

        public Map<String, HttpService> getServicesByBasePath() {
            return this.servicesByBasePath;
        }
    }

    /**
     * Un-register a service from the map.
     *
     * @param service requested service to be unregistered.
     */
    public void unRegisterService(BObject service) {
        String basePath = (String) service.getNativeData(HttpConstants.ABSOLUTE_RESOURCE_PATH);
        if (basePath == null) {
            logger.error("service is not attached to the listener");
            return;
        }
        HttpService httpService = HttpService.buildHttpService(service, basePath);
        String hostName = httpService.getHostName();
        ServicesMapHolder servicesMapHolder = servicesMapByHost.get(hostName);
        if (servicesMapHolder == null) {
            logger.error(basePath + " service is not attached to the listener");
            return;
        }
        servicesByBasePath = getServicesByHost(hostName);
        sortedServiceURIs = getSortedServiceURIsByHost(hostName);

        if (!servicesByBasePath.containsKey(basePath)) {
            logger.error(basePath + " service is not attached to the listener");
            return;
        }
        servicesByBasePath.remove(basePath);
        sortedServiceURIs.remove(basePath);
        if (logger.isDebugEnabled()) {
            logger.debug(String.format("Service detached : %s with context %s", TypeUtils.getType(service).getName(),
                    basePath));
        }
        sortedServiceURIs.sort((basePath1, basePath2) -> basePath2.length() - basePath1.length());
    }
}
