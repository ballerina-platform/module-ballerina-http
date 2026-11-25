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
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.listener.ServerConnectorBootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFactory;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.DefaultChannelPromise;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.util.concurrent.DefaultEventExecutor;
import io.netty.util.concurrent.EventExecutor;
import io.netty.util.concurrent.Future;
import io.netty.util.concurrent.GenericFutureListener;
import io.netty.util.concurrent.GlobalEventExecutor;
import org.mockito.ArgumentCaptor;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.lang.reflect.Field;
import java.net.ServerSocket;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

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

    @Test(timeOut = 30000, description = "A finished start does not stay registered on the event loop")
    @SuppressWarnings("unchecked")
    public void testTerminationListenerIsReleased() {
        EventExecutor eventLoop = mock(EventExecutor.class);
        Future<Object> terminationFuture = mock(Future.class);
        doReturn(terminationFuture).when(eventLoop).terminationFuture();
        HttpWsServerConnectorFuture future = new HttpWsServerConnectorFuture();

        future.failHandoverOnTermination(eventLoop);
        future.releaseTerminationListener();

        ArgumentCaptor<GenericFutureListener<Future<Object>>> added =
                ArgumentCaptor.forClass(GenericFutureListener.class);
        ArgumentCaptor<GenericFutureListener<Future<Object>>> removed =
                ArgumentCaptor.forClass(GenericFutureListener.class);
        verify(terminationFuture).addListener(added.capture());
        verify(terminationFuture).removeListener(removed.capture());
        Assert.assertSame(removed.getValue(), added.getValue());
    }

    @Test(timeOut = 30000, description = "A start cancelled while the port is being bound leaves the port closed")
    public void testStartCancelledDuringTheBindClosesThePort() throws Exception {
        NioEventLoopGroup bossGroup = new NioEventLoopGroup(1);
        NioEventLoopGroup workerGroup = new NioEventLoopGroup(1);
        CountDownLatch bossBlocked = new CountDownLatch(1);
        try {
            ServerConnectorBootstrap bootstrap =
                    new ServerConnectorBootstrap(new DefaultChannelGroup(GlobalEventExecutor.INSTANCE));
            bootstrap.addThreadPools(bossGroup, workerGroup);
            int port;
            try (ServerSocket probe = new ServerSocket(0)) {
                port = probe.getLocalPort();
            }
            // Keeps the bind pending until the start has been cancelled
            bossGroup.execute(() -> {
                try {
                    bossBlocked.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            HttpWsServerConnectorFuture future =
                    (HttpWsServerConnectorFuture) bootstrap.getServerConnector("localhost", port).start();

            Assert.assertEquals(future.cancelStart(), HttpWsServerConnectorFuture.CancelResult.CANCELLED);
            bossBlocked.countDown();

            Assert.assertThrows(ServerConnectorException.class, future::sync);
            // The channel is closed on the boss event loop, so wait for the tasks queued on it to run
            bossGroup.submit(() -> { }).sync();
            try (ServerSocket socket = new ServerSocket(port)) {
                Assert.assertTrue(socket.isBound());
            }
        } finally {
            bossBlocked.countDown();
            bossGroup.shutdownGracefully(0, 0, TimeUnit.MILLISECONDS).sync();
            workerGroup.shutdownGracefully(0, 0, TimeUnit.MILLISECONDS).sync();
        }
    }

    @Test(timeOut = 30000, description = "A bind failing before the channel is registered is reported by sync()")
    public void testBindFailureBeforeRegistrationIsReported() throws Exception {
        NioEventLoopGroup group = new NioEventLoopGroup(1);
        try {
            ServerConnectorBootstrap bootstrap =
                    new ServerConnectorBootstrap(new DefaultChannelGroup(GlobalEventExecutor.INSTANCE));
            bootstrap.addThreadPools(group, group);
            Field serverBootstrapField = ServerConnectorBootstrap.class.getDeclaredField("serverBootstrap");
            serverBootstrapField.setAccessible(true);
            ServerBootstrap serverBootstrap = new ServerBootstrap().group(group)
                    .channelFactory((ChannelFactory<NioServerSocketChannel>) () -> {
                        throw new IllegalArgumentException("Too many open files");
                    })
                    .childHandler(new ChannelInboundHandlerAdapter());
            serverBootstrapField.set(bootstrap, serverBootstrap);

            ServerConnectorFuture future = bootstrap.getServerConnector("localhost", 0).start();

            Throwable failure = Assert.expectThrows(Throwable.class, future::sync);
            Assert.assertTrue(String.valueOf(failure.getCause()).contains("Too many open files")
                    || String.valueOf(failure).contains("Too many open files"), String.valueOf(failure));
        } finally {
            group.shutdownGracefully(0, 0, TimeUnit.MILLISECONDS).sync();
        }
    }
}
