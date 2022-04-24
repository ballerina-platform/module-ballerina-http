/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.InboundMsgSizeValidationConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.HttpWsServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLHandlerFactory;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.*;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.socket.nio.NioDatagramChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.ssl.SslContext;
import io.netty.incubator.codec.http3.*;
import io.netty.incubator.codec.quic.*;
import io.netty.util.concurrent.EventExecutorGroup;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetSocketAddress;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.SSLContext;

/**
 * {@code ServerConnectorBootstrap} is the heart of the HTTP Server Connector.
 * <p>
 * This is responsible for creating the serverBootstrap and allow bind/unbind to interfaces
 */
public class ServerConnectorBootstrap {

    private static final Logger LOG = LoggerFactory.getLogger(ServerConnectorBootstrap.class);

    private ServerBootstrap serverBootstrap;
    private Bootstrap http3serverBootstrap;
    private HttpServerChannelInitializer httpServerChannelInitializer;
    private Http3ServerChannelInitializer http3ServerChannelInitializer;
    private boolean initialized;
    private boolean isHttps = false;
    private ChannelGroup allChannels;
    private SSLConfig sslConfig;


    public ServerConnectorBootstrap(ChannelGroup allChannels) {
        serverBootstrap = new ServerBootstrap();
        httpServerChannelInitializer = new HttpServerChannelInitializer();
        httpServerChannelInitializer.setAllChannels(allChannels);
        serverBootstrap.childHandler(httpServerChannelInitializer);
        HttpTransportContextHolder.getInstance().setHandlerExecutor(new HandlerExecutor());
        initialized = true;
        this.allChannels = allChannels;
    }

    public ServerConnectorBootstrap(ChannelGroup allChannels, QuicSslContext sslctx) {

        http3serverBootstrap = new Bootstrap();
        http3ServerChannelInitializer = new Http3ServerChannelInitializer();
        ChannelHandler codec = Http3.newQuicServerCodecBuilder()
                .sslContext(sslctx)
                .maxIdleTimeout(5000, TimeUnit.MILLISECONDS)
                .initialMaxData(10000000)
                .initialMaxStreamDataBidirectionalLocal(1000000)
                .initialMaxStreamDataBidirectionalRemote(1000000)
                .initialMaxStreamsBidirectional(100)
                .tokenHandler(InsecureQuicTokenHandler.INSTANCE)
                .handler(http3ServerChannelInitializer).build();

        http3serverBootstrap.handler(codec);
        HttpTransportContextHolder.getInstance().setHandlerExecutor(new HandlerExecutor());
        initialized = true;
        this.allChannels = allChannels;
    }

    public ServerConnector getServerConnector(String host, int port, String httpVersion) {
        String serverConnectorId = Util.createServerConnectorID(host, port);
        return new HttpServerConnector(serverConnectorId, host, port, httpVersion);
    }

    public void addSocketConfiguration(ServerBootstrapConfiguration serverBootstrapConfiguration) {
        // Set other serverBootstrap parameters
        serverBootstrap.option(ChannelOption.SO_BACKLOG, serverBootstrapConfiguration.getSoBackLog());
        serverBootstrap.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, serverBootstrapConfiguration.getConnectTimeOut());
        serverBootstrap.option(ChannelOption.SO_RCVBUF, serverBootstrapConfiguration.getReceiveBufferSize());

        serverBootstrap.childOption(ChannelOption.TCP_NODELAY, serverBootstrapConfiguration.isTcpNoDelay());
        serverBootstrap.childOption(ChannelOption.SO_RCVBUF, serverBootstrapConfiguration.getReceiveBufferSize());
        serverBootstrap.childOption(ChannelOption.SO_SNDBUF, serverBootstrapConfiguration.getSendBufferSize());

