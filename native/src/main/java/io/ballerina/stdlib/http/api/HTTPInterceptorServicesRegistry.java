package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Locale;
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

    /**
     * Get ServiceInfo instance for given interface and base path.
     *
     * @param basepath basePath of the service.
     * @return the {@link InterceptorService} instance if exist else null
     */
    public InterceptorService getServiceInfo(String basepath) {
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
     * @param runtime  ballerina runtime instance.
     * @param service  requested serviceInfo to be registered.
     * @param basePath absolute resource path of the service
     */
    public void registerInterceptorService(Runtime runtime, BObject service, String basePath) {
        InterceptorService httpInterceptorService = InterceptorService.buildHttpService(service, basePath,
                this.getServicesType());
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
            logger.debug(String.format("Service deployed : %s with context %s", service.getType().getName(), basePath));
        }

        //basePath will get cached after registering service
        sortedServiceURIs.add(basePath);
        sortedServiceURIs.sort((basePath1, basePath2) -> basePath2.length() - basePath1.length());
    }

    public String findTheMostSpecificBasePath(String requestURIPath, Map<String, InterceptorService> services,
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

    public String getServicesType() {
        return servicesType;
    }

    public void setServicesType(String servicesType) {
        if (servicesType == null) {
            throw new BallerinaConnectorException("HTTP interceptor services should include only one " +
                    "interceptor type");
        } else {
            this.servicesType = servicesType;
        }
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
        InterceptorService interceptorService = InterceptorService.buildHttpService(service, basePath,
                this.getServicesType());
        String hostName = interceptorService.getHostName();
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
            logger.debug(String.format("Service detached : %s with context %s", service.getType().getName(), basePath));
        }
        sortedServiceURIs.sort((basePath1, basePath2) -> basePath2.length() - basePath1.length());
    }
}
