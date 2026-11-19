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

package io.ballerina.stdlib.http.transport.contract;

import io.ballerina.stdlib.http.transport.contract.exceptions.CallTimeoutException;
import io.netty.handler.codec.http.HttpResponseStatus;

import java.math.BigDecimal;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static io.ballerina.stdlib.http.transport.contract.Constants.CALL_TIMEOUT_EXCEEDED;

/**
 * The total time budget of one client call. It is shared by every attempt the call makes, so the retries and the
 * redirects of a call spend the same budget instead of each getting its own.
 */
public final class CallDeadline {

    private static final AtomicInteger TIMER_THREAD_COUNT = new AtomicInteger();
    private static final ScheduledThreadPoolExecutor TIMER = createTimer();

    private final long budgetNanos;
    private final long expiryNanos;

    private CallDeadline(long budgetNanos) {
        this.budgetNanos = budgetNanos;
        this.expiryNanos = System.nanoTime() + budgetNanos;
    }

    /**
     * Starts a budget that runs out the given time from now.
     *
     * @param budgetNanos the total time of the call in nanoseconds, which must be positive
     * @return the deadline
     */
    public static CallDeadline startingNow(long budgetNanos) {
        return new CallDeadline(budgetNanos);
    }

    /**
     * Gets the time left in the budget.
     *
     * @return the remaining time in nanoseconds, which is not positive once the budget has run out
     */
    public long remainingNanos() {
        return expiryNanos - System.nanoTime();
    }

    public boolean hasExpired() {
        return remainingNanos() <= 0;
    }

    /**
     * Creates the failure that reports this budget running out.
     *
     * @return the failure
     */
    public CallTimeoutException timeoutFailure() {
        String seconds = BigDecimal.valueOf(budgetNanos, 9).stripTrailingZeros().toPlainString();
        return new CallTimeoutException(CALL_TIMEOUT_EXCEEDED + ": the call did not complete within " + seconds
                                                + " seconds", HttpResponseStatus.GATEWAY_TIMEOUT.code());
    }

    ScheduledFuture<?> schedule(Runnable task, long delayNanos) {
        return TIMER.schedule(task, Math.max(delayNanos, 0), TimeUnit.NANOSECONDS);
    }

    private static ScheduledThreadPoolExecutor createTimer() {
        ScheduledThreadPoolExecutor timer = new ScheduledThreadPoolExecutor(1, runnable -> {
            Thread thread = new Thread(runnable,
                                       "ballerina-http-call-deadline-" + TIMER_THREAD_COUNT.incrementAndGet());
            thread.setDaemon(true);
            return thread;
        });
        // A cancelled task is dropped at once, as nearly every call ends before its deadline
        timer.setRemoveOnCancelPolicy(true);
        return timer;
    }
}
