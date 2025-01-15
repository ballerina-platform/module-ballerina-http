/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

/**
 * {@code HttpInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina
 * side when an interceptor service is invoked.
 */
public abstract class HttpInterceptorUnitCallback extends HttpCallableUnitCallback {
    protected final BObject requestCtx;

    HttpInterceptorUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime) {
        super(requestMessage, runtime);
        this.requestCtx = getRequestContext(requestMessage);
    }

    HttpInterceptorUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime, BObject caller) {
        super(requestMessage, runtime, caller);
        this.requestCtx = getRequestContext(requestMessage);
    }

    public static boolean isServiceType(Object result) {
        return result instanceof BObject && TypeUtils.getType(result) instanceof ServiceType;
    }

    public static BObject getRequestContext(HttpCarbonMessage requestMessage) {
        return (BObject) requestMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
    }

    @Override
    public void handlePanic(BError error) { // handles panic and check_panic
        cleanupRequestMessage();
        sendFailureResponse(error);
        System.exit(1);
    }

    @Override
    public boolean alreadyResponded(Object result) {
        try {
            HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        } catch (BError e) {
            return true;
        }
        return false;
    }

    @Override
    public void callBalMethod(Object[] paramFeed, String methodName) {
        try {
            runtime.callMethod(caller, methodName, null, paramFeed);
        } catch (BError error) {
            cleanupRequestMessage();
            HttpUtil.handleFailure(requestMessage, error);
        }
    }
}
