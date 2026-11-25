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
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.ScheduledFuture;

/**
 * One attempt of a call, from the moment its request is handed to the transport until the connection or the stream
 * it used is no longer tied to it. It is the only thing that can abort that attempt from the outside, which it
 * does for the call's total timeout and for a cancel by the caller.
 * <p>
 * The exchange ends when the connection goes back to the pool or the stream closes, not when the response is
 * returned, because the body of the response is read lazily and still belongs to the call. Once it has ended it can
 * no longer abort anything, so a timer that fires late cannot touch a connection another request has since taken.
 */
public final class CallExchange {

    private static final Logger LOG = LoggerFactory.getLogger(CallExchange.class);

    /**
     * Aborts what an exchange is bound to, which is a connection or a stream. The binding side makes sure the abort
     * only takes effect while the exchange still owns it.
     */
    public interface Aborter {

        /**
         * Aborts the exchange's connection or stream, so its response and its body fail with the given failure.
         *
         * @param failure the reason the exchange is aborted
         */
        void abort(Throwable failure);
    }

    private enum State {
        ACTIVE, ENDED, ABORTED
    }

    private final CallDeadline deadline;
    private final HttpCarbonMessage request;
    private final HttpResponseFuture responseFuture;
    // Guarded by this
    private State state = State.ACTIVE;
    private Aborter aborter;
    private Throwable failure;
    private ScheduledFuture<?> timer;

    private CallExchange(CallDeadline deadline, HttpCarbonMessage request, HttpResponseFuture responseFuture) {
        this.deadline = deadline;
        this.request = request;
        this.responseFuture = responseFuture;
    }

    /**
     * Gets the exchange of the request's latest attempt. The request message is shared by the attempts of a call and
     * by every use of a request object, so whatever deals with one particular attempt keeps hold of its exchange.
     *
     * @param request the outbound request
     * @return the exchange, or {@code null} if the attempt has no deadline and cannot be cancelled
     */
    public static CallExchange of(HttpCarbonMessage request) {
        Object exchange = request.getProperty(Constants.CALL_EXCHANGE);
        return exchange instanceof CallExchange ? (CallExchange) exchange : null;
    }

    /**
     * Starts the exchange of an attempt, if the request belongs to a call with a deadline or can be cancelled.
     * An attempt whose deadline has already run out is aborted at once.
     *
     * @param request        the outbound request
     * @param responseFuture the future the attempt's outcome is reported on
     * @return the exchange, or {@code null} if the attempt has no deadline and cannot be cancelled
     */
    public static CallExchange begin(HttpCarbonMessage request, HttpResponseFuture responseFuture) {
        request.removeProperty(Constants.CALL_EXCHANGE);
        Object deadlineProperty = request.getProperty(Constants.CALL_DEADLINE);
        CallDeadline deadline = deadlineProperty instanceof CallDeadline ? (CallDeadline) deadlineProperty : null;
        boolean cancellable = Boolean.TRUE.equals(request.getProperty(Constants.CALL_CANCELLABLE));
        if (deadline == null && !cancellable) {
            return null;
        }
        CallExchange exchange = new CallExchange(deadline, request, responseFuture);
        request.setProperty(Constants.CALL_EXCHANGE, exchange);
        if (deadline != null) {
            if (deadline.hasExpired()) {
                exchange.abort(deadline.timeoutFailure());
            } else {
                synchronized (exchange) {
                    exchange.timer = deadline.schedule(() -> exchange.abort(deadline.timeoutFailure()),
                                                       deadline.remainingNanos());
                }
            }
        }
        return exchange;
    }

    public boolean hasDeadline() {
        return deadline != null;
    }

    /**
     * Gets the time left in the call's budget.
     *
     * @return the remaining time in nanoseconds, which is {@link Long#MAX_VALUE} if the call has no deadline
     */
    public long remainingNanos() {
        return deadline == null ? Long.MAX_VALUE : deadline.remainingNanos();
    }

    public synchronized boolean isAborted() {
        return state == State.ABORTED;
    }

    /**
     * Gets the reason the exchange was aborted.
     *
     * @return the failure, or {@code null} if the exchange has not been aborted
     */
    public synchronized Throwable getFailure() {
        return failure;
    }

    /**
     * Reports the call's total timeout running out while the attempt waited for a connection and aborts the
     * attempt, if it has not ended already.
     *
     * @return the failure the attempt is aborted with
     */
    public ClientConnectorException abortOnTimeout() {
        if (deadline != null) {
            abort(deadline.timeoutFailure());
        }
        Throwable reason = getFailure();
        return reason instanceof ClientConnectorException ? (ClientConnectorException) reason :
                new CallTimeoutException(Constants.CALL_TIMEOUT_EXCEEDED, HttpResponseStatus.GATEWAY_TIMEOUT.code());
    }

    /**
     * Binds the exchange to the connection or stream that carries it, which the exchange aborts if it is aborted
     * from now on.
     *
     * @param aborter aborts the connection or stream
     * @return false if the exchange has already been aborted or ended, in which case nothing is bound and the caller
     * must not use the connection or stream for this attempt
     */
    public boolean bind(Aborter aborter) {
        synchronized (this) {
            if (state != State.ACTIVE) {
                return false;
            }
            this.aborter = aborter;
            return true;
        }
    }

    /**
     * Ends the exchange because its connection or stream is no longer tied to it. An ended exchange can no longer be
     * aborted.
     */
    public void end() {
        synchronized (this) {
            if (state == State.ACTIVE) {
                state = State.ENDED;
            }
            aborter = null;
            cancelTimer();
        }
    }

    /**
     * Aborts the exchange: the caller of the attempt gets the failure, and the connection or stream it is bound to
     * is closed or reset. Does nothing if the exchange has ended or been aborted already.
     *
     * @param reason the reason the exchange is aborted
     */
    public void abort(Throwable reason) {
        Aborter toAbort;
        synchronized (this) {
            if (state != State.ACTIVE) {
                return;
            }
            state = State.ABORTED;
            failure = reason;
            toAbort = aborter;
            aborter = null;
            cancelTimer();
        }
        // The caller is told first, so it hears this failure and not the one a closing connection reports
        responseFuture.notifyResponseHandle(reason);
        responseFuture.notifyHttpListener(reason);
        stopRequestBody(reason);
        if (toAbort != null) {
            try {
                toAbort.abort(reason);
            } catch (RuntimeException e) {
                LOG.warn("Failed to abort the exchange: {}", e.getMessage(), e);
            }
        }
    }

    // A request that gets no response any more may still be having its body written, which a body that comes from a
    // stream can take long over, and the call does not return until that ends. Failing the request message ends it at
    // the next content, and releases what is added to it from then on. Not done once the response has arrived, or when
    // the message already carries a later attempt.
    private void stopRequestBody(Throwable reason) {
        if (!responseFuture.isResponseReceived() && request.getProperty(Constants.CALL_EXCHANGE) == this) {
            request.setIoException(new IOException(reason.getMessage()));
        }
    }

    private void cancelTimer() {
        if (timer != null) {
            timer.cancel(false);
            timer = null;
        }
    }
}
