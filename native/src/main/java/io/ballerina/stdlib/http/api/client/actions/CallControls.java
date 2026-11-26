/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.api.client.actions;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.CallDeadline;
import io.ballerina.stdlib.http.transport.contract.CallExchange;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.exceptions.CallCancelledException;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;

import java.math.BigDecimal;
import java.util.concurrent.TimeUnit;

/**
 * Natives that tie a request to the total time budget of the call it is sent for, and let the caller cancel it.
 */
public final class CallControls {

    // About 146 years, far beyond any call, and well clear of overflowing the nanosecond clock
    private static final long MAX_BUDGET_NANOS = TimeUnit.DAYS.toNanos(365L * 146);
    private static final BigDecimal NANOS_PER_SECOND = BigDecimal.valueOf(TimeUnit.SECONDS.toNanos(1));

    private CallControls() {
    }

    /**
     * Starts the total time budget of the call the request is sent for. A budget that is not positive means the
     * call has none, and removes the one a previous call left on the request.
     *
     * @param request the request of the call
     * @param seconds the total time of the call in seconds
     */
    public static void setCallDeadline(BObject request, BDecimal seconds) {
        BigDecimal nanos = seconds.decimalValue().multiply(NANOS_PER_SECOND);
        if (nanos.signum() <= 0) {
            // Not a null, as the native data of an object may not take one
            request.addNativeData(HttpConstants.CALL_DEADLINE, Boolean.FALSE);
            return;
        }
        long budget = nanos.compareTo(BigDecimal.valueOf(MAX_BUDGET_NANOS)) >= 0 ? MAX_BUDGET_NANOS :
                Math.max(nanos.longValue(), 1L);
        request.addNativeData(HttpConstants.CALL_DEADLINE, CallDeadline.startingNow(budget));
    }

    /**
     * Gets the time left in the total budget of the call the request is sent for.
     *
     * @param request the request of the call
     * @return the remaining time in seconds, zero if it has run out, or a negative value if the call has no budget
     */
    public static BDecimal remainingCallTime(BObject request) {
        Object callDeadline = request.getNativeData(HttpConstants.CALL_DEADLINE);
        if (!(callDeadline instanceof CallDeadline)) {
            return ValueCreator.createDecimalValue(BigDecimal.valueOf(-1));
        }
        long remaining = Math.max(((CallDeadline) callDeadline).remainingNanos(), 0);
        return ValueCreator.createDecimalValue(BigDecimal.valueOf(remaining, 9));
    }

    /**
     * Cancels the call an asynchronous request was submitted for, closing the connection or resetting the stream it
     * is carried on. Nothing happens if the call has ended.
     *
     * @param httpFuture the future of the submitted request
     * @return an error if the future is not one a request was submitted for, otherwise null
     */
    public static Object cancel(BObject httpFuture) {
        Object handle = httpFuture.getNativeData(HttpConstants.TRANSPORT_HANDLE);
        if (!(handle instanceof ResponseHandle)) {
            return HttpUtil.createHttpError("invalid http handle");
        }
        // The exchange of this very submission, even if its request object has been sent again since
        CallExchange exchange = ((ResponseHandle) handle).getOutboundMsgHolder().getCallExchange();
        if (exchange != null) {
            exchange.abort(new CallCancelledException(Constants.CALL_CANCELLED, -1));
        }
        return null;
    }
}
