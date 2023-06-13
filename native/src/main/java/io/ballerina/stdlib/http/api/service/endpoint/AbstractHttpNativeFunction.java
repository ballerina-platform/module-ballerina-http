package io.ballerina.stdlib.http.api.service.endpoint;

import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HTTPInterceptorServicesRegistry;
import io.ballerina.stdlib.http.api.HTTPServicesRegistry;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;

import java.util.ArrayList;
import java.util.List;

/**
 * Includes common functions to all the actions.
 *
 * @since 0.966
 */
public abstract class AbstractHttpNativeFunction {

    protected static HTTPServicesRegistry getHttpServicesRegistry(BObject serviceEndpoint) {
        return (HTTPServicesRegistry) serviceEndpoint.getNativeData(HttpConstants.HTTP_SERVICE_REGISTRY);
    }

    public static List<HTTPInterceptorServicesRegistry> getHttpInterceptorServicesRegistries(BObject serviceEndpoint) {
        return (List<HTTPInterceptorServicesRegistry>) serviceEndpoint.getNativeData(HttpConstants.
                INTERCEPTOR_SERVICES_REGISTRIES);
    }

    protected static ServerConnector getServerConnector(BObject serviceEndpoint) {
        return (ServerConnector) serviceEndpoint.getNativeData(HttpConstants.HTTP_SERVER_CONNECTOR);
    }

    static boolean isConnectorStarted(BObject serviceEndpoint) {
        return serviceEndpoint.getNativeData(HttpConstants.CONNECTOR_STARTED) != null &&
                (Boolean) serviceEndpoint.getNativeData(HttpConstants.CONNECTOR_STARTED);
    }

    static void resetRegistry(BObject serviceEndpoint) {
        HTTPServicesRegistry httpServicesRegistry = new HTTPServicesRegistry();
        serviceEndpoint.addNativeData(HttpConstants.HTTP_SERVICE_REGISTRY, httpServicesRegistry);
    }

    public static void resetInterceptorRegistry(BObject serviceEndpoint, int interceptorsSize) {
        List<HTTPInterceptorServicesRegistry> httpInterceptorServicesRegistries = new ArrayList<>();
        for (int i = 0; i < interceptorsSize; i++) {
            httpInterceptorServicesRegistries.add(new HTTPInterceptorServicesRegistry());
        }
        serviceEndpoint.addNativeData(HttpConstants.INTERCEPTOR_SERVICES_REGISTRIES,
                httpInterceptorServicesRegistries);
    }
}
