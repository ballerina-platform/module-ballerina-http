/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package org.ballerinalang.net.transport.compression;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultFullHttpRequest;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contentaware.listeners.EchoStreamingMessageListener;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.client.http.HttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;

import static org.testng.AssertJUnit.assertEquals;
import static org.testng.AssertJUnit.assertNull;

/**
 * This class tests compression outbound responses.
 */
public class ServerRespCompressionTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(ServerRespCompressionTestCase.class);

    protected ServerConnector serverConnector;
    protected ListenerConfiguration listenerConfiguration;
    private FullHttpRequest httpRequest;
    private FullHttpResponse httpResponse;
    private HttpClient httpClient;

    ServerRespCompressionTestCase() {
        this.listenerConfiguration = new ListenerConfiguration();
    }

    @BeforeClass
    public void setUp() {
        givenServerConnectorWithCompressionAuto();
    }

    @Test
    public void testChunkingRespCompression() {
        whenLargeReqWithAcceptGzipIsSent();
        thenRespShouldContainHeaderValue(Constants.ENCODING_GZIP);

        whenLargeReqWithAcceptDeflateIsSent();
        thenRespShouldContainHeaderValue(Constants.ENCODING_DEFLATE);

        whenLargeReqWithAcceptDeflateFirstIsSent();
        thenRespShouldContainHeaderValue(Constants.ENCODING_DEFLATE);
    }

    @Test
    public void testContentLengthRespCompression() {
        whenSmallReqWithAcceptDeflateIsSent();
        thenRespShouldContainHeaderValue(Constants.ENCODING_DEFLATE);
    }

    @Test
    public void testRespNonCompression() {
        whenReqWithoutAcceptEncodingIsSent();
        assertNull(httpResponse.headers().get(HttpHeaderNames.CONTENT_ENCODING));
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        serverConnector.stop();
    }

    private void givenServerConnectorWithCompressionAuto() {
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setServerHeader(TestUtil.TEST_SERVER);
        ServerBootstrapConfiguration serverBootstrapConfig = new ServerBootstrapConfiguration(new HashMap<>());

        HttpWsConnectorFactory httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        serverConnector = httpWsConnectorFactory.createServerConnector(serverBootstrapConfig, listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new EchoStreamingMessageListener());
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.error("Thread Interrupted while sleeping ", e);
        }
    }

    private void whenReqWithoutAcceptEncodingIsSent() {
        httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
        httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                 HttpMethod.POST, "/", getContent(TestUtil.smallEntity));
        httpResponse = httpClient.sendRequest(httpRequest);
    }

    private void whenSmallReqWithAcceptDeflateIsSent() {
        httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
        httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                 HttpMethod.POST, "/", getContent(TestUtil.smallEntity));
        httpRequest.headers().set(HttpHeaderNames.ACCEPT_ENCODING, Constants.ENCODING_DEFLATE);
        httpResponse = httpClient.sendRequest(httpRequest);
    }

    private void whenLargeReqWithAcceptDeflateFirstIsSent() {
        httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
        httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                 HttpMethod.POST, "/", getContent(TestUtil.largeEntity));
        httpRequest.headers().set(HttpHeaderNames.ACCEPT_ENCODING, "deflate;q=1.0, gzip;q=0.8");
        httpResponse = httpClient.sendRequest(httpRequest);
    }

    private void whenLargeReqWithAcceptDeflateIsSent() {
        httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
        httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                 HttpMethod.POST, "/", getContent(TestUtil.largeEntity));
        httpRequest.headers().set(HttpHeaderNames.ACCEPT_ENCODING, Constants.ENCODING_DEFLATE);
        httpResponse = httpClient.sendRequest(httpRequest);
    }

    private void thenRespShouldContainHeaderValue(String headerValue) {
        assertEquals(headerValue, httpResponse.headers().get(HttpHeaderNames.CONTENT_ENCODING));
    }

    private void whenLargeReqWithAcceptGzipIsSent() {
        httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
        httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                 HttpMethod.POST, "/", getContent(TestUtil.largeEntity));
        httpRequest.headers().set(HttpHeaderNames.ACCEPT_ENCODING, Constants.ENCODING_GZIP);
        httpResponse = httpClient.sendRequest(httpRequest);
    }

    private ByteBuf getContent(String content) {
        return Unpooled.wrappedBuffer(content.getBytes());
    }
}
