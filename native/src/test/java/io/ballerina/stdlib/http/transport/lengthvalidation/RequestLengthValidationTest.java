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

package io.ballerina.stdlib.http.transport.lengthvalidation;

import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;
import com.mashape.unirest.http.exceptions.UnirestException;
import com.mashape.unirest.http.options.Options;
import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoStreamingMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http.HttpClient;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultFullHttpRequest;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.net.URI;
import java.net.URL;
import java.util.HashMap;

import static org.testng.AssertJUnit.assertEquals;

/**
 * This class tests for 413, 414 and 431 responses.
 */
public class RequestLengthValidationTest {

    private static final Logger LOG = LoggerFactory.getLogger(RequestLengthValidationTest.class);

    protected ServerConnector serverConnector;
    protected ListenerConfiguration listenerConfiguration;
    private HttpWsConnectorFactory httpWsConnectorFactory;
    private static final String testValue = "Test Message";
    private URI baseURI = URI.create(String.format("http://%s:%d", "localhost", TestUtil.SERVER_CONNECTOR_PORT));

    RequestLengthValidationTest() {
        this.listenerConfiguration = new ListenerConfiguration();
    }

    @BeforeClass
    public void setUp() {
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setServerHeader(TestUtil.TEST_SERVER);
        listenerConfiguration.getMsgSizeValidationConfig().setMaxEntityBodySize(1024);
        listenerConfiguration.getMsgSizeValidationConfig().setMaxHeaderSize(1024);
        listenerConfiguration.getMsgSizeValidationConfig().setMaxInitialLineLength(1024);

        ServerBootstrapConfiguration serverBootstrapConfig = new ServerBootstrapConfiguration(new HashMap<>());
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        serverConnector = httpWsConnectorFactory.createServerConnector(serverBootstrapConfig, listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new EchoStreamingMessageListener());
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.error("Thread Interrupted while sleeping ", e);
        }
    }

    @Test
    public void largeUriTest() {
        try {
            HttpClient httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
            FullHttpRequest httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                                                                     HttpMethod.POST, getUriWithLengthOf(9000),
                                                                     Unpooled.wrappedBuffer(testValue.getBytes()));
            FullHttpResponse httpResponse = httpClient.sendRequest(httpRequest);

            assertEquals(HttpResponseStatus.REQUEST_URI_TOO_LONG.code(), httpResponse.status().code());
            assertEquals(TestUtil.TEST_SERVER, httpResponse.headers().get(HttpHeaderNames.SERVER.toString()));
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running largeUriTest", e);
        }
    }

    @Test
    public void shortUriTest() {
        try {
            HttpResponse<String> response = sendShortUri();
            assertEquals(HttpResponseStatus.OK.code(), response.getStatus());
            assertEquals(TestUtil.TEST_SERVER, response.getHeaders().getFirst(HttpHeaderNames.SERVER.toString()));
            assertEquals(testValue, response.getBody());
        } catch (IOException | UnirestException e) {
            TestUtil.handleException("IOException occurred while running shortUriTest", e);
        }
    }

    @Test
    public void largeHeaderTest() {
        try {
            HttpClient httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);

            FullHttpRequest httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(testValue.getBytes()));
            httpRequest.headers().set("X-Test", getLargeHeader());
            FullHttpResponse httpResponse = httpClient.sendRequest(httpRequest);

            assertEquals(HttpResponseStatus.REQUEST_HEADER_FIELDS_TOO_LARGE.code(), httpResponse.status().code());
            assertEquals(Constants.CONNECTION_CLOSE, httpResponse.headers().get(HttpHeaderNames.CONNECTION.toString()));
            assertEquals(TestUtil.TEST_SERVER, httpResponse.headers().get(HttpHeaderNames.SERVER));

            httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
            httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(testValue.getBytes()));
            httpResponse = httpClient.sendRequest(httpRequest);
            String payload = TestUtil.getEntityBodyFrom(httpResponse);

            assertEquals(testValue, payload);
            assertEquals(HttpResponseStatus.OK.code(), httpResponse.status().code());
            assertEquals(TestUtil.TEST_SERVER, httpResponse.headers().get(HttpHeaderNames.SERVER.toString()));

        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running largeHeaderTest", e);
        }
    }

    @Test
    public void largeEntityBodyTest() {
        try {
            HttpClient httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);

            FullHttpRequest httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(TestUtil.largeEntity.getBytes()));
            FullHttpResponse httpResponse = httpClient.sendChunkRequest(httpRequest);
            assertEntityTooLargeResponse(httpResponse);

            httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
            httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(TestUtil.largeEntity.getBytes()));
            httpResponse = httpClient.sendRequest(httpRequest);
            assertEntityTooLargeResponse(httpResponse);

            httpClient = new HttpClient(TestUtil.TEST_HOST, TestUtil.SERVER_CONNECTOR_PORT);
            httpRequest = new DefaultFullHttpRequest(HttpVersion.HTTP_1_1,
                    HttpMethod.POST, "/", Unpooled.wrappedBuffer(TestUtil.smallEntity.getBytes()));
            httpResponse = httpClient.sendRequest(httpRequest);
            assertEquals(HttpResponseStatus.OK.code(), httpResponse.status().code());
            assertEquals(TestUtil.TEST_SERVER, httpResponse.headers().get(HttpHeaderNames.SERVER));

        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running largeEntityBodyTest", e);
        }
    }

    private void assertEntityTooLargeResponse(FullHttpResponse httpResponse) {
        assertEquals(HttpResponseStatus.REQUEST_ENTITY_TOO_LARGE.code(), httpResponse.status().code());
        assertEquals(Constants.CONNECTION_CLOSE, httpResponse.headers().get(HttpHeaderNames.CONNECTION.toString()));
        assertEquals(TestUtil.TEST_SERVER, httpResponse.headers().get(HttpHeaderNames.SERVER));
    }

    private String getLargeHeader() {
        StringBuilder header = new StringBuilder("x");
        for (int i = 0; i < 9000; i++) {
            header.append("x");
        }
        return header.toString();
    }

    private HttpResponse<String> sendShortUri() throws IOException, UnirestException {
        URL url = baseURI.resolve(getUriWithLengthOf(900)).toURL();
        return sendPostRequest(url);
    }

    private String getUriWithLengthOf(int length) {
        StringBuilder uri = new StringBuilder("/");
        for (int i = 0; i < length; i++) {
            uri.append("x");
        }
        return uri.toString();
    }

    private HttpResponse<String> sendPostRequest(URL url) throws UnirestException {
        return Unirest.post(url.toString()).body(testValue).asString();
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        serverConnector.stop();
        try {
            Unirest.shutdown();
            Options.refresh();
            httpWsConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        } catch (IOException e) {
            LOG.warn("IOException occurred while waiting for Unirest connection to shutdown", e);
        }
    }
}
