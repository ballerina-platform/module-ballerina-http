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
import static org.testng.Assert.assertFalse;
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

        CompletableFuture<Void> blockedWriter = CompletableFuture.runAsync(
                () -> observable.notifyUnWritableIfStreamUnwritable(() -> false));
        assertThrows(TimeoutException.class, () -> blockedWriter.get(200, TimeUnit.MILLISECONDS));

        CompletableFuture<Void> resume = CompletableFuture.runAsync(() -> {
            synchronized (observable) {
                observable.notifyWritable();
            }
        });
        resume.get(5, TimeUnit.SECONDS);
        blockedWriter.get(5, TimeUnit.SECONDS);
    }

    // A blocking listener replaced while its writer is about to pause belongs to a finished message, so the writer
    // must not be left blocked on it.
    @Test(timeOut = 30000)
    public void testWriterOfAReplacedBlockingListenerIsNotLeftBlocked() throws Exception {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        observable.setListener(new DefaultBackPressureListener());
        BackPressureListener nextListener = new BackPressureListener() {
            @Override
            public void onUnWritable() {
            }

            @Override
            public void onWritable() {
            }
        };

        CompletableFuture.runAsync(() -> observable.notifyUnWritableIfStreamUnwritable(() -> {
            observable.setListener(nextListener);
            return false;
        })).get(5, TimeUnit.SECONDS);
    }

    @Test
    public void testReplacingAPausedListenerResumesIt() {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        AtomicBoolean previousPaused = new AtomicBoolean();
        observable.setListener(new BackPressureListener() {
            @Override
            public void onUnWritable() {
                previousPaused.set(true);
            }

            @Override
            public void onWritable() {
                previousPaused.set(false);
            }
        });
        observable.notifyUnWritableIfStreamUnwritable(() -> false);

        observable.setListener(new DefaultBackPressureListener());

        assertFalse(previousPaused.get(), "The replaced listener was left paused");
    }

    // A chunk still on its way when the stream finishes must not pause, as nothing would resume it.
    @Test(timeOut = 30000)
    public void testWriterDoesNotPauseAfterTheStreamFinished() throws Exception {
        DefaultBackPressureObservable observable = new DefaultBackPressureObservable();
        observable.setListener(new DefaultBackPressureListener());

        AtomicBoolean writable = new AtomicBoolean(false);
        StreamWritability stream = new StreamWritability() {
            @Override
            public boolean isStreamWritable() {
                return writable.get();
            }

            @Override
            public void setStreamWritable(boolean streamWritable) {
                writable.set(streamWritable);
            }
        };

        observable.streamFinished(stream);
        CompletableFuture.runAsync(() -> observable.notifyUnWritableIfStreamUnwritable(stream::isStreamWritable))
                .get(5, TimeUnit.SECONDS);
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
