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

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Default implementation of the {@link BackPressureObservable}.
 */
public class DefaultBackPressureObservable implements BackPressureObservable {

    private volatile BackPressureListener listener;
    private final AtomicBoolean unWritable = new AtomicBoolean();

    @Override
    public void setListener(BackPressureListener listener) {
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

    // Not synchronized: DefaultBackPressureListener blocks the writer here until notifyWritable() releases it, and
    // that call takes this monitor. Callers whose listener does not block hold the monitor around the check instead.
    @Override
    public void notifyUnWritable() {
        if (listener != null) {
            unWritable.set(true);
            listener.onUnWritable();
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
        if (currentListener != null && unWritable.compareAndSet(true, false)) {
            currentListener.onWritable();
        }
    }

    @Override
    public BackPressureListener getListener() {
        return listener;
    }
}
