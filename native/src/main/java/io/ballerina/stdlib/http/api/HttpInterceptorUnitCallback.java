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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

/**
 * {@code HttpInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina side when
 * an interceptor service is invoked.
 *
 * @since SL Beta 4
 */
public class HttpInterceptorUnitCallback implements Callback {
    private final BObject caller;
    private final Runtime runtime;
    private final HttpCarbonMessage requestMessage;
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: response has already been sent";
    private final BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener;
    private final BObject requestCtx;

    HttpInterceptorUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime,
                                BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener) {
        this.runtime = runtime;
        this.requestMessage = requestMessage;
        this.requestCtx = (BObject) requestMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        this.ballerinaHTTPConnectorListener = ballerinaHTTPConnectorListener;
        this.caller = (BObject) requestMessage.getProperty(HttpConstants.CALLER);
    }

    @Override
    public void notifySuccess(Object result) {
        printStacktraceIfError(result);
        if (result instanceof BError) {
            notifyFailure((BError) result);
        } else {
            validateResponseAndProceed(result);
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

    public void sendFailureResponse(BError error) {
        cleanupRequestAndContext();
        HttpUtil.handleFailure(requestMessage, error, false);
    }

    private void cleanupRequestAndContext() {
        requestMessage.waitAndReleaseAllEntities();
    }

    private boolean alreadyResponded(Object result) {
        try {
            HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        } catch (BError e) {
            return true;
        }
        return false;
    }

    private void printStacktraceIfError(Object result) {
        if (result instanceof BError) {
            ((BError) result).printStackTrace();
        }
    }

    private void sendRequestToNextService() {
        ballerinaHTTPConnectorListener.onMessage(requestMessage);
    }

    private void validateResponseAndProceed(Object result) {
        int interceptorId = (int) requestCtx.getNativeData(HttpConstants.INTERCEPTOR_SERVICE_INDEX);
        requestMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE_INDEX, interceptorId);
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);
        boolean nextCalled = (boolean) requestCtx.getNativeData(HttpConstants.REQUEST_CONTEXT_NEXT);

        if (alreadyResponded(result)) {
            if (nextCalled) {
                sendRequestToNextService();
            }
            return;
        }

        if (result == null) {
            if (nextCalled) {
                sendRequestToNextService();
                return;
            }
            returnEmptyResponse();
            return;
        }

        if (interceptors != null) {
            if (interceptorId < interceptors.size()) {
                Object interceptor = interceptors.get(interceptorId);
                if (result.equals(interceptor)) {
                    sendRequestToNextService();
                } else {
                    BError err = HttpUtil.createHttpError("next interceptor service did not match " +
                            "with the configuration", HttpErrorType.GENERIC_LISTENER_ERROR);
                    sendFailureResponse(err);
                }
            } else {
                Object targetService = requestCtx.getNativeData(HttpConstants.TARGET_SERVICE);
                if (result.equals(targetService)) {
                    sendRequestToNextService();
                } else {
                    BError err = HttpUtil.createHttpError("target service did not match with the configuration",
                            HttpErrorType.GENERIC_LISTENER_ERROR);
                    sendFailureResponse(err);
                }
            }
        }
    }

    private void returnEmptyResponse() {
        Object[] paramFeed = new Object[6];
        paramFeed[0] = null;
        paramFeed[1] = true;
        paramFeed[2] = null;
        paramFeed[3] = true;
        paramFeed[4] = null;
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
}
