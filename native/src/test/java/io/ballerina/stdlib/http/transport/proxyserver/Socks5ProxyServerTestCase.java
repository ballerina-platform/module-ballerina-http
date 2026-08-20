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

import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ProxyServerConfiguration.ProxyProtocol;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.Test;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_1_1;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_2_0;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_HOST;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_PORT;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_POST_METHOD;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.PROTOCOL;

/**
 * Integration tests for connecting to a backend through a SOCKS5 proxy, over both plaintext HTTP and TLS, with
 * and without username/password authentication. An embedded Netty SOCKS5 server stands in for the proxy and a
 * Ballerina echo server stands in for the backend.
 */
public class Socks5ProxyServerTestCase {

    private static final String TEST_VALUE = "Test";
    private static final String USERNAME = "proxyUser";
    private static final String PASSWORD = "proxyPass";

    @Test(description = "Connects to an HTTP backend through a SOCKS5 proxy without authentication.")
    public void testSocks5ProxyOverHttp() throws InterruptedException {
        runScenario(HTTP_SCHEME, null, null);
    }

    @Test(description = "Connects to an HTTP backend through a SOCKS5 proxy with username/password auth.")
    public void testSocks5ProxyOverHttpWithAuth() throws InterruptedException {
        runScenario(HTTP_SCHEME, USERNAME, PASSWORD);
    }

    @Test(description = "Connects to an HTTPS backend through a SOCKS5 proxy without authentication.")
    public void testSocks5ProxyOverHttps() throws InterruptedException {
        runScenario(HTTPS_SCHEME, null, null);
    }

    @Test(description = "Connects to an HTTPS backend through a SOCKS5 proxy with username/password auth.")
    public void testSocks5ProxyOverHttpsWithAuth() throws InterruptedException {
        runScenario(HTTPS_SCHEME, USERNAME, PASSWORD);
    }

    @Test(description = "Connects to an HTTP/2 (h2c) backend through a SOCKS5 proxy. HTTP/2 is the default version " +
            "for Ballerina clients.")
    public void testSocks5ProxyOverHttp2() throws InterruptedException {
        runScenario(HTTP_SCHEME, null, null, HTTP_2_0);
    }

    @Test(description = "Connects to an HTTP/2 (h2c) backend through a SOCKS5 proxy with username/password auth.")
    public void testSocks5ProxyOverHttp2WithAuth() throws InterruptedException {
        runScenario(HTTP_SCHEME, USERNAME, PASSWORD, HTTP_2_0);
    }

    @Test(description = "Connects to an HTTP/2 backend over TLS (ALPN) through a SOCKS5 proxy.")
    public void testSocks5ProxyOverHttp2Tls() throws InterruptedException {
        runScenario(HTTPS_SCHEME, null, null, HTTP_2_0);
    }

    private void runScenario(String scheme, String username, String password) throws InterruptedException {
        runScenario(scheme, username, password, String.valueOf(HTTP_1_1));
    }

    private void runScenario(String scheme, String username, String password, String httpVersion)
            throws InterruptedException {
        EmbeddedSocksServer socksServer =
                new EmbeddedSocksServer(TestUtil.SERVER_PORT2, EmbeddedSocksServer.Version.SOCKS5, username, password);
        socksServer.start();
        try {
            ProxyServerUtil.setUpClientAndServerConnectors(getListenerConfiguration(scheme, httpVersion), scheme,
                    ProxyProtocol.SOCKS5, username, password, httpVersion);
            ProxyServerUtil.sendRequest(buildMessage(scheme), TEST_VALUE);
        } finally {
            ProxyServerUtil.shutDown();
            socksServer.stop();
        }
    }

    private ListenerConfiguration getListenerConfiguration(String scheme, String httpVersion) {
        ListenerConfiguration listenerConfiguration = ListenerConfiguration.getDefault();
        listenerConfiguration.setPort(TestUtil.SERVER_PORT1);
        listenerConfiguration.setVersion(httpVersion);
        if (HTTPS_SCHEME.equals(scheme)) {
            listenerConfiguration.setScheme(HTTPS_SCHEME);
            listenerConfiguration.setKeyStoreFile(TestUtil.getAbsolutePath(TestUtil.KEY_STORE_FILE_PATH));
            listenerConfiguration.setKeyStorePass(TestUtil.KEY_STORE_PASSWORD);
        }
        return listenerConfiguration;
    }

    private HttpCarbonMessage buildMessage(String scheme) {
        ByteBuffer byteBuffer = ByteBuffer.wrap(TEST_VALUE.getBytes(StandardCharsets.UTF_8));
        HttpCarbonMessage msg = new HttpCarbonRequest(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, ""));
        msg.setHttpMethod(HTTP_POST_METHOD);
        msg.setProperty(HTTP_PORT, TestUtil.SERVER_PORT1);
        msg.setProperty(PROTOCOL, scheme);
        msg.setProperty(HTTP_HOST, TestUtil.TEST_HOST);
        msg.setHeader("Host", "localhost:" + TestUtil.SERVER_PORT1);
        msg.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(byteBuffer)));
        return msg;
    }
}
