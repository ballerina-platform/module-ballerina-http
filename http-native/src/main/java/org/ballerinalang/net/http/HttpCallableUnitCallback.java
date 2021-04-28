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

package org.ballerinalang.net.http;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import org.ballerinalang.net.http.nativeimpl.ModuleUtils;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import static org.ballerinalang.net.http.HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY;

/**
 * {@code HttpCallableUnitCallback} is the responsible for acting on notifications received from Ballerina side.
 *
 * @since 0.94
 */
public class HttpCallableUnitCallback implements Callback {
    private final BObject caller;
    private final Runtime runtime;
    private final String returnMediaType;
    private HttpCarbonMessage requestMessage;
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: request has already been responded";

    HttpCallableUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime, String returnMediaType) {
        this.requestMessage = requestMessage;
        this.caller = (BObject) requestMessage.getProperty(HttpConstants.CALLER);
        this.runtime = runtime;
        this.returnMediaType = returnMediaType;
    }

    @Override
    public void notifySuccess(Object result) {
        if (result == null) { // handles nil return and end of resource exec
            requestMessage.waitAndReleaseAllEntities();
            if (ObserveUtils.isObservabilityEnabled()) {
                ObserverContext observerContext
                        = (ObserverContext) requestMessage.getProperty(OBSERVABILITY_CONTEXT_PROPERTY);
                if (observerContext != null) {
                    ObserveUtils.stopObservationWithContext(observerContext);
                }
            }
            return;
        }
        HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        if (result instanceof BError) { // handles error check and return
            sendFailureResponse((BError) result);
            return;
        }

        Object[] paramFeed = new Object[4];
        paramFeed[0] = result;
        paramFeed[1] = true;
        paramFeed[2] = returnMediaType != null ? StringUtils.fromString(returnMediaType) : null;
        paramFeed[3] = true;

        Callback returnCallback = new Callback() {
            @Override
            public void notifySuccess(Object result) {
                requestMessage.waitAndReleaseAllEntities();
            }

            @Override
            public void notifyFailure(BError result) {
                sendFailureResponse(result);
            }
        };
        runtime.invokeMethodAsync(caller, "returnResponse", null, ModuleUtils.getNotifySuccessMetaData(),
                                  returnCallback, paramFeed);
    }

    @Override
    public void notifyFailure(BError error) { // handles panic and check_panic
        // This check is added to release the failure path since there is an authn/authz failure and responded
        // with 401/403 internally.
        if (error.getMessage().equals("Already responded by auth desugar.")) {
            requestMessage.waitAndReleaseAllEntities();
            return;
        }
        sendFailureResponse(error);
    }

    private void sendFailureResponse(BError error) {
        HttpUtil.handleFailure(requestMessage, error);
        if (ObserveUtils.isObservabilityEnabled()) {
            ObserverContext observerContext
                    = (ObserverContext) requestMessage.getProperty(OBSERVABILITY_CONTEXT_PROPERTY);
            if (observerContext != null) {
                ObserveUtils.stopObservationWithContext(observerContext);
            }
        }
        requestMessage.waitAndReleaseAllEntities();
    }
}
