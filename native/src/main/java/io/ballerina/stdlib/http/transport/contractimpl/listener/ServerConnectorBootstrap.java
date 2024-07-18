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
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.ssl.SslContext;
import io.netty.util.concurrent.EventExecutorGroup;
import io.netty.util.concurrent.GlobalEventExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetSocketAddress;
import java.util.Objects;

import javax.net.ssl.SSLContext;

/**
 * {@code ServerConnectorBootstrap} is the heart of the HTTP Server Connector.
 * <p>
 * This is responsible for creating the serverBootstrap and allow bind/unbind to interfaces
 */
public class ServerConnectorBootstrap {

    private static final Logger LOG = LoggerFactory.getLogger(ServerConnectorBootstrap.class);

    private ServerBootstrap serverBootstrap;
    private HttpServerChannelInitializer httpServerChannelInitializer;
    private boolean initialized;
    private boolean isHttps = false;
    private ChannelGroup allChannels;
    private final ChannelGroup listenerChannels = new DefaultChannelGroup(GlobalEventExecutor.INSTANCE);
    private int gracefulStopTimeout = 0;

    public ServerConnectorBootstrap(ChannelGroup allChannels) {
        serverBootstrap = new ServerBootstrap();
        httpServerChannelInitializer = new HttpServerChannelInitializer();
        httpServerChannelInitializer.setAllChannels(allChannels, listenerChannels);
        serverBootstrap.childHandler(httpServerChannelInitializer);
        HttpTransportContextHolder.getInstance().setHandlerExecutor(new HandlerExecutor());
        initialized = true;
        this.allChannels = allChannels;
    }

    public ServerConnector getServerConnector(String host, int port) {
        String serverConnectorId = Util.createServerConnectorID(host, port);
        return new HttpServerConnector(serverConnectorId, host, port);
    }

    public void addSocketConfiguration(ServerBootstrapConfiguration serverBootstrapConfiguration) {
        // Set other serverBootstrap parameters
        serverBootstrap.option(ChannelOption.SO_BACKLOG, serverBootstrapConfiguration.getSoBackLog());
        serverBootstrap.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, serverBootstrapConfiguration.getConnectTimeOut());
        serverBootstrap.option(ChannelOption.SO_RCVBUF, serverBootstrapConfiguration.getReceiveBufferSize());

        serverBootstrap.childOption(ChannelOption.TCP_NODELAY, serverBootstrapConfiguration.isTcpNoDelay());
        serverBootstrap.childOption(ChannelOption.SO_RCVBUF, serverBootstrapConfiguration.getReceiveBufferSize());
        serverBootstrap.childOption(ChannelOption.SO_SNDBUF, serverBootstrapConfiguration.getSendBufferSize());
        serverBootstrap.childOption(ChannelOption.SO_KEEPALIVE, serverBootstrapConfiguration.isKeepAlive());
        serverBootstrap.childOption(ChannelOption.SO_REUSEADDR, serverBootstrapConfiguration.isSocketReuse());

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

    public void setHttp2InitialWindowSize(int http2InitialWindowSize) {
        httpServerChannelInitializer.setHttp2InitialWindowSize(http2InitialWindowSize);
    }

    public void setTimeBetweenStaleEviction(long timeBetweenStaleEviction) {
        httpServerChannelInitializer.setTimeBetweenStaleEviction(timeBetweenStaleEviction);
    }

    public void setMinIdleTimeInStaleState(long minIdleTimeInStaleState) {
        httpServerChannelInitializer.setMinIdleTimeInStaleState(minIdleTimeInStaleState);
    }

    public ChannelGroup getListenerChannels() {
        return listenerChannels;
    }

    public void setGracefulStopTimeout(int gracefulStopTimeout) {
        this.gracefulStopTimeout = gracefulStopTimeout;
    }

    class HttpServerConnector implements ServerConnector {

       private final Logger log = LoggerFactory.getLogger(HttpServerConnector.class);

        private ServerConnectorFuture serverConnectorFuture;
        private String host;
        private int port;
        private String connectorID;
        private Channel serverChannel;

        HttpServerConnector(String id, String host, int port) {
            this.host = host;
            this.port = port;
            this.connectorID = id;
            httpServerChannelInitializer.setInterfaceId(id);
        }

        @Override
        public ServerConnectorFuture start() {
            ChannelFuture channelFuture = bindInterface();
            if (Objects.nonNull(channelFuture)) {
                serverChannel = channelFuture.channel();
            }
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
            httpServerChannelInitializer.setServerConnectorFuture(serverConnectorFuture);
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
        public boolean immediateStop() {
            setGracefulStopTimeout(0);
            return this.stop();
        }

        @Override
        public String getConnectorID() {
            return this.connectorID;
        }

        private Channel getServerChannel() {
            return serverChannel;
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
            return serverBootstrap.bind(new InetSocketAddress(getHost(), getPort()));
        }

        private boolean unBindInterface() throws InterruptedException {
            if (!initialized) {
                log.error("ServerConnectorBootstrap is not initialized");
                return false;
            }

            //Remove cached channels and close them.
            Channel listenerChannel = getServerChannel();
            if (listenerChannel != null) {
                try {
                    //Close will stop accepting new connections.
                    listenerChannel.close().sync();
                    try {
                        Thread.sleep(gracefulStopTimeout);
                    } catch (InterruptedException e) {
                        log.warn("Couldn't complete the graceful time period");
                    }
                    //Close will close existing connections after above grace period.
                    getListenerChannels().close().sync();
                } catch (InterruptedException e) {
                    log.error("Failed to shutdown the listener", e);
                }

                if (log.isDebugEnabled()) {
                    log.debug("HttpConnectorListener stopped listening on host {} and port {}", getHost(), getPort());
                }
                return true;
            }
            return false;
        }
    }
}
