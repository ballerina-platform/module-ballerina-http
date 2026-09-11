/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.proxyserver;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.ProxyServerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.SendChannelIDServerInitializer;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.UnknownHostException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_HOST;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_PORT;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.PROTOCOL;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Verifies that client connection pooling works through a SOCKS5 proxy. The backend echoes the id of the channel
 * that served the request; because the embedded SOCKS proxy keeps a single relayed backend connection alive for the
 * lifetime of each (keep-alive) client connection, two sequential requests that reuse the same pooled client
 * connection are served by the same backend channel. Therefore, equal channel ids across two sequential requests
 * prove the client reused its pooled connection rather than dialling a fresh SOCKS tunnel.
 */
public class SocksConnectionPoolTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(SocksConnectionPoolTestCase.class);

    private HttpWsConnectorFactory httpWsConnectorFactory;
    private HttpClientConnector httpClientConnector;
    private HttpServer backendServer;
    private EmbeddedSocksServer socksServer;

    @BeforeClass
    public void setup() throws InterruptedException {
        // Real backend that responds with the serving channel's id (keep-alive enabled).
        backendServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new SendChannelIDServerInitializer(0));

        // SOCKS5 proxy with no authentication.
        socksServer = new EmbeddedSocksServer(TestUtil.SERVER_PORT2, EmbeddedSocksServer.Version.SOCKS5, null, null);
        socksServer.start();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration =
                HttpConnectorUtil.getSenderConfiguration(transportsConfiguration, HTTP_SCHEME);
        try {
            ProxyServerConfiguration proxyServerConfiguration =
                    new ProxyServerConfiguration("localhost", TestUtil.SERVER_PORT2);
            proxyServerConfiguration.setProxyProtocol(ProxyServerConfiguration.ProxyProtocol.SOCKS5);
            senderConfiguration.setProxyServerConfiguration(proxyServerConfiguration);
        } catch (UnknownHostException e) {
            TestUtil.handleException("Failed to resolve proxy host", e);
        }

        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = httpWsConnectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test(description = "Two sequential requests through a SOCKS5 proxy reuse the same pooled client connection.")
    public void testConnectionReuseThroughSocks5Proxy() {
        String channelIdOne = sendRequestAndGetResponse();
        String channelIdTwo = sendRequestAndGetResponse();
        assertNotNull(channelIdOne);
        assertNotNull(channelIdTwo);
        assertEquals(channelIdTwo, channelIdOne,
                "Sequential requests through the SOCKS5 proxy should reuse the same pooled connection");
    }

    private String sendRequestAndGetResponse() {
        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = httpClientConnector.send(buildMessage());
            responseFuture.setHttpConnectorListener(listener);
            latch.await(5, TimeUnit.SECONDS);

            HttpCarbonMessage response = listener.getHttpResponseMessage();
            assertNotNull(response);
            return new BufferedReader(
                    new InputStreamReader(new HttpMessageDataStreamer(response).getInputStream())).lines()
                    .collect(Collectors.joining("\n"));
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running testConnectionReuseThroughSocks5Proxy", e);
        }
        return null;
    }

    private HttpCarbonMessage buildMessage() {
        HttpCarbonMessage msg = new HttpCarbonRequest(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, ""));
        msg.setHttpMethod(HttpMethod.GET.name());
        msg.setProperty(HTTP_PORT, TestUtil.HTTP_SERVER_PORT);
        msg.setProperty(PROTOCOL, HTTP_SCHEME);
        msg.setProperty(HTTP_HOST, TestUtil.TEST_HOST);
        msg.setHeader("Host", "localhost:" + TestUtil.HTTP_SERVER_PORT);
        msg.addHttpContent(new DefaultLastHttpContent());
        return msg;
    }

    @AfterClass
    public void cleanUp() {
        httpClientConnector.close();
        socksServer.stop();
        try {
            backendServer.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while shutting down the SOCKS connection-pool test resources", e);
        }
    }
}
