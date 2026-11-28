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
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
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
import io.netty.handler.codec.http2.Http2HeadersFrame;
import io.netty.util.ReferenceCountUtil;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.nio.charset.StandardCharsets;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that a reset or a connection closure reaches a response that started before the request finished sending.
 */
public class Http2EarlyResponseStreamTerminationTest {

    private EventLoopGroup serverGroup;
    private Channel serverChannel;
    private HttpClientConnector client;

    @Test(timeOut = 60000)
    public void testResetAfterRequestEndFailsTheStreamingResponse() throws Exception {
        startBackend(false);
        assertEquals(sendAndReadResponseBodyFailure(),
                     Constants.REMOTE_SERVER_SENT_RST_STREAM_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    @Test(timeOut = 60000)
    public void testConnectionCloseAfterRequestEndFailsTheStreamingResponse() throws Exception {
        startBackend(true);
        assertEquals(sendAndReadResponseBodyFailure(),
                     Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    private String sendAndReadResponseBodyFailure() throws Exception {
        client = FrameLevelTestUtils.setupHttp2PriorKnowledgeClient();
        HttpCarbonMessage request = createRequest();
        request.addHttpContent(new DefaultHttpContent(Unpooled.copiedBuffer("first", StandardCharsets.UTF_8)));

        CountDownLatch responded = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(responded);
        HttpResponseFuture responseFuture = client.send(request);
        responseFuture.setHttpConnectorListener(listener);
        assertTrue(responded.await(10, TimeUnit.SECONDS), "The backend's early response never arrived");
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "Expected a response, got " + listener.getHttpErrorMessage());

        // The backend has already started the response, and ends the exchange once it sees the request end.
        request.addHttpContent(new DefaultLastHttpContent(Unpooled.copiedBuffer("last", StandardCharsets.UTF_8)));

        CompletableFuture<String> bodyFailure = CompletableFuture.supplyAsync(() -> {
            while (true) {
                HttpContent content = response.getHttpContent();
                if (content == null) {
                    return "no content before the collector timed out";
                }
                content.release();
                if (content.decoderResult().isFailure()) {
                    return content.decoderResult().cause().getMessage();
                }
                if (content instanceof LastHttpContent) {
                    return "the response body completed normally";
                }
            }
        });
        return bodyFailure.get(10, TimeUnit.SECONDS);
    }

    private void startBackend(boolean closeConnection) throws InterruptedException {
        serverGroup = new MultiThreadIoEventLoopGroup(1, NioIoHandler.newFactory());
        serverChannel = new ServerBootstrap()
                .group(serverGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ch.pipeline().addLast(Http2FrameCodecBuilder.forServer().build(),
                                              new EarlyResponseBackend(closeConnection));
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
     * Sends the response headers as soon as the request headers arrive, and on the request's END_STREAM either resets
     * the stream or closes the connection without sending any response body. No response DATA arrives after the
     * request ends, since one would move the client's stream state back to receiving the body and hide the bug.
     */
    private static final class EarlyResponseBackend extends ChannelInboundHandlerAdapter {
        private final boolean closeConnection;

        EarlyResponseBackend(boolean closeConnection) {
            this.closeConnection = closeConnection;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof Http2HeadersFrame headersFrame) {
                ctx.writeAndFlush(new DefaultHttp2HeadersFrame(new DefaultHttp2Headers().status("200"))
                                          .stream(headersFrame.stream()));
            } else if (msg instanceof Http2DataFrame dataFrame) {
                dataFrame.release();
                if (!dataFrame.isEndStream()) {
                    return;
                }
                if (closeConnection) {
                    ctx.close();
                } else {
                    ctx.writeAndFlush(new DefaultHttp2ResetFrame(Http2Error.CANCEL).stream(dataFrame.stream()));
                }
            } else {
                ReferenceCountUtil.release(msg);
            }
        }
    }
}
