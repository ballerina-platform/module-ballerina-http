/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contract.CallDeadline;
import io.ballerina.stdlib.http.transport.contract.CallExchange;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.CallCancelledException;
import io.ballerina.stdlib.http.transport.contract.exceptions.CallTimeoutException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
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
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.DefaultHttp2DataFrame;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.DefaultHttp2HeadersFrame;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2FrameCodecBuilder;
import io.netty.handler.codec.http2.Http2FrameStream;
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.handler.codec.http2.Http2ResetFrame;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that the total timeout of an HTTP/2 call, and a cancel by the caller, reset the stream of the exchange with
 * {@code CANCEL} and leave the connection, and so the other streams on it, alone.
 */
public class Http2CallDeadlineTestCase {

    // Long enough that the idle timeout never fires first, so any failure within a test is from the deadline
    private static final int IDLE_TIMEOUT_MILLIS = 60000;
    private static final long DEADLINE_MILLIS = 1000;

    // Each test gets its own, as the instance is shared by the tests of the class
    private CopyOnWriteArrayList<Long> resetErrorCodes;
    private CountDownLatch firstStreamReset;
    private CountDownLatch firstRequestReceived;
    private AtomicInteger connections;
    private AtomicInteger requests;
    private EventLoopGroup serverGroup;
    private Channel serverChannel;
    private HttpWsConnectorFactory connectorFactory;
    private HttpClientConnector client;

    @BeforeMethod
    public void setUp() {
        resetErrorCodes = new CopyOnWriteArrayList<>();
        firstStreamReset = new CountDownLatch(1);
        firstRequestReceived = new CountDownLatch(1);
        connections = new AtomicInteger();
        requests = new AtomicInteger();
    }

    @AfterMethod(alwaysRun = true)
    public void cleanUp() throws InterruptedException {
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

    @Test(timeOut = 60000)
    public void testDeadlineResetsTheStreamAndLeavesTheConnectionForTheNextCall() throws Exception {
        // The first stream is never answered, and the second one is
        startBackend(false);
        client = createClient();

        long start = System.nanoTime();
        DefaultHttpConnectorListener first = send(withDeadline(newRequest(), DEADLINE_MILLIS));
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
        assertTrue(first.getHttpErrorMessage() instanceof CallTimeoutException,
                   "Expected a CallTimeoutException but got " + first.getHttpErrorMessage());
        assertTrue(first.getHttpErrorMessage().getMessage().startsWith(Constants.CALL_TIMEOUT_EXCEEDED));
        assertTrue(elapsedMillis < DEADLINE_MILLIS + 4000, "The call failed after " + elapsedMillis + " ms");
        assertTrue(firstStreamReset.await(10, TimeUnit.SECONDS), "The stream was not reset");
        assertEquals(resetErrorCodes.get(0).longValue(), Http2Error.CANCEL.code(),
                     "The stream was not reset with CANCEL");

        DefaultHttpConnectorListener second = send(newRequest());
        assertNull(second.getHttpErrorMessage(), "The next call failed: " + second.getHttpErrorMessage());
        assertNotNull(second.getHttpResponseMessage());
        assertEquals(connections.get(), 1, "The connection was not kept for the next call");
    }

    @Test(timeOut = 60000)
    public void testDeadlineCoversTheBodyReadAfterTheResponseIsReturned() throws Exception {
        // The response starts and then stalls part-way through its body
        startBackend(true);
        client = createClient();

        DefaultHttpConnectorListener listener = send(withDeadline(newRequest(), DEADLINE_MILLIS));
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "The response did not arrive: " + listener.getHttpErrorMessage());

        long start = System.nanoTime();
        Throwable failure = readBodyFailure(response);
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);

