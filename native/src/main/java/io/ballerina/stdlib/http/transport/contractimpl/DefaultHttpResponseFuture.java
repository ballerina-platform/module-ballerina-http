/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.OutboundMsgHolder;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Semaphore;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Implementation of the response returnError future.
 */
public class DefaultHttpResponseFuture implements HttpResponseFuture {

    private static final Logger LOG = LoggerFactory.getLogger(HttpResponseFuture.class);

    private HttpConnectorListener httpConnectorListener;
    private HttpClientConnectorListener responseHandleListener;
    private HttpClientConnectorListener promiseAvailabilityListener;
    private HttpConnectorListener pushPromiseListener;
    private ConcurrentHashMap<Integer, HttpConnectorListener> pushResponseListeners;
    private ConcurrentHashMap<Integer, Throwable> pushResponseListenerErrors;
    private BackPressureHandler backPressureHandler;

    private HttpCarbonMessage httpCarbonMessage;
    private ResponseHandle responseHandle;
    private OutboundMsgHolder outboundMsgHolder;

    private Throwable throwable;
    private Throwable responseHandleError;
    private Throwable returnError;
    private Semaphore executionWaitSem;

    // Lock to synchronize response related operations
    private Lock responseLock = new ReentrantLock();
    // Lock to synchronize response handle related operations
    private Lock responseHandleLock = new ReentrantLock();
    // Lock to synchronize promise availability related operations
    private Lock promiseAvailabilityLock = new ReentrantLock();
    // Lock to synchronize promise related operations
    private Lock promiseLock = new ReentrantLock();
    // Lock to synchronize push response related operations
    private Lock pushResponseLock = new ReentrantLock();

    public DefaultHttpResponseFuture(OutboundMsgHolder outboundMsgHolder) {
        this.outboundMsgHolder = outboundMsgHolder;
        pushResponseListeners = new ConcurrentHashMap<>();
        pushResponseListenerErrors = new ConcurrentHashMap<>();
    }

    public DefaultHttpResponseFuture() {
        this(null);
    }

    @Override
    public void setHttpConnectorListener(HttpConnectorListener connectorListener) {
        responseLock.lock();
        try {
            this.httpConnectorListener = connectorListener;
            if (httpCarbonMessage != null) {
                notifyHttpListener(httpCarbonMessage);
                httpCarbonMessage = null;
            }
            if (this.throwable != null) {
                notifyHttpListener(this.throwable);
                this.throwable = null;
            }
        } finally {
            responseLock.unlock();
        }
    }

    @Override
    public void removeHttpListener() {
        this.httpConnectorListener = null;
    }

    @Override
    public void notifyHttpListener(HttpCarbonMessage httpCarbonMessage) {
        responseLock.lock();
        try {
            this.httpCarbonMessage = httpCarbonMessage;
            if (executionWaitSem != null) {
                executionWaitSem.release();
            }
            if (httpConnectorListener != null) {
                HttpConnectorListener listener = httpConnectorListener;
                removeHttpListener();
                listener.onMessage(httpCarbonMessage);
            }
        } finally {
            responseLock.unlock();
        }
    }

    @Override
    public void notifyHttpListener(Throwable throwable) {
        responseLock.lock();
        try {
            // For HTTP1.1 we have the listener attached to BackPressureObservable inside the BackPressureHandler.
            // Whereas for HTTP2 we have the listener attached to BackPressureObservable inside the OutboundMsgHolder.
            if (backPressureHandler != null) {
                backPressureHandler.getBackPressureObservable().removeListener();
            } else if (outboundMsgHolder != null) {
                outboundMsgHolder.getBackPressureObservable().removeListener();
            } else {
                LOG.warn("No BackPressureObservable found.");
            }
            this.throwable = throwable;
            returnError = throwable;
            if (executionWaitSem != null) {
                executionWaitSem.release();
            }
            if (httpConnectorListener != null) {
                HttpConnectorListener listener = httpConnectorListener;
                removeHttpListener();
                listener.onError(throwable);
            } else if (responseHandleListener != null) {
                HttpClientConnectorListener listener = responseHandleListener;
                removeResponseHandleListener();
                responseHandleError = null;
                listener.onError(throwable);
            }
        } finally {
            responseLock.unlock();
        }
    }

    public HttpResponseFuture sync() throws InterruptedException {
        // sync operation is not synchronized with locks as it might cause a deadlock.
        // We may have to refactor this using conditions in ReentrantLock later.
        executionWaitSem = new Semaphore(0);
        if (this.httpCarbonMessage == null && this.throwable == null && this.returnError == null) {
            executionWaitSem.acquire();
        }
        if (httpCarbonMessage != null) {
            returnError = null;
            httpCarbonMessage = null;
        }
        if (throwable != null) {
            returnError = throwable;
            throwable = null;
        }
        return this;
    }

    public DefaultOperationStatus getStatus() {
        return this.returnError != null ? new DefaultOperationStatus(this.returnError)
                                        : new DefaultOperationStatus(null);
    }

    public void resetStatus() {
        this.returnError = null;
    }

