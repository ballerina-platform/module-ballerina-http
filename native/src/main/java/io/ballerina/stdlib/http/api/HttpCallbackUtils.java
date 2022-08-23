/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import static io.ballerina.stdlib.http.api.HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY;

public class HttpCallbackUtils {

    protected static void stopObserverContext(HttpCarbonMessage requestMessage) {
        if (ObserveUtils.isObservabilityEnabled()) {
            ObserverContext observerContext = (ObserverContext) requestMessage
                    .getProperty(OBSERVABILITY_CONTEXT_PROPERTY);
            if (observerContext.isManuallyClosed()) {
                ObserveUtils.stopObservationWithContext(observerContext);
            }
        }
    }

    protected static void printStacktraceIfError(Object result) {
        if (result instanceof BError) {
            ((BError) result).printStackTrace();
        }
    }

    protected static void sendFailureResponse(BError error, HttpCarbonMessage requestMessage) {
        stopObserverContext(requestMessage);
        HttpUtil.handleFailure(requestMessage, error, true);
    }
}
