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

package io.ballerina.stdlib.http.transport.contractimpl.common;

import io.ballerina.stdlib.http.transport.message.BackPressureListener;
import io.ballerina.stdlib.http.transport.message.BackPressureObservable;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.WriteBufferWaterMark;
import io.netty.channel.embedded.EmbeddedChannel;
import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertThrows;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that an HTTP/1.1 writer checks its channel's writability under the lock that a writability change takes
 * to resume, so a stale check cannot pause after that resume.
 */
public class Http1BackPressureCheckTest {

    @Test(timeOut = 30000)
    public void testCheckWaitsForAWritabilityChangeInProgress() throws Exception {
        BackPressureHandler backPressureHandler = new BackPressureHandler();
        EmbeddedChannel channel = new EmbeddedChannel(backPressureHandler);
        try {
            channel.config().setWriteBufferWaterMark(new WriteBufferWaterMark(1, 2));
            channel.write(Unpooled.wrappedBuffer(new byte[8]));
            assertFalse(channel.isWritable());
            ChannelHandlerContext context = channel.pipeline().context(backPressureHandler);
            BackPressureObservable observable = backPressureHandler.getBackPressureObservable();
            AtomicInteger pauses = new AtomicInteger();
            observable.setListener(new BackPressureListener() {
                @Override
                public void onUnWritable() {
                    pauses.incrementAndGet();
                }

                @Override
                public void onWritable() {
                    // Resuming is not counted; only a pause after the channel became writable would be wrong.
                }
            });

            CompletableFuture<Void> check;
            synchronized (observable) {
                check = CompletableFuture.runAsync(() -> Util.checkUnWritabilityAndNotify(context,
                                                                                           backPressureHandler));
                assertThrows(TimeoutException.class, () -> check.get(200, TimeUnit.MILLISECONDS));
                channel.flush();
                assertTrue(channel.isWritable());
            }
            check.get(5, TimeUnit.SECONDS);

            assertEquals(pauses.get(), 0, "The writer paused after the channel had become writable");
        } finally {
            channel.finishAndReleaseAll();
        }
    }
}
