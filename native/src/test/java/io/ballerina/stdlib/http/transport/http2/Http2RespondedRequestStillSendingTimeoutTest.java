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

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.MultiThreadIoEventLoopGroup;
import io.netty.channel.nio.NioIoHandler;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.DefaultHttp2HeadersFrame;
import io.netty.handler.codec.http2.Http2DataFrame;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2FrameCodecBuilder;
import io.netty.handler.codec.http2.Http2FrameStream;
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.handler.codec.http2.Http2ResetFrame;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.io.UncheckedIOException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that a request still being sent after its response ended is timed out when the peer stops reading it.
 */
public class Http2RespondedRequestStillSendingTimeoutTest {

    private static final int CHUNK_SIZE = 16 * 1024;
    // The response comes well after the writer pauses and well before the idle timeout, so the request times out
    // only once its response has ended.
    private static final int IDLE_TIMEOUT_MILLIS = 3000;
    private static final int RESPONSE_DELAY_MILLIS = 500;

    private final CountDownLatch requestHeadersReceived = new CountDownLatch(1);
    private final Semaphore dataFramesReceived = new Semaphore(0);
    private final CompletableFuture<Long> resetErrorCode = new CompletableFuture<>();
    private EventLoopGroup serverGroup;
    private Channel serverChannel;
    private HttpWsConnectorFactory connectorFactory;

    @Test(timeOut = 60000)
    public void testStalledRequestIsTimedOutAfterItsResponseEnded() throws Exception {
        Util.setMaxBackPressureStallTime(1);
        startBackend();
        HttpClientConnector client = createClient();
        HttpCarbonMessage request = createRequest();
        request.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[CHUNK_SIZE])));

        CountDownLatch responded = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(responded);
        client.send(request).setHttpConnectorListener(listener);
        assertTrue(requestHeadersReceived.await(10, TimeUnit.SECONDS), "The request never reached the backend");

        CompletableFuture<String> writer = CompletableFuture.supplyAsync(() -> {
            try {
                // Paced by the backend receiving each chunk until the window is used up, so the stream has turned
                // unwritable before the writer adds the chunk it pauses on.
                boolean windowOpen = true;
                for (int i = 0; i < 256; i++) {
                    request.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[CHUNK_SIZE])));
                    if (windowOpen) {
                        windowOpen = dataFramesReceived.tryAcquire(100, TimeUnit.MILLISECONDS);
                    }
                }
                return "the whole body was accepted";
            } catch (UncheckedIOException e) {
                return e.getCause().getMessage();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return "interrupted";
            }
        });

        assertTrue(responded.await(10, TimeUnit.SECONDS), "The backend's response never arrived");
        assertNotNull(listener.getHttpResponseMessage(), "Expected a response, got " + listener.getHttpErrorMessage());
        assertEquals(writer.get(20, TimeUnit.SECONDS),
                     Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_REQUEST_BODY);
        assertEquals(resetErrorCode.get(10, TimeUnit.SECONDS).longValue(), Http2Error.CANCEL.code(),
                     "The timed-out stream was not reset with CANCEL");
    }

    private HttpClientConnector createClient() {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        senderConfiguration.setSocketIdleTimeout(IDLE_TIMEOUT_MILLIS);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(new TransportsConfiguration()), senderConfiguration);
    }

    private void startBackend() throws InterruptedException {
        serverGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        serverChannel = new ServerBootstrap()
                .group(serverGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ch.pipeline().addLast(Http2FrameCodecBuilder.forServer().build(),
                                              new RespondOnceTheWindowIsUsedUp(requestHeadersReceived,
                                                                               dataFramesReceived, resetErrorCode));
                    }
                })
                .bind(HTTP_SERVER_PORT).sync().channel();
    }

    private static HttpCarbonMessage createRequest() {
        String uri = String.format("http://%s:%d", TestUtil.TEST_HOST, HTTP_SERVER_PORT);
        HttpCarbonMessage request = new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1,
                                                                                 HttpMethod.POST, uri));
        request.setHttpMethod(HttpMethod.POST.toString());
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.HTTP_PORT, HTTP_SERVER_PORT);
        request.setHeader(TestUtil.HOST, TestUtil.TEST_HOST + ":" + HTTP_SERVER_PORT);
        return request;
    }

    @AfterMethod(alwaysRun = true)
    public void cleanUp() throws InterruptedException {
        Util.setMaxBackPressureStallTime(Util.DEFAULT_MAX_BACK_PRESSURE_STALL_TIME);
        if (connectorFactory != null) {
            connectorFactory.shutdown();
        }
        if (serverChannel != null) {
            serverChannel.close().sync();
        }
        if (serverGroup != null) {
            serverGroup.shutdownGracefully(0, 1, TimeUnit.SECONDS).sync();
        }
    }

    /**
     * Never returns flow-control window for the request body, and sends a complete response shortly after the
     * stream's initial window has been used up, so the client's writer is already paused when the response ends.
     * Records the error code of the client's reset.
     */
    private static final class RespondOnceTheWindowIsUsedUp extends ChannelInboundHandlerAdapter {
        private final CountDownLatch requestHeadersReceived;
        private final Semaphore dataFramesReceived;
        private final CompletableFuture<Long> resetErrorCode;
        private int received;
        private boolean responded;

        RespondOnceTheWindowIsUsedUp(CountDownLatch requestHeadersReceived, Semaphore dataFramesReceived,
                                     CompletableFuture<Long> resetErrorCode) {
            this.requestHeadersReceived = requestHeadersReceived;
            this.dataFramesReceived = dataFramesReceived;
            this.resetErrorCode = resetErrorCode;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof Http2HeadersFrame) {
                requestHeadersReceived.countDown();
            } else if (msg instanceof Http2ResetFrame resetFrame) {
                resetErrorCode.complete(resetFrame.errorCode());
            } else if (msg instanceof Http2DataFrame dataFrame) {
                received += dataFrame.content().readableBytes();
                dataFramesReceived.release();
                if (!responded && received >= 65535) {
                    responded = true;
                    // Delayed so the client's writer has paused on the shut window before the response ends.
                    Http2FrameStream stream = dataFrame.stream();
                    ctx.executor().schedule(() -> ctx.writeAndFlush(
                            new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("413"), true).stream(stream)),
                                            RESPONSE_DELAY_MILLIS, TimeUnit.MILLISECONDS);
                }
            }
            ReferenceCountUtil.release(msg);
        }
    }
}
