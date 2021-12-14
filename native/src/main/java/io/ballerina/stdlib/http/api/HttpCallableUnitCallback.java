/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import static java.lang.System.err;

/**
 * {@code HttpCallableUnitCallback} is the responsible for acting on notifications received from Ballerina side.
 *
 * @since 0.94
 */
public class HttpCallableUnitCallback implements Callback {
    private final BObject caller;
    private final Runtime runtime;
    private final String returnMediaType;
    private final BMap cacheConfig;
    private HttpCarbonMessage requestMessage;
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: response has already been sent";

    HttpCallableUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime, String returnMediaType,
                             BMap cacheConfig) {
        this.requestMessage = requestMessage;
        this.caller = (BObject) requestMessage.getProperty(HttpConstants.CALLER);
        this.runtime = runtime;
        this.returnMediaType = returnMediaType;
        this.cacheConfig = cacheConfig;
    }

    @Override
    public void notifySuccess(Object result) {
        cleanupRequestAndContext();
        if (alreadyResponded(result)) {
            return;
        }
        printStacktraceIfError(result);

        Object[] paramFeed = new Object[6];
        paramFeed[0] = result;
        paramFeed[1] = true;
        paramFeed[2] = returnMediaType != null ? StringUtils.fromString(returnMediaType) : null;
        paramFeed[3] = true;
        paramFeed[4] = cacheConfig;
        paramFeed[5] = true;

        Callback returnCallback = new Callback() {
            @Override
            public void notifySuccess(Object result) {
                printStacktraceIfError(result);
            }

            @Override
            public void notifyFailure(BError result) {
                sendFailureResponse(result);
            }
        };
        runtime.invokeMethodAsyncSequentially(
                caller, "returnResponse", null, ModuleUtils.getNotifySuccessMetaData(),
                returnCallback, null, PredefinedTypes.TYPE_NULL, paramFeed);
    }

    @Override
    public void notifyFailure(BError error) { // handles panic and check_panic
        cleanupRequestAndContext();
        // This check is added to release the failure path since there is an authn/authz failure and responded
        // with 401/403 internally.
        if (error.getMessage().equals("Already responded by auth desugar.")) {
            return;
        }
        if (alreadyResponded(error)) {
            return;
        }
        sendFailureResponse(error);
    }

    private void sendFailureResponse(BError error) {
        HttpUtil.handleFailure(requestMessage, error, true);
    }

    private void cleanupRequestAndContext() {
        requestMessage.waitAndReleaseAllEntities();
        stopObservationWithContext();
    }

    private void stopObservationWithContext() {
        if (ObserveUtils.isObservabilityEnabled()) {
            ObserverContext observerContext
                    = (ObserverContext) requestMessage.getProperty(HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY);
            if (observerContext != null) {
                ObserveUtils.stopObservationWithContext(observerContext);
            }
        }
    }

    private boolean alreadyResponded(Object result) {
        try {
            HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        } catch (BError e) {
            if (result != null) { // handles nil return and end of resource exec
                printStacktraceIfError(result);
                err.println(HttpConstants.HTTP_RUNTIME_WARNING_PREFIX + e.getMessage());
            }
            return true;
        }
        return false;
    }

    private void printStacktraceIfError(Object result) {
        if (result instanceof BError) {
            ((BError) result).printStackTrace();
        }
    }
}
