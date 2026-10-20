/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.message;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BooleanSupplier;

/**
 * Default implementation of the {@link BackPressureObservable}.
 */
public class DefaultBackPressureObservable implements BackPressureObservable {

    private static final Logger LOG = LoggerFactory.getLogger(DefaultBackPressureObservable.class);

    private volatile BackPressureListener listener;
    private final AtomicBoolean unWritable = new AtomicBoolean();

    // A paused listener being replaced belongs to a finished message, such as the previous request on a keep-alive
    // connection, so it is resumed rather than left with its inbound channel suspended.
    @Override
    public synchronized void setListener(BackPressureListener listener) {
        BackPressureListener previous = this.listener;
        if (previous != null && previous != listener && unWritable.getAndSet(false)) {
            previous.onWritable();
        }
        this.listener = listener;
    }

    @Override
    public synchronized void removeListener() {
        if (listener != null) {
            unWritable.set(false);
            listener.onWritable();
            listener = null;
        }
    }

    // Not synchronized: a blocking listener waits here for notifyWritable(), which takes this monitor.
    @Override
    public void notifyUnWritable() {
        pause(listener);
    }

    private void pause(BackPressureListener currentListener) {
        if (currentListener != null) {
            unWritable.set(true);
            currentListener.onUnWritable();
        }
    }

    // A blocking listener is checked without the monitor (its semaphore keeps an earlier release); any other listener
    // is checked under it, so a stale check cannot pause after a writability change has resumed.
    @Override
    public void notifyUnWritableIfStreamUnwritable(BooleanSupplier streamWritable) {
        BackPressureListener currentListener = listener;
        if (currentListener == null || !currentListener.blocksWriter()) {
            synchronized (this) {
                currentListener = listener;
                if (currentListener == null || !currentListener.blocksWriter()) {
                    pauseIfStreamUnwritable(currentListener, streamWritable);
                    return;
                }
            }
        }
        pauseIfStreamUnwritable(currentListener, streamWritable);
    }

    private void pauseIfStreamUnwritable(BackPressureListener currentListener, BooleanSupplier streamWritable) {
        if (!streamWritable.getAsBoolean()) {
            if (LOG.isDebugEnabled()) {
                LOG.debug("In thread {}. Stream is not writable.", Thread.currentThread().getName());
            }
            pause(currentListener);
        }
    }

    @Override
    public synchronized void notifyWritable() {
        if (listener != null) {
            unWritable.set(false);
            listener.onWritable();
        }
    }

    @Override
    public synchronized void notifyWritableIfUnWritable() {
        BackPressureListener currentListener = listener;
        // A blocking writer checks writability without this monitor, so it may block just after this runs. Its
        // semaphore keeps the release, and an extra one is harmless once the stream is done.
        if (currentListener != null && (unWritable.compareAndSet(true, false) || currentListener.blocksWriter())) {
            currentListener.onWritable();
        }
    }

    @Override
    public synchronized void streamWritabilityChanged(StreamWritability stream, boolean writable) {
        stream.setStreamWritable(writable);
        if (writable) {
            notifyWritable();
        }
    }

    @Override
    public synchronized void streamFinished(StreamWritability stream) {
        stream.setStreamWritable(true);
        notifyWritableIfUnWritable();
    }

    @Override
    public synchronized BackPressureListener getListener() {
        return listener;
    }
}
