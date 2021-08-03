package io.ballerina.stdlib.http.api.service.endpoint;

import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HTTPServicesRegistry;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;

/**
 * Includes common functions to all the actions.
 *
 * @since 0.966
 */
public abstract class AbstractHttpNativeFunction {

    protected static HTTPServicesRegistry getHttpServicesRegistry(BObject serviceEndpoint) {
        return (HTTPServicesRegistry) serviceEndpoint.getNativeData(HttpConstants.HTTP_SERVICE_REGISTRY);
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
}
