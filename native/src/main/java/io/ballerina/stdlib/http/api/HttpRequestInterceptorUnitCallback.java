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
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import static io.ballerina.stdlib.http.api.HttpErrorType.INTERCEPTOR_RETURN_ERROR;

/**
 * {@code HttpRequestInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina
 * side when a request interceptor service is invoked.
 *
 * @since SL Beta 4
 */
public class HttpRequestInterceptorUnitCallback extends HttpCallableUnitCallback {
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: response has already been sent";
    private final BObject caller;
    private final Runtime runtime;
    private final HttpCarbonMessage requestMessage;
    private final BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener;
    private final BObject requestCtx;

    HttpRequestInterceptorUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime,
                                       BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener) {
        super(requestMessage, runtime);
        this.runtime = runtime;
        this.requestMessage = requestMessage;
        this.requestCtx = (BObject) requestMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        this.ballerinaHTTPConnectorListener = ballerinaHTTPConnectorListener;
        this.caller = (BObject) requestMessage.getProperty(HttpConstants.CALLER);
    }

    @Override
    public void notifySuccess(Object result) {
        if (result instanceof BError) {
            if (!result.equals(requestCtx.getNativeData(HttpConstants.TARGET_SERVICE))) {
                requestMessage.setHttpStatusCode(500);
            }
            invokeErrorInterceptors((BError) result, true);
            return;
        }
        validateResponseAndProceed(result);
    }

    @Override
    public void notifyFailure(BError error) { // handles panic and check_panic
        cleanupRequestMessage();
        sendFailureResponse(error);
        System.exit(1);
    }

    public void invokeErrorInterceptors(BError error, boolean printError) {
        requestMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR, error);
        if (printError) {
            error.printStackTrace();
        }
        ballerinaHTTPConnectorListener.onMessage(requestMessage);
    }

    public void returnErrorResponse(Object error) {
        cleanupRequestMessage();

        Object[] paramFeed = new Object[4];
        paramFeed[0] = error;
        paramFeed[1] = true;
        paramFeed[2] = null;
        paramFeed[3] = true;

        invokeBalMethod(paramFeed, "returnErrorResponse");
    }

    private boolean alreadyResponded() {
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
        int interceptorId = getRequestInterceptorId();
        requestMessage.setProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorId);
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);
        boolean nextCalled = (boolean) requestCtx.getNativeData(HttpConstants.REQUEST_CONTEXT_NEXT);

        if (alreadyResponded()) {
            if (nextCalled) {
                sendRequestToNextService();
            }
            return;
        }

        if (result == null) {
            returnResponse(null);
            if (nextCalled) {
                sendRequestToNextService();
                return;
            }
            return;
        }

        if (isServiceType(result)) {
            validateServiceReturnType(result, interceptorId, interceptors);
        } else {
            returnResponse(result);
        }
    }

    private boolean isServiceType(Object result) {
        return result instanceof BObject && ((BObject) result).getType() instanceof ServiceType;
    }

    private void validateServiceReturnType(Object result, int interceptorId, BArray interceptors) {
        if (interceptors != null) {
            if (interceptorId < interceptors.size()) {
                Object interceptor = interceptors.get(interceptorId);
                if (result.equals(interceptor)) {
                    sendRequestToNextService();
                } else {
                    String message = "next interceptor service did not match with the configuration";
                    BError err = HttpUtil.createHttpStatusCodeError(INTERCEPTOR_RETURN_ERROR, message);
                    invokeErrorInterceptors(err, true);
                }
            } else {
                Object targetService = requestCtx.getNativeData(HttpConstants.TARGET_SERVICE);
                if (result.equals(targetService)) {
                    sendRequestToNextService();
                } else {
                    String message = "target service did not match with the configuration";
                    BError err = HttpUtil.createHttpStatusCodeError(INTERCEPTOR_RETURN_ERROR, message);
                    invokeErrorInterceptors(err, true);
                }
            }
        }
    }

    private void returnResponse(Object result) {
        Object[] paramFeed = new Object[8];
        paramFeed[0] = result;
        paramFeed[1] = true;
        paramFeed[2] = null;
        paramFeed[3] = true;
        paramFeed[4] = null;
        paramFeed[5] = true;
        paramFeed[6] = null;
        paramFeed[7] = true;

        invokeBalMethod(paramFeed, "returnResponse");
    }

    public void invokeBalMethod(Object[] paramFeed, String methodName) {
        Callback returnCallback = new Callback() {
            @Override
            public void notifySuccess(Object result) {
                printStacktraceIfError(result);
            }

            @Override
            public void notifyFailure(BError result) {
                cleanupRequestMessage();
                HttpUtil.handleFailure(requestMessage, result, false);
            }
        };
        runtime.invokeMethodAsyncSequentially(
                caller, methodName, null, ModuleUtils.getNotifySuccessMetaData(),
                returnCallback, null, PredefinedTypes.TYPE_NULL, paramFeed);
    }

    private int getRequestInterceptorId() {
        return Math.max((int) requestCtx.getNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX),
                (int) requestMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX));
    }
}
