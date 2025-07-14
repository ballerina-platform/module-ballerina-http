/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.uri.URIUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_HOST;

/**
 * This services registry holds all the interceptor services of HTTP. This is a singleton class where all HTTP
 * Dispatchers can access.
 *
 * @since SL Beta 4
 */
public class HTTPInterceptorServicesRegistry {

    private static final Logger logger = LoggerFactory.getLogger(HTTPInterceptorServicesRegistry.class);

    protected Map<String, ServicesMapHolder> servicesMapByHost = new ConcurrentHashMap<>();
    protected Map<String, InterceptorService> servicesByBasePath;
    protected List<String> sortedServiceURIs;
    private Runtime runtime;
    private String servicesType = HttpConstants.HTTP_NORMAL;
    private boolean possibleLastInterceptor = false;

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
    public Map<String, InterceptorService> getServicesByHost(String hostName) {
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
     * @param service      requested serviceInfo to be registered
     * @param basePath     absolute resource path of the service
     * @param fromListener boolean value indicates whether the service is from listener configuration or not
     */
    public void registerInterceptorService(BObject service, String basePath, boolean fromListener) {
        InterceptorService httpInterceptorService = InterceptorService.buildHttpService(service, basePath,
                this.getServicesType(), fromListener);
        service.addNativeData(HttpConstants.ABSOLUTE_RESOURCE_PATH, basePath);
        String hostName = httpInterceptorService.getHostName();
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
        servicesByBasePath.put(basePath, httpInterceptorService);
        if (logger.isDebugEnabled()) {
            logger.debug(String.format("Service deployed : %s with context %s", TypeUtils.getType(service).getName(),
                    basePath));
        }

        //basePath will get cached after registering service
        sortedServiceURIs.add(basePath);
        sortedServiceURIs.sort((basePath1, basePath2) -> basePath2.length() - basePath1.length());
    }

    public String findTheMostSpecificBasePath(String requestURIPath, Map<String, InterceptorService> services,
                                              List<String> sortedServiceURIs) {
        for (Object key : sortedServiceURIs) {
            if (URIUtil.isPathMatch(requestURIPath, key.toString())) {
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

    public String getServicesType() {
        return servicesType;
    }

    public void setServicesType(String servicesType) {
        this.servicesType = servicesType;
    }

    /**
     * Holds both serviceByBasePath map and sorted Service basePath list.
     */
    protected static class ServicesMapHolder {
        private Map<String, InterceptorService> servicesByBasePath;
        private List<String> sortedServiceURIs;

        public ServicesMapHolder(Map<String, InterceptorService> servicesByBasePath,
                                                                                    List<String> sortedServiceURIs) {
            this.servicesByBasePath = servicesByBasePath;
            this.sortedServiceURIs = sortedServiceURIs;
        }
    }

    public boolean isPossibleLastInterceptor() {
        return possibleLastInterceptor;
    }

    public void setPossibleLastInterceptor(boolean possibleLastInterceptor) {
        this.possibleLastInterceptor = possibleLastInterceptor;
    }
}
