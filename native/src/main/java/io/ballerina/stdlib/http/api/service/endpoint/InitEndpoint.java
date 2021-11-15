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

import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpConnectionManager;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;

import static io.ballerina.stdlib.http.api.HttpConstants.ENDPOINT_CONFIG_PORT;
import static io.ballerina.stdlib.http.api.HttpUtil.getListenerConfig;

/**
 * Initialize the HTTP listener.
 *
 * @since 0.966
 */
public class InitEndpoint extends AbstractHttpNativeFunction {
    public static Object initEndpoint(BObject serviceEndpoint, BMap serviceEndpointConfig) {
        try {
            // Creating server connector
            serviceEndpoint.addNativeData(HttpConstants.SERVICE_ENDPOINT_CONFIG, serviceEndpointConfig);
            long port = serviceEndpoint.getIntValue(ENDPOINT_CONFIG_PORT);
            ListenerConfiguration listenerConfiguration = getListenerConfig(port, serviceEndpointConfig);
            ServerConnector httpServerConnector =
                    HttpConnectionManager.getInstance().createHttpServerConnector(listenerConfiguration);
            serviceEndpoint.addNativeData(HttpConstants.HTTP_SERVER_CONNECTOR, httpServerConnector);

            //Adding service registries to native data
            resetRegistry(serviceEndpoint);
            return null;
        } catch (BError errorValue) {
            return HttpUtil.createHttpError(errorValue.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR,
                                            errorValue.getCause());
        } catch (Exception e) {
            return HttpUtil.createHttpError(e.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    private InitEndpoint() {}
}
