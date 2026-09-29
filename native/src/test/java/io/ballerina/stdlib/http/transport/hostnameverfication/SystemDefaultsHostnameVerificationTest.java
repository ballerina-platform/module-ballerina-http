/*
 * Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
package io.ballerina.stdlib.http.transport.hostnameverfication;

import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLHandlerFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import io.netty.handler.ssl.SslHandler;
import io.netty.handler.ssl.SslProvider;
import io.netty.util.concurrent.Future;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.FileInputStream;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.security.KeyStore;
import java.util.Locale;

import javax.net.ssl.KeyManagerFactory;

import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests host name verification for the system default (Java defaults) client configuration, which trusts the JVM
 * default trust store rather than a configured one. The server certificate is issued for CN=localhost with no subject
 * alternative names, so reaching it over 127.0.0.1 is a host name mismatch.
 */
public class SystemDefaultsHostnameVerificationTest {

    private static final String KEY_STORE_PATH = "/simple-test-config/wso2carbon.p12";
    private static final String TRUST_STORE_PATH = "/simple-test-config/client-truststore.p12";
    private static final String PASSWORD = "ballerina";
    private static final String STORE_TYPE = "PKCS12";
    private static final String TRUST_STORE_PROPERTY = "javax.net.ssl.trustStore";
    private static final String TRUST_STORE_PASSWORD_PROPERTY = "javax.net.ssl.trustStorePassword";
    private static final String TRUST_STORE_TYPE_PROPERTY = "javax.net.ssl.trustStoreType";

    private EventLoopGroup eventLoopGroup;
    private Channel serverChannel;
    private int serverPort;
    private String originalTrustStore;
    private String originalTrustStorePassword;
    private String originalTrustStoreType;

    @BeforeClass
    public void setup() throws Exception {
        originalTrustStore = System.getProperty(TRUST_STORE_PROPERTY);
        originalTrustStorePassword = System.getProperty(TRUST_STORE_PASSWORD_PROPERTY);
        originalTrustStoreType = System.getProperty(TRUST_STORE_TYPE_PROPERTY);
        System.setProperty(TRUST_STORE_PROPERTY, TestUtil.getAbsolutePath(TRUST_STORE_PATH));
        System.setProperty(TRUST_STORE_PASSWORD_PROPERTY, PASSWORD);
        System.setProperty(TRUST_STORE_TYPE_PROPERTY, STORE_TYPE);

        eventLoopGroup = new NioEventLoopGroup(2);
        SslContext serverSslContext = SslContextBuilder.forServer(getKeyManagerFactory())
                .sslProvider(SslProvider.JDK).build();
        serverChannel = new ServerBootstrap().group(eventLoopGroup).channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel channel) {
                        channel.pipeline().addLast(serverSslContext.newHandler(channel.alloc()));
                    }
                }).bind("127.0.0.1", 0).sync().channel();
        serverPort = ((InetSocketAddress) serverChannel.localAddress()).getPort();
    }

    @Test
    public void testSystemDefaultsRejectHostNameMismatch() throws Exception {
        Throwable cause = handshake(true);
        assertNotNull(cause, "Expected the handshake to fail on a host name mismatch");
        assertTrue(hasHostNameMismatchCause(cause),
                "Expected a host name verification failure, but got: " + describe(cause));
    }

    @Test
    public void testSystemDefaultsAllowHostNameMismatchWhenVerificationDisabled() throws Exception {
        Throwable cause = handshake(false);
        assertTrue(cause == null, "Expected the handshake to succeed, but got: " + describe(cause));
    }

    private Throwable handshake(boolean hostNameVerificationEnabled) throws Exception {
        SSLConfig sslConfig = new SSLConfig();
        sslConfig.setUseJavaDefaults();
        sslConfig.setHostNameVerificationEnabled(hostNameVerificationEnabled);
        SslContext sslContext = new SSLHandlerFactory(sslConfig).createHttp2TLSContextForClient(false);

        SslHandler[] sslHandler = new SslHandler[1];
        Channel channel = new Bootstrap().group(eventLoopGroup).channel(NioSocketChannel.class)
                .handler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel channel) {
                        sslHandler[0] = sslContext.newHandler(channel.alloc(), "127.0.0.1", serverPort);
                        channel.pipeline().addLast(sslHandler[0]);
                    }
                }).connect("127.0.0.1", serverPort).sync().channel();
        try {
            Future<Channel> handshakeFuture = sslHandler[0].handshakeFuture().await();
            return handshakeFuture.isSuccess() ? null : handshakeFuture.cause();
        } finally {
            channel.close().sync();
        }
    }

    private boolean hasHostNameMismatchCause(Throwable cause) {
        for (Throwable current = cause; current != null; current = current.getCause()) {
            String message = current.getMessage() == null ? "" : current.getMessage().toLowerCase(Locale.ENGLISH);
            if (message.contains("no subject alternative names") || message.contains("no name matching")) {
                return true;
            }
            if (current.getCause() == current) {
                break;
            }
        }
        return false;
    }

    private String describe(Throwable cause) {
        StringBuilder description = new StringBuilder();
        for (Throwable current = cause; current != null; current = current.getCause()) {
            description.append(current).append(" <- ");
            if (current.getCause() == current) {
                break;
            }
        }
        return description.toString();
    }

    private KeyManagerFactory getKeyManagerFactory() throws Exception {
        KeyStore keyStore = KeyStore.getInstance(STORE_TYPE);
        try (InputStream keyStoreStream = new FileInputStream(TestUtil.getAbsolutePath(KEY_STORE_PATH))) {
            keyStore.load(keyStoreStream, PASSWORD.toCharArray());
        }
        KeyManagerFactory keyManagerFactory =
                KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        keyManagerFactory.init(keyStore, PASSWORD.toCharArray());
        return keyManagerFactory;
    }

    @AfterClass
    public void cleanUp() throws InterruptedException {
        restoreProperty(TRUST_STORE_PROPERTY, originalTrustStore);
        restoreProperty(TRUST_STORE_PASSWORD_PROPERTY, originalTrustStorePassword);
        restoreProperty(TRUST_STORE_TYPE_PROPERTY, originalTrustStoreType);
        if (serverChannel != null) {
            serverChannel.close().sync();
        }
        if (eventLoopGroup != null) {
            eventLoopGroup.shutdownGracefully().sync();
        }
    }

    private void restoreProperty(String key, String value) {
        if (value == null) {
            System.clearProperty(key);
        } else {
            System.setProperty(key, value);
        }
    }
}
