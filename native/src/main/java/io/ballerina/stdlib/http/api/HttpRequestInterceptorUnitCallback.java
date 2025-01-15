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

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_INTERCEPTOR_RETURN_ERROR;

/**
 * {@code HttpRequestInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina
 * side when a request interceptor service is invoked.
 *
 * @since SL Beta 4
 */
public class HttpRequestInterceptorUnitCallback extends HttpInterceptorUnitCallback {
    private final BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener;

    HttpRequestInterceptorUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime,
                                       BallerinaHTTPConnectorListener ballerinaHTTPConnectorListener) {
        super(requestMessage, runtime);
        this.ballerinaHTTPConnectorListener = ballerinaHTTPConnectorListener;
    }

    @Override
    public void handleResult(Object result) {
        if (result instanceof BError) {
            if (!result.equals(requestCtx.getNativeData(HttpConstants.TARGET_SERVICE))) {
                requestMessage.setHttpStatusCode(500);
            }
            invokeErrorInterceptors((BError) result, false);
            return;
        }
        validateResponseAndProceed(result);
    }

    public void invokeErrorInterceptors(BError error, boolean isInternalError) {
        if (isInternalError) {
            requestMessage.setProperty(HttpConstants.INTERNAL_ERROR, true);
        } else {
            requestMessage.removeProperty(HttpConstants.INTERNAL_ERROR);
        }
        requestMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR, error);
        ballerinaHTTPConnectorListener.onMessage(requestMessage);
    }

    private void sendRequestToNextService() {
        ballerinaHTTPConnectorListener.onMessage(requestMessage);
    }

    private void validateResponseAndProceed(Object result) {
        int interceptorId = getRequestInterceptorId();
        requestMessage.setProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorId);
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);
        boolean nextCalled = (boolean) requestCtx.getNativeData(HttpConstants.REQUEST_CONTEXT_NEXT);

        if (alreadyResponded(result)) {
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

    private void validateServiceReturnType(Object result, int interceptorId, BArray interceptors) {
        if (interceptors != null) {
            if (interceptorId < interceptors.size()) {
                Object interceptor = interceptors.get(interceptorId);
                if (result.equals(interceptor)) {
                    sendRequestToNextService();
                } else {
                    String message = "next interceptor service did not match with the configuration";
                    BError err = HttpUtil.createHttpStatusCodeError(INTERNAL_INTERCEPTOR_RETURN_ERROR, message);
                    invokeErrorInterceptors(err, true);
                }
            } else {
                Object targetService = requestCtx.getNativeData(HttpConstants.TARGET_SERVICE);
                if (result.equals(targetService)) {
                    sendRequestToNextService();
                } else {
                    String message = "target service did not match with the configuration";
                    BError err = HttpUtil.createHttpStatusCodeError(INTERNAL_INTERCEPTOR_RETURN_ERROR, message);
                    invokeErrorInterceptors(err, true);
                }
            }
        }
    }

    private int getRequestInterceptorId() {
        return Math.max((int) requestCtx.getNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX),
                (int) requestMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX));
    }
}
