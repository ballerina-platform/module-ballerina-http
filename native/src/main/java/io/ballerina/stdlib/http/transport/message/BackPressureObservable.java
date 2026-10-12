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

import java.util.function.BooleanSupplier;

/**
 * Allows listeners to register and get notified.
 */
public interface BackPressureObservable {

    /**
     * Set listener interested for message events.
     * @param listener for message
     */
    void setListener(BackPressureListener listener);

    /**
     * Remove listener from the observable.
     */
    void removeListener();

    /**
     * Notify to start throttling.
     */
    void notifyUnWritable();

    /**
     * Notify to start throttling if the stream the message is written to is not writable.
     *
     * @param streamWritable reports whether the stream is currently writable
     */
    void notifyUnWritableIfStreamUnwritable(BooleanSupplier streamWritable);

    /**
     * Notify to release throttling.
     */
    void notifyWritable();

    /**
     * Release throttling if the last notification was {@link #notifyUnWritable()}. Used once the writer can no
     * longer report writability, so a pause it started is not left in place.
     */
    void notifyWritableIfUnWritable();

    /**
     * Record a writability change of the stream under the lock that
     * {@link #notifyUnWritableIfStreamUnwritable(BooleanSupplier)} checks it with, and release throttling when the
     * stream becomes writable.
     *
     * @param stream   the stream whose writability changed
     * @param writable whether the stream is now writable
     */
    void streamWritabilityChanged(StreamWritability stream, boolean writable);

    /**
     * Mark a finished stream writable and release throttling it started, as it never reports writability again.
     * Marking it writable stops a chunk still on its way from starting throttling again with nothing to release it.
     *
     * @param stream the stream that finished
     */
    void streamFinished(StreamWritability stream);

    /**
     * Get the registered listener.
     *
     * @return backpressure listener
     */
    BackPressureListener getListener();
}
