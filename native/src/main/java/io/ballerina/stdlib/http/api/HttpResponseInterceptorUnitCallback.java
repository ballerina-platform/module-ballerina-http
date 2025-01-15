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
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.nativeimpl.connection.Respond;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

/**
 * {@code HttpResponseInterceptorUnitCallback} is the responsible for acting on notifications received from Ballerina
 * side when a response interceptor service is invoked.
 */
public class HttpResponseInterceptorUnitCallback extends HttpInterceptorUnitCallback {
    private final BObject response;
    private final Environment environment;
    private final DataContext dataContext;
    private final boolean possibleLastInterceptor;


    public HttpResponseInterceptorUnitCallback(HttpCarbonMessage requestMessage, BObject caller, BObject response,
                                               Environment env, DataContext dataContext, Runtime runtime,
                                               boolean possibleLastInterceptor) {
        super(requestMessage, runtime, caller);
        this.response = response;
        this.environment = env;
        this.dataContext = dataContext;
        this.possibleLastInterceptor = possibleLastInterceptor;
    }

    @Override
    public void handleResult(Object result) {
        if (result instanceof BError) {
            requestMessage.setHttpStatusCode(500);
            invokeErrorInterceptors((BError) result, false, false);
            return;
        }
        if (possibleLastInterceptor) {
            cleanupRequestMessage();
        }
        validateResponseAndProceed(result);
    }

    private void sendResponseToNextService() {
        Respond.nativeRespondWithDataCtx(environment, caller, response, dataContext);
    }

    private void validateResponseAndProceed(Object result) {
        int interceptorId = getResponseInterceptorId();
        requestMessage.setProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorId);
        BArray interceptors = (BArray) requestCtx.getNativeData(HttpConstants.INTERCEPTORS);

        if (alreadyResponded(result)) {
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

    private void validateServiceReturnType(Object result, int interceptorId, BArray interceptors) {
        if (interceptors != null) {
            if (interceptorId < interceptors.size()) {
                Object interceptor = interceptors.get(interceptorId);
                if (result.equals(interceptor)) {
                    sendResponseToNextService();
                } else {
                    BError err = HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_INTERCEPTOR_RETURN_ERROR,
                            "next interceptor service did not match with the configuration");
                    invokeErrorInterceptors(err, true, false);
                }
            }
        }
    }

    private int getResponseInterceptorId() {
        return Math.min((int) requestCtx.getNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX),
                        (int) requestMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX));
    }
}