        assertNotNull(failure, "The body ended without failing");
        assertTrue(messageOf(failure).startsWith(Constants.CALL_TIMEOUT_EXCEEDED),
                   "The body failed with: " + messageOf(failure));
        assertTrue(elapsedMillis < 10000, "The body read ended after " + elapsedMillis + " ms");
        assertTrue(firstStreamReset.await(10, TimeUnit.SECONDS), "The stream was not reset");
        assertEquals(resetErrorCodes.get(0).longValue(), Http2Error.CANCEL.code());
    }

    @Test(timeOut = 60000)
    public void testCancelResetsTheStream() throws Exception {
        startBackend(false);
        client = createClient();
        HttpCarbonMessage request = newRequest();
        request.setProperty(Constants.CALL_CANCELLABLE, true);

        CompletableFuture<ResponseHandle> handle = new CompletableFuture<>();
        HttpResponseFuture future = client.send(request);
        future.setResponseHandleListener(new HttpClientConnectorListener() {
            @Override
            public void onResponseHandle(ResponseHandle responseHandle) {
                handle.complete(responseHandle);
            }

            @Override
            public void onError(Throwable throwable) {
                handle.completeExceptionally(throwable);
            }
        });
        ResponseHandle responseHandle = handle.get(10, TimeUnit.SECONDS);
        assertTrue(firstRequestReceived.await(10, TimeUnit.SECONDS), "The request did not arrive");

        CountDownLatch done = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        client.getResponse(responseHandle).setHttpConnectorListener(listener);
        CallExchange.of(responseHandle.getOutboundMsgHolder().getRequest())
                .abort(new CallCancelledException(Constants.CALL_CANCELLED, -1));

        assertTrue(done.await(10, TimeUnit.SECONDS), "The cancelled call did not complete");
        assertTrue(listener.getHttpErrorMessage() instanceof CallCancelledException,
                   "Expected a CallCancelledException but got " + listener.getHttpErrorMessage());
        assertTrue(firstStreamReset.await(10, TimeUnit.SECONDS), "The stream was not reset");
        assertEquals(resetErrorCodes.get(0).longValue(), Http2Error.CANCEL.code());
    }

    @Test(timeOut = 60000)
    public void testCallThatEndsBeforeItsDeadlineIsNotResetByIt() throws Exception {
        // Every stream is answered at once, and the deadline passes while the connection serves the next calls
        startBackend(false, true);
        client = createClient();

        DefaultHttpConnectorListener first = send(withDeadline(newRequest(), DEADLINE_MILLIS));
        assertNotNull(first.getHttpResponseMessage(), "The call failed: " + first.getHttpErrorMessage());
        readBodyFailure(first.getHttpResponseMessage());
        Thread.sleep(DEADLINE_MILLIS + 500);

        assertTrue(resetErrorCodes.isEmpty(), "The deadline of a call that had ended reset a stream");
        DefaultHttpConnectorListener second = send(newRequest());
        assertNotNull(second.getHttpResponseMessage(), "The next call failed: " + second.getHttpErrorMessage());
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

    private void startBackend(boolean stallInTheBody) throws InterruptedException {
        startBackend(stallInTheBody, false);
    }

    // The first stream is answered only if answerEveryStream, and the later ones always are
    private void startBackend(boolean stallInTheBody, boolean answerEveryStream) throws InterruptedException {
        serverGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        serverChannel = new ServerBootstrap()
                .group(serverGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        connections.incrementAndGet();
                        ch.pipeline().addLast(Http2FrameCodecBuilder.forServer().build(),
                                              new Backend(stallInTheBody, answerEveryStream));
                    }
                })
                .bind(HTTP_SERVER_PORT).sync().channel();
    }

    private final class Backend extends ChannelInboundHandlerAdapter {

        private final boolean stallInTheBody;
        private final boolean answerEveryStream;

        Backend(boolean stallInTheBody, boolean answerEveryStream) {
            this.stallInTheBody = stallInTheBody;
            this.answerEveryStream = answerEveryStream;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof Http2HeadersFrame headersFrame) {
                int request = requests.incrementAndGet();
                firstRequestReceived.countDown();
                Http2FrameStream stream = headersFrame.stream();
                if (request == 1 && stallInTheBody) {
                    ctx.write(new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("200"), false)
                                      .stream(stream));
                    ctx.writeAndFlush(new DefaultHttp2DataFrame(Unpooled.wrappedBuffer("partial".getBytes()), false)
                                              .stream(stream));
                } else if (request > 1 || answerEveryStream) {
                    ctx.write(new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("200"), false)
                                      .stream(stream));
                    ctx.writeAndFlush(new DefaultHttp2DataFrame(Unpooled.wrappedBuffer("ok".getBytes()), true)
                                              .stream(stream));
                }
            } else if (msg instanceof Http2ResetFrame resetFrame) {
                resetErrorCodes.add(resetFrame.errorCode());
                firstStreamReset.countDown();
            }
            ReferenceCountUtil.release(msg);
        }
    }

    private static HttpCarbonMessage newRequest() {
        String uri = String.format("http://%s:%d", TestUtil.TEST_HOST, HTTP_SERVER_PORT);
        HttpCarbonMessage request = new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1,
                                                                                 HttpMethod.GET, uri));
        request.setHttpMethod(HttpMethod.GET.toString());
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.HTTP_PORT, HTTP_SERVER_PORT);
        request.setHeader(TestUtil.HOST, TestUtil.TEST_HOST + ":" + HTTP_SERVER_PORT);
        request.addHttpContent(new io.netty.handler.codec.http.DefaultLastHttpContent());
        return request;
    }

    private static HttpCarbonMessage withDeadline(HttpCarbonMessage request, long millis) {
        request.setProperty(Constants.CALL_DEADLINE, CallDeadline.startingNow(TimeUnit.MILLISECONDS.toNanos(millis)));
        return request;
    }

    private DefaultHttpConnectorListener send(HttpCarbonMessage request) throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        client.send(request).setHttpConnectorListener(listener);
        assertTrue(latch.await(30, TimeUnit.SECONDS), "The call neither responded nor failed");
        return listener;
    }

    private static Throwable readBodyFailure(HttpCarbonMessage response) {
        try (InputStream in = new HttpMessageDataStreamer(response).getInputStream()) {
            while (in.read() != -1) {
                // Reading on until the body ends or fails
            }
            return null;
        } catch (IOException | RuntimeException e) {
            return e;
        }
    }

    private static String messageOf(Throwable failure) {
        for (Throwable t = failure; t != null; t = t.getCause()) {
            if (t.getMessage() != null && t.getMessage().startsWith(Constants.CALL_TIMEOUT_EXCEEDED)) {
                return t.getMessage();
            }
        }
        return String.valueOf(failure.getMessage());
    }
}
