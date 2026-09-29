/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ProxyServerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;
import static org.testng.Assert.assertEquals;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * A util class to use in both http and https proxy scenarios.
 */
public final class ProxyServerUtil {
    private ProxyServerUtil() {}

    private static HttpClientConnector httpClientConnector;
    private static ServerConnector serverConnector;
    private static HttpWsConnectorFactory httpWsConnectorFactory;
    private static final Logger LOG = LoggerFactory.getLogger(ProxyServerUtil.class);
    private static SenderConfiguration senderConfiguration;

    protected static void sendRequest(HttpCarbonMessage msg, String testValue) {

        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = httpClientConnector.send(msg);
            responseFuture.setHttpConnectorListener(listener);

            latch.await(5, TimeUnit.SECONDS);

            HttpCarbonMessage response = listener.getHttpResponseMessage();
            assertNotNull(response);
            String result = new BufferedReader(
                    new InputStreamReader(new HttpMessageDataStreamer(response).getInputStream())).lines()
                    .collect(Collectors.joining("\n"));
            assertEquals(testValue, result);
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running testProxyServer", e);
        }
    }

    static void setUpClientAndServerConnectors(ListenerConfiguration listenerConfiguration, String scheme)
            throws InterruptedException {
        setUpClientAndServerConnectors(listenerConfiguration, scheme,
                ProxyServerConfiguration.ProxyProtocol.HTTP, null, null);
    }

    /**
     * Sets up the backend server connector and an HTTP client connector that routes through a proxy speaking the
     * given protocol. The proxy is always assumed to listen on {@link TestUtil#SERVER_PORT2}.
     *
     * @param listenerConfiguration backend listener configuration
     * @param scheme                {@code http://} or {@code https://}
     * @param proxyProtocol         the proxy protocol (HTTP, SOCKS4 or SOCKS5)
     * @param username              proxy username/userId, or {@code null} for no auth
     * @param password              proxy password (SOCKS5/HTTP), or {@code null}
     */
    static void setUpClientAndServerConnectors(ListenerConfiguration listenerConfiguration, String scheme,
                                               ProxyServerConfiguration.ProxyProtocol proxyProtocol,
                                               String username, String password)
            throws InterruptedException {
        setUpClientAndServerConnectors(listenerConfiguration, scheme, proxyProtocol, username, password,
                String.valueOf(Constants.HTTP_1_1));
    }

    /**
     * Sets up the backend server connector and an HTTP client connector that routes through a proxy speaking the
     * given protocol, negotiating the given HTTP version.
     *
     * @param listenerConfiguration backend listener configuration
     * @param scheme                {@code http://} or {@code https://}
     * @param proxyProtocol         the proxy protocol (HTTP, SOCKS4 or SOCKS5)
     * @param username              proxy username/userId, or {@code null} for no auth
     * @param password              proxy password (SOCKS5/HTTP), or {@code null}
     * @param httpVersion           the HTTP version to use (e.g. {@code "1.1"} or {@code "2.0"})
     */
    static void setUpClientAndServerConnectors(ListenerConfiguration listenerConfiguration, String scheme,
                                               ProxyServerConfiguration.ProxyProtocol proxyProtocol,
                                               String username, String password, String httpVersion)
            throws InterruptedException {

        ProxyServerConfiguration proxyServerConfiguration = null;
        try {
            proxyServerConfiguration = new ProxyServerConfiguration("localhost", TestUtil.SERVER_PORT2);
            proxyServerConfiguration.setProxyProtocol(proxyProtocol);
            if (username != null) {
                proxyServerConfiguration.setProxyUsername(username);
            }
            if (password != null) {
                proxyServerConfiguration.setProxyPassword(password);
            }
        } catch (UnknownHostException e) {
            TestUtil.handleException("Failed to resolve host", e);
        }

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        Set<SenderConfiguration> senderConfig = transportsConfiguration.getSenderConfigurations();
        ProxyServerConfiguration finalProxyServerConfiguration = proxyServerConfiguration;
        setSenderConfigs(senderConfig, finalProxyServerConfiguration, scheme, httpVersion);
        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();

        serverConnector = httpWsConnectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        httpClientConnector = httpWsConnectorFactory.createHttpClientConnector(new HashMap<>(), HttpConnectorUtil
                .getSenderConfiguration(transportsConfiguration, scheme));
    }

    static void shutDown() {
        httpClientConnector.close();
        serverConnector.stop();
        try {
            httpWsConnectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }

    private static void setSenderConfigs(Set<SenderConfiguration> senderConfig,
                                         ProxyServerConfiguration finalProxyServerConfiguration, String scheme,
                                         String httpVersion) {
        senderConfig.forEach(config -> {
            if (scheme.equals(HTTPS_SCHEME)) {
                config.setTrustStoreFile(TestUtil.getAbsolutePath(TestUtil.KEY_STORE_FILE_PATH));
                config.setTrustStorePass(TestUtil.KEY_STORE_PASSWORD);
                config.setScheme(HTTPS_SCHEME);
            }
            config.setHttpVersion(httpVersion);
            if (Constants.HTTP_2_0.equals(httpVersion) && !scheme.equals(HTTPS_SCHEME)) {
                // Over plaintext, use HTTP/2 prior knowledge (no upgrade) so the request is sent directly as
                // HTTP/2 through the SOCKS tunnel. Over TLS the version is negotiated via ALPN.
                config.setForceHttp2(true);
            }
            config.setProxyServerConfiguration(finalProxyServerConfiguration);
        });
    }
}

