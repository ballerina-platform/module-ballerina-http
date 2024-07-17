/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 */

package io.ballerina.stdlib.http.api.service.endpoint;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.BallerinaHTTPConnectorListener;
import io.ballerina.stdlib.http.api.HTTPServicesRegistry;
import io.ballerina.stdlib.http.api.HttpConnectorPortBindingListener;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;

import static io.ballerina.stdlib.http.api.HttpConstants.SERVER_CONNECTOR_FUTURE;
import static io.ballerina.stdlib.http.api.HttpConstants.SERVICE_ENDPOINT_CONFIG;

/**
 * Start the HTTP listener instance.
 *
 * @since 0.966
 */
public class Start extends AbstractHttpNativeFunction {
    public static Object start(Environment env, BObject listener) {
        if (!isConnectorStarted(listener)) {
            return startServerConnector(env, listener);
        }
        return null;
    }

    private static Object startServerConnector(Environment env, BObject serviceEndpoint) {
        // TODO : Move these to `register` after this issue is fixed
        //  https://github.com/ballerina-platform/ballerina-lang/issues/33594
        HTTPServicesRegistry httpServicesRegistry = getHttpServicesRegistry(serviceEndpoint);
        // Register services implemented via service contract type
        for (BObject serviceContractImpl : httpServicesRegistry.getServiceContractImpls()) {
            httpServicesRegistry.registerServiceImplementedByContract(serviceContractImpl);
        }
        // Get and populate interceptor services
        Runtime runtime = getRuntime(env, httpServicesRegistry);
        try {
            HttpUtil.populateInterceptorServicesFromListener(serviceEndpoint, runtime);
            HttpUtil.populateInterceptorServicesFromService(serviceEndpoint, httpServicesRegistry);
            HttpUtil.markPossibleLastInterceptors(httpServicesRegistry);
        } catch (Exception ex) {
            return HttpUtil.createHttpError("interceptor service registration failed: " + ex.getMessage(),
                                             HttpErrorType.GENERIC_LISTENER_ERROR);
        }

        ServerConnector serverConnector = getServerConnector(serviceEndpoint);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        BallerinaHTTPConnectorListener httpListener =
                new BallerinaHTTPConnectorListener(getHttpServicesRegistry(serviceEndpoint),
                                                   getHttpInterceptorServicesRegistries(serviceEndpoint),
                                                   (BMap) serviceEndpoint.getNativeData(SERVICE_ENDPOINT_CONFIG),
                                                   serviceEndpoint.getNativeData(HttpConstants.INTERCEPTORS));
        serviceEndpoint.addNativeData(SERVER_CONNECTOR_FUTURE, serverConnectorFuture);
        HttpConnectorPortBindingListener portBindingListener = new HttpConnectorPortBindingListener();
        serverConnectorFuture.setHttpConnectorListener(httpListener);
        serverConnectorFuture.setPortBindingEventListener(portBindingListener);

        try {
            serverConnectorFuture.sync();
        } catch (Exception ex) {
            throw HttpUtil.createHttpError("failed to start server connector '"
                    + serverConnector.getConnectorID()
                            + "': " + ex.getMessage(), HttpErrorType.LISTENER_STARTUP_FAILURE);
        }

        serviceEndpoint.addNativeData(HttpConstants.CONNECTOR_STARTED, true);
        return null;
    }

    private static Runtime getRuntime(Environment env, HTTPServicesRegistry httpServicesRegistry) {
        if (httpServicesRegistry.getRuntime() != null) {
            return httpServicesRegistry.getRuntime();
        } else {
            Runtime runtime = env.getRuntime();
            httpServicesRegistry.setRuntime(runtime);
            return runtime;
        }
    }

    private Start() {}
}
