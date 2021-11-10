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

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import static java.lang.System.err;

/**
 * {@code HttpInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina side when
 * an interceptor service is invoked.
 */
public class HttpInterceptorUnitCallback implements Callback {
    private final HttpCarbonMessage requestMessage;
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: response has already been sent";
    private final BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener;
    private final BObject requestCtx;

    HttpInterceptorUnitCallback(HttpCarbonMessage requestMessage,
                                    BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener) {
        this.requestMessage = requestMessage;
        this.requestCtx = (BObject) requestMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        this.ballerinaHTTPConnectorListener = ballerinaHTTPConnectorListener;
    }

    @Override
    public void notifySuccess(Object result) {
        printStacktraceIfError(result);
        if (result instanceof BError) {
            notifyFailure((BError) result);
        } else {
            if (!alreadyResponded(result)) {
                if ((boolean) requestCtx.getNativeData(HttpConstants.REQUEST_CONTEXT_NEXT)) {
                    ballerinaHTTPConnectorListener.onMessage(requestMessage);
                    requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
                } else {
                    BError err = HttpUtil.createHttpError("interceptor service should call next() method to " +
                            "continue execution", HttpErrorType.GENERIC_LISTENER_ERROR);
                    notifyFailure(err);
                }
            }
        }
    }

    @Override
    public void notifyFailure(BError error) { // handles panic and check_panic
        // This check is added to release the failure path since there is an authn/authz failure and responded
        // with 401/403 internally.
        if (error.getMessage().equals("Already responded by auth desugar.")) {
            return;
        }
        if (alreadyResponded(error)) {
            return;
        }
        requestMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR, error);
        ballerinaHTTPConnectorListener.onMessage(requestMessage);
    }

    public void sendFailureResponse() {
        BError error = (BError) requestMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
        cleanupRequestAndContext();
        // TODO : Set the Error Status Code
        HttpUtil.handleFailure(requestMessage, error);
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
