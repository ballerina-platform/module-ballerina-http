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
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

/**
 * Unbind the the listening port immediately and stop accepting new connection.
 *
 * @since 0.966
 */
public class GracefulStop extends AbstractHttpNativeFunction {
    public static Object gracefulStop(BObject serverEndpoint) {
        try {
            getServerConnector(serverEndpoint).stop();
            serverEndpoint.addNativeData(HttpConstants.CONNECTOR_STARTED, false);
            resetRegistry(serverEndpoint);
        } catch (Exception ex) {
            return HttpUtil.createHttpError(ex.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR);
        }
        return null;
    }

    private GracefulStop() {}
}
