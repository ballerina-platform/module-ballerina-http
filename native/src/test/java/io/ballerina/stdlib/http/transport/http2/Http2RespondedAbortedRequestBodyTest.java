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
import io.netty.handler.codec.http2.Http2DataFrame;
import io.netty.handler.codec.http2.Http2FrameCodecBuilder;
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.handler.codec.http2.Http2ResetFrame;
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
        startBackend();
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

        LastHttpContent abortedEnd = new DefaultLastHttpContent();
        abortedEnd.setDecoderResult(DecoderResult.failure(new DecoderException("client went away")));
        request.addHttpContent(abortedEnd);

        assertEquals(requestEnds.poll(10, TimeUnit.SECONDS), "reset");
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
                                              new CompleteResponseBackend(requestEnds));
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
     * Sends a complete response as soon as the request headers arrive, then records whether the request was ended
     * with END_STREAM or reset.
     */
    private static final class CompleteResponseBackend extends ChannelInboundHandlerAdapter {
        private final BlockingQueue<String> requestEnds;

        CompleteResponseBackend(BlockingQueue<String> requestEnds) {
            this.requestEnds = requestEnds;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof Http2HeadersFrame headersFrame) {
                ctx.writeAndFlush(new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("200"), true)
                                          .stream(headersFrame.stream()));
            } else if (msg instanceof Http2DataFrame dataFrame) {
                dataFrame.release();
                if (dataFrame.isEndStream()) {
                    requestEnds.add("ended");
                }
            } else if (msg instanceof Http2ResetFrame) {
                requestEnds.add("reset");
            } else {
                ReferenceCountUtil.release(msg);
            }
        }
    }
}
