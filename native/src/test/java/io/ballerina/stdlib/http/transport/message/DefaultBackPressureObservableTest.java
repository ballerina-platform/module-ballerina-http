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

import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertThrows;

/**
 * Tests the locking of {@link DefaultBackPressureObservable} with a listener that blocks the writer.
 */
public class DefaultBackPressureObservableTest {

    // A writability change takes the observable's monitor to update the stream flag and resume, so a writer blocked
    // by DefaultBackPressureListener must not hold that monitor, or neither side can proceed.
    @Test(timeOut = 30000)
    public void testBlockedWriterDoesNotHoldTheLockAResumeTakes() throws Exception {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        observable.setListener(new DefaultBackPressureListener());

        CompletableFuture<Void> blockedWriter = CompletableFuture.runAsync(observable::notifyUnWritable);
        assertThrows(TimeoutException.class, () -> blockedWriter.get(200, TimeUnit.MILLISECONDS));

        CompletableFuture<Void> resume = CompletableFuture.runAsync(() -> {
            synchronized (observable) {
                observable.notifyWritable();
            }
        });
        resume.get(5, TimeUnit.SECONDS);
        blockedWriter.get(5, TimeUnit.SECONDS);
    }

    // The writer checks writability without the monitor, so the stream can finish before it blocks.
    @Test(timeOut = 30000)
    public void testWriterThatBlocksAfterTheStreamFinishedIsReleased() throws Exception {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        observable.setListener(new DefaultBackPressureListener());

        observable.notifyWritableIfUnWritable();
        CompletableFuture.runAsync(observable::notifyUnWritable).get(5, TimeUnit.SECONDS);
    }

    // A writability change updates the flag and resumes under the observable's monitor. A writer that read the flag
    // before that update must not pause after the resume, or nothing would resume it again.
    @Test(timeOut = 30000)
    public void testCheckWaitsForAWritabilityChangeInProgress() throws Exception {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        AtomicInteger pauses = new AtomicInteger();
        observable.setListener(new BackPressureListener() {
            @Override
            public void onUnWritable() {
                pauses.incrementAndGet();
            }

            @Override
            public void onWritable() {
                // Resuming is not counted; only a pause after the stream became writable would be wrong.
            }
        });
        AtomicBoolean streamWritable = new AtomicBoolean(false);

        CompletableFuture<Void> check;
        synchronized (observable) {
            check = CompletableFuture.runAsync(
                    () -> observable.notifyUnWritableIfStreamUnwritable(streamWritable::get));
            assertThrows(TimeoutException.class, () -> check.get(200, TimeUnit.MILLISECONDS));
            streamWritable.set(true);
            observable.notifyWritable();
        }
        check.get(5, TimeUnit.SECONDS);

        assertEquals(pauses.get(), 0, "The writer paused after the stream had become writable");
    }
}
