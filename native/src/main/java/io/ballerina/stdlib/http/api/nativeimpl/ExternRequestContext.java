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
        BArray interceptors = getInterceptors(requestCtx);
        Object mainService = requestCtx.getNativeData(HttpConstants.TARGET_SERVICE);
        if (interceptors != null) {
            if (!isInterceptorService(requestCtx)) {
                // TODO : After introducing response interceptors, calling ctx.next() should return "illegal function
                //  invocation : next()" if there is a response interceptor service in the pipeline
                return HttpUtil.createHttpError("no next service to be returned",
                        HttpErrorType.GENERIC_LISTENER_ERROR);
            }
            String nextInterceptorType = (String) requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE_TYPE);
            Object interceptorToReturn = mainService;
            Object interceptor;
            int interceptorId;
            if (nextInterceptorType.equals(HttpConstants.HTTP_REQUEST_INTERCEPTOR)) {
                interceptorId = (int) requestCtx.getNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX) + 1;
            } else {
                interceptorId = (int) requestCtx.getNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX) + 1;
            }
            requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, true);
            while (interceptorId < interceptors.size()) {
                interceptor = interceptors.get(interceptorId);
                String interceptorType = HttpUtil.getInterceptorServiceType((BObject) interceptor);
                if (interceptorType.equals(nextInterceptorType)) {
                    interceptorToReturn = interceptor;
                    break;
                }
                if (nextInterceptorType.equals(HttpConstants.HTTP_REQUEST_INTERCEPTOR)) {
                    interceptorId += 1;
                } else {
                    interceptorId -= 1;
                }
            }
            if (interceptorId > interceptors.size()) {
                return HttpUtil.createHttpError("no next service to be returned",
                        HttpErrorType.GENERIC_LISTENER_ERROR);
            }
            if (interceptorId < 0) {
                return null;
            }
            if (nextInterceptorType.equals(HttpConstants.HTTP_REQUEST_INTERCEPTOR)) {
                requestCtx.addNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorId);
            } else {
                requestCtx.addNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorId);
            }
            return interceptorToReturn;
        } else {
            return HttpUtil.createHttpError("request context object does not contain the configured " +
                    "interceptors", HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    private static boolean isInterceptorService(BObject requestCtx) {
        return requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE) != null &&
                (boolean) requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE);
    }

    private static BArray getInterceptors(BObject requestCtx) {
        return requestCtx.getNativeData(HttpConstants.INTERCEPTORS) == null ? null :
                (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);
    }
}
