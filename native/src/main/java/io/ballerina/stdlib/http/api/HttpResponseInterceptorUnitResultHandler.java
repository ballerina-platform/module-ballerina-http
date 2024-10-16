/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.nativeimpl.connection.Respond;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

/**
 * {@code HttpResponseInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina
 * side when a response interceptor service is invoked.
 */
public class HttpResponseInterceptorUnitResultHandler extends HttpCallableUnitResultHandler {
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: response has already been sent";

    private final HttpCarbonMessage requestMessage;
    private final BObject caller;
    private final BObject response;
    private final Environment environment;
    private final BObject requestCtx;
    private final DataContext dataContext;
    private final boolean possibleLastInterceptor;


    public HttpResponseInterceptorUnitResultHandler(HttpCarbonMessage requestMessage, BObject caller, BObject response,
                                                    Environment env, DataContext dataContext, Runtime runtime,
                                                    boolean possibleLastInterceptor) {
        super(requestMessage, runtime);
        this.requestMessage = requestMessage;
        this.requestCtx = (BObject) requestMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        this.caller = caller;
        this.response = response;
        this.environment = env;
        this.dataContext = dataContext;
        this.possibleLastInterceptor = possibleLastInterceptor;
    }

    @Override
    public void handleResult(Object result) {
        if (result instanceof BError) {
            requestMessage.setHttpStatusCode(500);
            invokeErrorInterceptors((BError) result, false);
            return;
        }
        if (possibleLastInterceptor) {
            cleanupRequestMessage();
        }
        validateResponseAndProceed(result);
    }

    @Override
    public void handleError(BError error) { // handles panic and check_panic
        cleanupRequestMessage();
        sendFailureResponse(error);
        System.exit(1);
    }

    public void invokeErrorInterceptors(BError error, boolean isInternalError) {
        if (isInternalError) {
            requestMessage.setProperty(HttpConstants.INTERNAL_ERROR, true);
        } else {
            requestMessage.removeProperty(HttpConstants.INTERNAL_ERROR);
        }
        requestMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR, error);
        returnErrorResponse(error);
    }

    private void sendResponseToNextService() {
        Respond.nativeRespondWithDataCtx(environment, caller, response, dataContext);
    }

    private boolean alreadyResponded() {
        try {
            HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        } catch (BError e) {
            return true;
        }
        return false;
    }

    private void validateResponseAndProceed(Object result) {
        int interceptorId = getResponseInterceptorId();
        requestMessage.setProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorId);
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);

        if (alreadyResponded()) {
            dataContext.notifyOutboundResponseStatus(null);
            stopObserverContext();
            return;
        }

        if (result == null && interceptorId == -1) {
            sendResponseToNextService();
            return;
        }

        if (isServiceType(result)) {
            validateServiceReturnType(result, interceptorId, interceptors);
        } else {
            returnResponse(result);
        }
    }

    private boolean isServiceType(Object result) {
        return result instanceof BObject && TypeUtils.getType(result) instanceof ServiceType;
    }

    private void validateServiceReturnType(Object result, int interceptorId, BArray interceptors) {
        if (interceptors != null) {
            if (interceptorId < interceptors.size()) {
                Object interceptor = interceptors.get(interceptorId);
                if (result.equals(interceptor)) {
                    sendResponseToNextService();
                } else {
                    BError err = HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_INTERCEPTOR_RETURN_ERROR,
                            "next interceptor service did not match with the configuration");
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

    @Override
    public void invokeBalMethod(Object[] paramFeed, String methodName) {
        try {
            this.getRuntime().call(caller, methodName, paramFeed);
            stopObserverContext();
            dataContext.notifyOutboundResponseStatus(null);
        } catch (BError error) {
            dataContext.notifyOutboundResponseStatus(null);
            sendFailureResponse(error);
        }
    }

    private int getResponseInterceptorId() {
        return Math.min((int) requestCtx.getNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX),
                        (int) requestMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX));
    }

    public void returnErrorResponse(BError error) {
        Object[] paramFeed = new Object[4];
        paramFeed[0] = error;
        paramFeed[1] = true;
        paramFeed[2] = null;
        paramFeed[3] = true;

        invokeBalMethod(paramFeed, "returnErrorResponse");
    }
}
