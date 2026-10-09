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
        Thread.sleep(200);

        CompletableFuture<Void> resume = CompletableFuture.runAsync(() -> {
            synchronized (observable) {
                observable.notifyWritable();
            }
        });
        resume.get(5, TimeUnit.SECONDS);
        blockedWriter.get(5, TimeUnit.SECONDS);
    }
}
