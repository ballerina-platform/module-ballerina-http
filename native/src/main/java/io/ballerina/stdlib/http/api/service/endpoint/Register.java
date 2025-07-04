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
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HTTPServicesRegistry;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Register a service to the listener.
 *
 * @since 0.966
 */
public class Register extends AbstractHttpNativeFunction {
    public static Object register(Environment env, BObject serviceEndpoint, BObject service, Object serviceName) {
        try {
            HTTPServicesRegistry httpServicesRegistry = getHttpServicesRegistry(serviceEndpoint);
            Runtime runtime = env.getRuntime();
            httpServicesRegistry.setRuntime(runtime);
            String basePath = getBasePath(serviceName);
            httpServicesRegistry.registerService(service, basePath);
        } catch (BError ex) {
            return ex;
        } catch (Exception e) {
            return HttpUtil.createHttpError("service registration failed: " + e.getMessage(),
                                            HttpErrorType.GENERIC_LISTENER_ERROR);
        }
        return null;
    }

    private static String getBasePath(Object serviceName) {
        if (serviceName instanceof BArray) {
            List<String> strings = Arrays.stream(((BArray) serviceName).getStringArray()).map(
                    HttpUtil::unescapeAndEncodePath).collect(Collectors.toList());
            String basePath = String.join(HttpConstants.SINGLE_SLASH, strings);
            return HttpUtil.sanitizeBasePath(basePath);
        } else if (serviceName instanceof BString) {
            String path = ((BString) serviceName).getValue().trim();
            if (path.startsWith(HttpConstants.SINGLE_SLASH)) {
                path = path.substring(1);
            }
            String[] pathSplits = path.split(HttpConstants.SINGLE_SLASH);
            List<String> strings = Arrays.stream(pathSplits)
                    .map(HttpUtil::unescapeAndEncodePath)
                    .collect(Collectors.toList());
            String basePath = String.join(HttpConstants.SINGLE_SLASH, strings);
            return HttpUtil.sanitizeBasePath(basePath);
        } else {
            return HttpConstants.DEFAULT_BASE_PATH;
        }
    }

    private Register() {}
}
