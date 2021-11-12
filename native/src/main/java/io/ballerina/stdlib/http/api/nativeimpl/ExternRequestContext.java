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
package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

/**
 * Utilities related to HTTP request context.
 */
public class ExternRequestContext {
    public static Object next(BObject requestCtx) {
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.HTTP_INTERCEPTORS);
        if (interceptors != null) {
            int interceptorId = (int) requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE_INDEX) + 1;
            Object interceptor = null;
            requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, true);
            while (interceptorId < interceptors.size()) {
                interceptor = interceptors.get(interceptorId);
                String interceptorType = HttpUtil.getInterceptorServiceType((BObject) interceptor);
                if (interceptorType.equals(HttpConstants.HTTP_REQUEST_INTERCEPTOR)) {
                    break;
                }
                interceptorId += 1;
            }
            requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE_INDEX, interceptorId);
            return interceptor;
        } else {
            return HttpUtil.createHttpError("request context object does not contain the configured " +
                    "interceptors", HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }
}