    public void setBackPressureHandler(BackPressureHandler backPressureHandler) {
        this.backPressureHandler = backPressureHandler;
    }

    @Override
    public void setResponseHandleListener(HttpClientConnectorListener responseHandleListener) {
        responseHandleLock.lock();
        try {
            this.responseHandleListener = responseHandleListener;
            if (responseHandle != null) {
                notifyResponseHandle(responseHandle);
                responseHandle = null;
            }
            if (responseHandleError != null) {
                notifyResponseHandle(responseHandleError);
                this.responseHandleError = null;
            }
        } finally {
            responseHandleLock.unlock();
        }
    }

    @Override
    public void removeResponseHandleListener() {
        this.responseHandleListener = null;
    }

    @Override
    public void notifyResponseHandle(ResponseHandle responseHandle) {
        responseHandleLock.lock();
        try {
            this.responseHandle = responseHandle;
            if (responseHandleListener != null) {
                HttpClientConnectorListener listener = responseHandleListener;
                removeResponseHandleListener();
                this.responseHandle = null;
                listener.onResponseHandle(responseHandle);
            }
        } finally {
            responseHandleLock.unlock();
        }
    }

    @Override
    public void notifyResponseHandle(Throwable throwable) {
        responseHandleLock.lock();
        try {
            responseHandleError = throwable;
            if (responseHandleListener != null) {
                HttpClientConnectorListener listener = responseHandleListener;
                removeResponseHandleListener();
                responseHandleError = null;
                listener.onError(throwable);
            }
        } finally {
            responseHandleLock.unlock();
        }
    }

    @Override
    public void setPromiseAvailabilityListener(HttpClientConnectorListener promiseAvailabilityListener) {
        promiseAvailabilityLock.lock();
        try {
            this.promiseAvailabilityListener = promiseAvailabilityListener;
            notifyPromiseAvailability();
        } finally {
            promiseAvailabilityLock.unlock();
        }
    }

    @Override
    public void removePromiseAvailabilityListener() {
        this.promiseAvailabilityListener = null;
    }

    @Override
    public void notifyPromiseAvailability() {
        promiseAvailabilityLock.lock();
        try {
            if (promiseAvailabilityListener != null) {
                HttpClientConnectorListener listener = promiseAvailabilityListener;
                if (outboundMsgHolder.hasPromise()) {
                    removePromiseAvailabilityListener();
                    listener.onPushPromiseAvailability(true);
                } else if (outboundMsgHolder.isAllPromisesReceived()) {
                    removePromiseAvailabilityListener();
                    listener.onPushPromiseAvailability(false);
                }
            }
        } finally {
            promiseAvailabilityLock.unlock();
        }
    }

    @Override
    public void setPushPromiseListener(HttpConnectorListener pushPromiseListener) {
        promiseLock.lock();
        try {
            this.pushPromiseListener = pushPromiseListener;
            if (outboundMsgHolder.hasPromise()) {
                notifyPushPromise();
            }
        } finally {
            promiseLock.unlock();
        }
    }

    @Override
    public void removePushPromiseListener() {
        this.pushPromiseListener = null;
    }

    @Override
    public void notifyPushPromise() {
        promiseLock.lock();
        try {
            if (pushPromiseListener != null) {
                HttpConnectorListener listener = pushPromiseListener;
                removePushPromiseListener();
                listener.onPushPromise(outboundMsgHolder.getNextPromise());
            }
        } finally {
            promiseLock.unlock();
        }
    }

    @Override
    public void setPushResponseListener(HttpConnectorListener pushResponseListener, int promiseId) {
        pushResponseLock.lock();
        try {
            pushResponseListeners.put(promiseId, pushResponseListener);
            HttpCarbonMessage pushResponse = outboundMsgHolder.getPushResponse(promiseId);
            if (pushResponse != null) {
                notifyPushResponse(promiseId, pushResponse);
            }
            if (pushResponseListenerErrors.get(promiseId) != null) {
                notifyPushResponse(promiseId, pushResponseListenerErrors.get(promiseId));
            }
        } finally {
            pushResponseLock.unlock();
        }
    }

    @Override
    public void removePushResponseListener(int promisedId) {
        this.pushResponseListeners.remove(promisedId);
    }

    @Override
    public void notifyPushResponse(int streamId, HttpCarbonMessage pushResponse) {
        pushResponseLock.lock();
        try {
            HttpConnectorListener listener = pushResponseListeners.get(streamId);
            if (listener != null) {
                pushResponseListeners.remove(streamId);
                listener.onPushResponse(streamId, pushResponse);
            }
        } finally {
            pushResponseLock.unlock();
        }
    }

    @Override
    public void notifyPushResponse(int streamId, Throwable throwable) {
        pushResponseLock.lock();
        try {
            pushResponseListenerErrors.put(streamId, throwable);
            HttpConnectorListener listener = pushResponseListeners.get(streamId);
            if (listener != null) {
                pushResponseListeners.remove(streamId);
                pushResponseListenerErrors.remove(streamId);
                listener.onError(throwable);
            }
        } finally {
            pushResponseLock.unlock();
        }
    }
}