        if (LOG.isDebugEnabled()) {
            LOG.debug(String.format("Netty Server Socket BACKLOG %d", serverBootstrapConfiguration.getSoBackLog()));
            LOG.debug(String.format("Netty Server Socket TCP_NODELAY %s", serverBootstrapConfiguration.isTcpNoDelay()));
            LOG.debug(String.format("Netty Server Socket CONNECT_TIMEOUT_MILLIS %d",
                    serverBootstrapConfiguration.getConnectTimeOut()));
            LOG.debug(String.format("Netty Server Socket SO_RCVBUF %d",
                    serverBootstrapConfiguration.getReceiveBufferSize()));
            LOG.debug(String.format("Netty Server Socket SO_SNDBUF %d",
                    serverBootstrapConfiguration.getSendBufferSize()));
        }
    }

    public void addHttp3SocketConfiguration(ServerBootstrapConfiguration serverBootstrapConfiguration) {

        http3serverBootstrap.option(ChannelOption.SO_BACKLOG, serverBootstrapConfiguration.getSoBackLog());
        http3serverBootstrap.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, serverBootstrapConfiguration.
                getConnectTimeOut());
        http3serverBootstrap.option(ChannelOption.SO_RCVBUF, serverBootstrapConfiguration.getReceiveBufferSize());
        http3serverBootstrap.option(ChannelOption.SO_SNDBUF, serverBootstrapConfiguration.getSendBufferSize());

    }

    public void addSecurity(SSLConfig sslConfig) {
        if (sslConfig != null) {
            httpServerChannelInitializer.setSslConfig(sslConfig);
            isHttps = true;
        }
    }

    public void addIdleTimeout(long socketIdleTimeout) {
        httpServerChannelInitializer.setIdleTimeout(socketIdleTimeout);
    }

    public void setHttp2Enabled(boolean isHttp2Enabled) {
        httpServerChannelInitializer.setHttp2Enabled(isHttp2Enabled);
    }

    public void addThreadPools(EventLoopGroup bossGroup, EventLoopGroup workerGroup) {
        serverBootstrap.group(bossGroup, workerGroup).channel(NioServerSocketChannel.class);
    }

    public void addHttpTraceLogHandler(Boolean isHttpTraceLogEnabled) {
        httpServerChannelInitializer.setHttpTraceLogEnabled(isHttpTraceLogEnabled);
    }

    public void addHttpAccessLogHandler(Boolean isHttpAccessLogEnabled) {
        httpServerChannelInitializer.setHttpAccessLogEnabled(isHttpAccessLogEnabled);
    }

    public void addSslHandlerFactory(SSLHandlerFactory sslHandlerFactory) {
        httpServerChannelInitializer.setSslHandlerFactory(sslHandlerFactory);
    }

    public void addKeystoreSslContext(SSLContext sslContext) {
        httpServerChannelInitializer.setKeystoreSslContext(sslContext);
    }

    public void addHttp2SslContext(SslContext sslContext) {
        httpServerChannelInitializer.setHttp2SslContext(sslContext);
    }

    public void addCertAndKeySslContext(SslContext sslContext) {
        httpServerChannelInitializer.setCertandKeySslContext(sslContext);
    }

    public void addHeaderAndEntitySizeValidation(InboundMsgSizeValidationConfig requestSizeValidationConfig) {
        httpServerChannelInitializer.setReqSizeValidationConfig(requestSizeValidationConfig);
    }

    public void addcertificateRevocationVerifier(Boolean validateCertEnabled) {
        httpServerChannelInitializer.setValidateCertEnabled(validateCertEnabled);
    }

    public void addCacheDelay(int cacheDelay) {
        httpServerChannelInitializer.setCacheDelay(cacheDelay);
    }

    public void addCacheSize(int cacheSize) {
        httpServerChannelInitializer.setCacheSize(cacheSize);
    }

    public void addOcspStapling(boolean ocspStapling) {
        httpServerChannelInitializer.setOcspStaplingEnabled(ocspStapling);
    }

    public void addChunkingBehaviour(ChunkConfig chunkConfig) {
        httpServerChannelInitializer.setChunkingConfig(chunkConfig);
    }

    public void addKeepAliveBehaviour(KeepAliveConfig keepAliveConfig) {
        httpServerChannelInitializer.setKeepAliveConfig(keepAliveConfig);
    }

    public void addServerHeader(String serverName) {
        httpServerChannelInitializer.setServerName(serverName);
    }

    public void setPipeliningEnabled(boolean pipeliningEnabled) {
        httpServerChannelInitializer.setPipeliningEnabled(pipeliningEnabled);
    }

    public void setPipeliningLimit(long pipeliningLimit) {
        httpServerChannelInitializer.setPipeliningLimit(pipeliningLimit);
    }

    public void setPipeliningThreadGroup(EventExecutorGroup pipeliningGroup) {
        httpServerChannelInitializer.setPipeliningThreadGroup(pipeliningGroup);
    }

    public void setWebSocketCompressionEnabled(boolean webSocketCompressionEnabled) {
        httpServerChannelInitializer.setWebSocketCompressionEnabled(webSocketCompressionEnabled);
    }

    //for http3


    public void addHttp3ThreadPools(EventLoopGroup bossGroup) {
        http3serverBootstrap.group(bossGroup).channel(NioDatagramChannel.class);
    }

    public void addHttp3TraceLogHandler(boolean isHttpTraceLogEnabled) {
        http3ServerChannelInitializer.setHttp3TraceLogEnabled(isHttpTraceLogEnabled);

    }

    public void addHttp3AccessLogHandler(boolean isHttpAccessLogEnabled) {
        http3ServerChannelInitializer.setHttp3AccessLogEnabled(isHttpAccessLogEnabled);

    }

    public void addHttp3ChunkingBehaviour(ChunkConfig chunkConfig) {
        http3ServerChannelInitializer.setChunkingConfig(chunkConfig);

    }

    public void addHttp3KeepAliveBehaviour(KeepAliveConfig keepAliveConfig) {
        http3ServerChannelInitializer.setKeepAliveConfig(keepAliveConfig);
    }

    public void setHttp3PipeliningThreadGroup(EventExecutorGroup pipeliningGroup) {
        http3ServerChannelInitializer.setPipeliningThreadGroup(pipeliningGroup);
    }

    public void http3AddSecurity(SSLConfig sslConfig) {
        if (sslConfig != null) {
            http3ServerChannelInitializer.setSslConfig(sslConfig);
            isHttps = true;
        }
    }

    public void http3AddIdleTimeout(long socketIdleTimeout) {
        http3ServerChannelInitializer.setIdleTimeout(socketIdleTimeout);
    }

    class HttpServerConnector implements ServerConnector {

        private final Logger log = LoggerFactory.getLogger(HttpServerConnector.class);
        private final String httpVersion;

        private ChannelFuture channelFuture;
        private ServerConnectorFuture serverConnectorFuture;
        private String host;
        private int port;
        private String connectorID;

        HttpServerConnector(String id, String host, int port, String httpVersion) {
            this.host = host;
            this.port = port;
            this.connectorID = id;
            this.httpVersion = httpVersion;
            if ("3.0".equals(httpVersion)) {
                http3ServerChannelInitializer.setInterfaceId(id);
            } else {
                httpServerChannelInitializer.setInterfaceId(id);
            }
        }

        @Override
        public ServerConnectorFuture start() {
            channelFuture = bindInterface();
            serverConnectorFuture = new HttpWsServerConnectorFuture(channelFuture, allChannels);
            channelFuture.addListener(future -> {
                if (future.isSuccess()) {
                    if (log.isDebugEnabled()) {
                        log.debug("HTTP(S) Interface starting on host {} and port {}", getHost(), getPort());
                    }
                    serverConnectorFuture.notifyPortBindingEvent(this.connectorID, isHttps);
                } else {
                    serverConnectorFuture.notifyPortBindingError(future.cause());
                }
            });
            if ("3.0".equals(httpVersion)) {
                http3ServerChannelInitializer.setServerConnectorFuture(serverConnectorFuture);
            } else {
                httpServerChannelInitializer.setServerConnectorFuture(serverConnectorFuture);
            }

            return serverConnectorFuture;
        }

        @Override
        public boolean stop() {
            boolean connectorStopped = false;

            try {
                connectorStopped = unBindInterface();
                if (connectorStopped) {
                    serverConnectorFuture.notifyPortUnbindingEvent(this.connectorID, isHttps);
                }
            } catch (InterruptedException e) {
                log.error("Couldn't close the port", e);
                return false;
            } catch (ServerConnectorException e) {
                log.error("Error in notifying life cycle event listener", e);
            }

            return connectorStopped;
        }

        @Override
        public String getConnectorID() {
            return this.connectorID;
        }

        private ChannelFuture getChannelFuture() {
            return channelFuture;
        }

        @Override
        public String toString() {
            return this.host + "-" + this.port;
        }

        public String getHost() {
            return host;
        }

        public int getPort() {
            return port;
        }

        private ChannelFuture bindInterface() {
            if (!initialized) {
                log.error("ServerConnectorBootstrap is not initialized");
                return null;
            }
            if ("3.0".equals(httpVersion)) {
                return http3serverBootstrap.bind(new InetSocketAddress(getHost(), getPort()));
            } else {
                return serverBootstrap.bind(new InetSocketAddress(getHost(), getPort()));
            }
        }

        private boolean unBindInterface() throws InterruptedException {
            if (!initialized) {
                log.error("ServerConnectorBootstrap is not initialized");
                return false;
            }

            //Remove cached channels and close them.
            ChannelFuture future = getChannelFuture();
            if (future != null) {
                //Close will stop accepting new connections.
                future.channel().close().sync();
                if (log.isDebugEnabled()) {
                    log.debug("HttpConnectorListener stopped listening on host {} and port {}", getHost(), getPort());
                }
                return true;
            }
            return false;
        }
    }
}
