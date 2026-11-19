/*
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.contract.PortBindingEventListener;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.netty.channel.DefaultChannelPromise;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.util.concurrent.DefaultEventExecutor;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Tests that a start whose bind callback never runs, because the event loop was shut down, fails instead of hanging.
 */
public class HttpWsServerConnectorFutureHandoverTest {

    @Test(timeOut = 30000, description = "sync() fails when the event loop terminates before the bind callback runs")
    public void testSyncFailsWhenTheEventLoopIsShutDownBeforeTheHandover() throws Exception {
        EmbeddedChannel channel = new EmbeddedChannel();
        DefaultChannelPromise bindFuture = new DefaultChannelPromise(channel);
        bindFuture.setSuccess();
        HttpWsServerConnectorFuture future = new HttpWsServerConnectorFuture(bindFuture);
        future.setHandoverLatch(new CountDownLatch(1));
        AtomicReference<Throwable> reportedError = new AtomicReference<>();
        future.setPortBindingEventListener(new PortBindingEventListener() {
            @Override
            public void onOpen(String serverConnectorId, boolean isHttps) {
            }

            @Override
            public void onClose(String serverConnectorId, boolean isHttps) {
            }

            @Override
            public void onError(Throwable throwable) {
                reportedError.set(throwable);
            }
        });

        // The event loop is shut down, so Netty never runs the bind callback that would count the latch down.
        DefaultEventExecutor eventLoop = new DefaultEventExecutor();
        eventLoop.shutdownGracefully(0, 0, TimeUnit.MILLISECONDS).sync();
        future.failHandoverOnTermination(eventLoop);

        CompletableFuture<Void> sync = CompletableFuture.runAsync(() -> {
            try {
                future.sync();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(e);
            }
        });
        try {
            sync.get(20, TimeUnit.SECONDS);
            Assert.fail("The start must fail when the event loop was shut down before the handover");
        } catch (ExecutionException e) {
            Assert.assertTrue(e.getCause() instanceof ServerConnectorException, String.valueOf(e.getCause()));
        }
        Assert.assertTrue(reportedError.get() instanceof ServerConnectorException);
        Assert.assertFalse(future.claimHandover(), "The handover must stay claimed by the failure");
        channel.finishAndReleaseAll();
    }

    @Test(timeOut = 30000, description = "A handover that already ran is not failed by a later termination")
    public void testHandoverThatRanIsNotFailedByTheTermination() throws Exception {
        EmbeddedChannel channel = new EmbeddedChannel();
        DefaultChannelPromise bindFuture = new DefaultChannelPromise(channel);
        bindFuture.setSuccess();
        HttpWsServerConnectorFuture future = new HttpWsServerConnectorFuture(bindFuture);
        CountDownLatch latch = new CountDownLatch(1);
        future.setHandoverLatch(latch);

        DefaultEventExecutor eventLoop = new DefaultEventExecutor();
        future.failHandoverOnTermination(eventLoop);
        Assert.assertTrue(future.claimHandover());
        latch.countDown();
        eventLoop.shutdownGracefully(0, 0, TimeUnit.MILLISECONDS).sync();

        future.sync();
        channel.finishAndReleaseAll();
    }
}
