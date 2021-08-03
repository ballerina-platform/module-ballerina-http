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

import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.BallerinaHTTPConnectorListener;
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
    public static Object start(BObject listener) {
        if (!isConnectorStarted(listener)) {
            return startServerConnector(listener);
        }
        return null;
    }

    private static Object startServerConnector(BObject serviceEndpoint) {
        ServerConnector serverConnector = getServerConnector(serviceEndpoint);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        BallerinaHTTPConnectorListener httpListener =
                new BallerinaHTTPConnectorListener(getHttpServicesRegistry(serviceEndpoint),
                                                   serviceEndpoint.getMapValue(SERVICE_ENDPOINT_CONFIG));
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

    private Start() {}
}
