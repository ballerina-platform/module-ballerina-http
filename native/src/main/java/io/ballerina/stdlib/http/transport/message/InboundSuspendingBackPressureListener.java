/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.message;

/**
 * A {@link BackPressureListener} that suspends reading the inbound side of a passthrough while the outbound side is
 * unwritable. It acts only on a change, so a writable event does not resume reads that something else suspended.
 */
public abstract class InboundSuspendingBackPressureListener implements BackPressureListener {

    // Guarded by the observable that notifies this listener; read where the suspension is applied.
    private volatile boolean suspended;

    @Override
    public void onUnWritable() {
        if (!suspended) {
            suspended = true;
            applySuspension();
        }
    }

    @Override
    public void onWritable() {
        if (suspended) {
            suspended = false;
            applySuspension();
        }
    }

    protected boolean isSuspended() {
        return suspended;
    }

    /**
     * Applies the current {@link #isSuspended()} to the inbound side. Changes may be applied later than they were
     * made, so each application reads the latest decision rather than the one that scheduled it.
     */
    protected abstract void applySuspension();
}
