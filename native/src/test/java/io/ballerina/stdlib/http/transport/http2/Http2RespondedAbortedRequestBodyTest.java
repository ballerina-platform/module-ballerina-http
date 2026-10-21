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
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
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
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.DefaultHttp2HeadersFrame;
import io.netty.handler.codec.http2.DefaultHttp2ResetFrame;
import io.netty.handler.codec.http2.Http2DataFrame;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2FrameCodecBuilder;
import io.netty.handler.codec.http2.Http2FrameLogger;
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.handler.logging.LogLevel;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.nio.charset.StandardCharsets;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that a request body which fails after the backend has sent its complete response resets the HTTP/2 stream,
 * instead of ending it as if the body were complete.
 */
public class Http2RespondedAbortedRequestBodyTest {

    private EventLoopGroup serverGroup;
    private Channel serverChannel;
    private HttpClientConnector client;
    private final BlockingQueue<String> requestEnds = new LinkedBlockingQueue<>();

    @Test(timeOut = 60000)
    public void testBodyAbortedAfterTheResponseEndedResetsTheStream() throws Exception {
        sendAbortedBodyAfterTheResponse(false);

        assertEquals(requestEnds.poll(10, TimeUnit.SECONDS), "reset");
    }

    @Test(timeOut = 60000)
    public void testStreamResetByTheBackendIsNotResetBack() throws Exception {
        sendAbortedBodyAfterTheResponse(true);

        assertNull(requestEnds.poll(1, TimeUnit.SECONDS), "The client reset a stream the backend had already reset");
    }

    private void sendAbortedBodyAfterTheResponse(boolean resetAfterResponse) throws Exception {
        startBackend(resetAfterResponse);
        client = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
        HttpCarbonMessage request = createRequest();
        request.addHttpContent(new DefaultHttpContent(Unpooled.copiedBuffer("partial", StandardCharsets.UTF_8)));

        CountDownLatch responded = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(responded);
        client.send(request).setHttpConnectorListener(listener);
        assertTrue(responded.await(10, TimeUnit.SECONDS), "The backend's response never arrived");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Expected a response, got " + listener.getHttpErrorMessage());
        HttpContent responseEnd = response.getHttpContent();
        assertTrue(responseEnd instanceof LastHttpContent, "The response did not end: " + responseEnd);
        responseEnd.release();
        if (resetAfterResponse) {
            // Frames on a connection are handled in order, so once this response arrives the client has handled the
            // RST_STREAM sent before it and closed the stream.
            HttpCarbonMessage barrier = createRequest();
            CountDownLatch barrierResponded = new CountDownLatch(1);
            client.send(barrier).setHttpConnectorListener(new DefaultHttpConnectorListener(barrierResponded));
            barrier.addHttpContent(new DefaultLastHttpContent());
            assertTrue(barrierResponded.await(10, TimeUnit.SECONDS), "The backend did not answer the second request");
        }

        LastHttpContent abortedEnd = new DefaultLastHttpContent();
        abortedEnd.setDecoderResult(DecoderResult.failure(new DecoderException("client went away")));
        request.addHttpContent(abortedEnd);
    }

    private void startBackend(boolean resetAfterResponse) throws InterruptedException {
        serverGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        serverChannel = new ServerBootstrap()
                .group(serverGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ch.pipeline().addLast(Http2FrameCodecBuilder.forServer()
                                                      .frameLogger(new ResetRecorder(requestEnds)).build(),
                                              new CompleteResponseBackend(requestEnds, resetAfterResponse));
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
        if (client != null) {
            client.close();
        }
        if (serverChannel != null) {
            serverChannel.close().sync();
        }
        if (serverGroup != null) {
            serverGroup.shutdownGracefully(0, 1, TimeUnit.SECONDS).sync();
        }
    }

    /**
     * Sends a complete response as soon as the request headers arrive, optionally followed, for a request with a body
     * still to come, by RST_STREAM(NO_ERROR) as RFC 9113 section 8.1 allows. Records a request ended with END_STREAM.
     */
    private static final class CompleteResponseBackend extends ChannelInboundHandlerAdapter {
        private final BlockingQueue<String> requestEnds;
        private final boolean resetAfterResponse;

        CompleteResponseBackend(BlockingQueue<String> requestEnds, boolean resetAfterResponse) {
            this.requestEnds = requestEnds;
            this.resetAfterResponse = resetAfterResponse;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof Http2HeadersFrame headersFrame) {
                ctx.write(new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("200"), true)
                                  .stream(headersFrame.stream()));
                if (resetAfterResponse && !headersFrame.isEndStream()) {
                    ctx.write(new DefaultHttp2ResetFrame(Http2Error.NO_ERROR).stream(headersFrame.stream()));
                }
                ctx.flush();
            } else if (msg instanceof Http2DataFrame dataFrame) {
                dataFrame.release();
                if (dataFrame.isEndStream()) {
                    requestEnds.add("ended");
                }
            } else {
                ReferenceCountUtil.release(msg);
            }
        }
    }

    /**
     * Records every RST_STREAM the backend reads, including one for a stream it has already closed, which the frame
     * codec drops without passing on.
     */
    private static final class ResetRecorder extends Http2FrameLogger {
        private final BlockingQueue<String> requestEnds;

        ResetRecorder(BlockingQueue<String> requestEnds) {
            super(LogLevel.DEBUG);
            this.requestEnds = requestEnds;
        }

        @Override
        public void logRstStream(Direction direction, ChannelHandlerContext ctx, int streamId, long errorCode) {
            if (direction == Direction.INBOUND) {
                requestEnds.add("reset");
            }
        }
    }
}
