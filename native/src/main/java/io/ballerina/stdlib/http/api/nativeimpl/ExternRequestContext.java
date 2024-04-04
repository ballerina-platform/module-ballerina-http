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
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import org.ballerinalang.langlib.value.EnsureType;

import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_INTERCEPTOR_RETURN_ERROR;

/**
 * Utilities related to HTTP request context.
 */
public final class ExternRequestContext {

    private ExternRequestContext() {}

    public static Object getWithType(BObject requestCtx, BString key, BTypedesc targetType) {
        BMap members = requestCtx.getMapValue(HttpConstants.REQUEST_CTX_MEMBERS);
        try {
            Object value = members.getOrThrow(key);
            Object convertedType = EnsureType.ensureType(value, targetType);
            if (convertedType instanceof BError) {
                return HttpUtil.createHttpError("type conversion failed for value of key: " + key.getValue(),
                                                HttpErrorType.GENERIC_LISTENER_ERROR,
                                                (BError) convertedType);
            }
            return convertedType;
        } catch (Exception exp) {
            return HttpUtil.createHttpError("no member found for key: " + key.getValue(),
                                            HttpErrorType.GENERIC_LISTENER_ERROR,
                                            exp instanceof BError ? (BError) exp : null);
        }
    }

    public static Object next(BObject requestCtx) {
        BArray interceptors = getInterceptors(requestCtx);
        if (interceptors != null) {
            if (!isInterceptorService(requestCtx)) {
                // TODO : After introducing response interceptors, calling ctx.next() should return "illegal function
                //  invocation : next()" if there is a response interceptor service in the pipeline
                return HttpUtil.createHttpStatusCodeError(INTERNAL_INTERCEPTOR_RETURN_ERROR,
                        "no next service to be returned");
            }
            requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, true);
            return getNextInterceptor(requestCtx, interceptors);
        } else {
            String message = "request context object does not contain the configured interceptors";
            return HttpUtil.createHttpStatusCodeError(INTERNAL_INTERCEPTOR_RETURN_ERROR, message);
        }
    }

    private static Object getNextInterceptor(BObject requestCtx, BArray interceptors) {
        String requiredInterceptorType = (String) requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE_TYPE);
        Object interceptorToReturn = requestCtx.getNativeData(HttpConstants.TARGET_SERVICE);
        int interceptorIndex = getInterceptorIndex(requestCtx, requiredInterceptorType);
        Object interceptor;
        while (0 <= interceptorIndex && interceptorIndex < interceptors.size()) {
            interceptor = interceptors.get(interceptorIndex);
            String interceptorType = HttpUtil.getInterceptorServiceType((BObject) interceptor);
            if (interceptorType.equals(requiredInterceptorType)) {
                interceptorToReturn = interceptor;
                break;
            }
            if (requiredInterceptorType.equals(HttpConstants.REQUEST_INTERCEPTOR)) {
                interceptorIndex += 1;
            } else {
                interceptorIndex -= 1;
            }
        }
        if (interceptorIndex > interceptors.size()) {
            return HttpUtil.createHttpStatusCodeError(INTERNAL_INTERCEPTOR_RETURN_ERROR,
                    "no next service to be returned");
        }
        if (interceptorIndex < 0) {
            requestCtx.addNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, -1);
            return null;
        }
        updateInterceptorIndex(requestCtx, requiredInterceptorType, interceptorIndex);
        return interceptorToReturn;
    }

    private static int getInterceptorIndex(BObject requestCtx, String nextInterceptorType) {
        int interceptorIndex;
        if (nextInterceptorType.equals(HttpConstants.REQUEST_INTERCEPTOR)) {
            interceptorIndex = (int) requestCtx.getNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX) + 1;
        } else {
            interceptorIndex = (int) requestCtx.getNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX) - 1;
        }
        return interceptorIndex;
    }

    private static void updateInterceptorIndex(BObject requestCtx, String nextInterceptorType, int interceptorId) {
        if (nextInterceptorType.equals(HttpConstants.REQUEST_INTERCEPTOR)) {
            requestCtx.addNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorId);
        } else {
            requestCtx.addNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorId);
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
