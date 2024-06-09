/*
 * Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.config.InboundMsgSizeValidationConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contract.config.ProxyServerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpClientUpgradeHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.FrameLogger;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.http2.Http2ExceptionHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLHandlerFactory;
import io.ballerina.stdlib.http.transport.contractimpl.listener.HttpExceptionHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.HttpTraceLoggingHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.ClientFrameListener;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2TargetHandler;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;
import io.netty.handler.codec.http.HttpClientCodec;
import io.netty.handler.codec.http.HttpContentDecompressor;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.DelegatingDecompressorFrameListener;
import io.netty.handler.codec.http2.Http2ClientUpgradeCodec;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2ConnectionHandler;
import io.netty.handler.codec.http2.Http2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2FrameListener;
import io.netty.handler.proxy.HttpProxyHandler;
import io.netty.handler.ssl.ApplicationProtocolNames;
import io.netty.handler.ssl.ApplicationProtocolNegotiationHandler;
import io.netty.handler.ssl.ReferenceCountedOpenSslContext;
import io.netty.handler.ssl.ReferenceCountedOpenSslEngine;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.channels.ClosedChannelException;

import javax.net.ssl.SSLEngine;

import static io.ballerina.stdlib.http.transport.contract.Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER;
import static io.ballerina.stdlib.http.transport.contract.Constants.SECURITY;
import static io.ballerina.stdlib.http.transport.contract.Constants.SSL;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.setHostNameVerfication;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.setSslHandshakeTimeOut;
import static io.netty.handler.logging.LogLevel.TRACE;

/**
 * A class that responsible for initialize target server pipeline.
 */
public class HttpClientChannelInitializer extends ChannelInitializer<SocketChannel> {

    private TargetHandler targetHandler;
    private boolean httpTraceLogEnabled;
    private boolean httpAccessLogEnabled;
    private KeepAliveConfig keepAliveConfig;
    private ProxyServerConfiguration proxyServerConfiguration;
    private Http2ConnectionManager http2ConnectionManager;
    private boolean http2 = false;
    private Http2ConnectionHandler http2ConnectionHandler;
    private ClientFrameListener clientFrameListener;
    private Http2TargetHandler http2TargetHandler;
    private Http2Connection connection;
    private SSLConfig sslConfig;
    private HttpRoute httpRoute;
    private SenderConfiguration senderConfiguration;
    private ConnectionAvailabilityFuture connectionAvailabilityFuture;
    private SSLHandlerFactory sslHandlerFactory;
    private final InboundMsgSizeValidationConfig responseSizeValidationConfig;
    private static final Logger LOG = LoggerFactory.getLogger(HttpClientChannelInitializer.class);

    public HttpClientChannelInitializer(SenderConfiguration senderConfiguration, HttpRoute httpRoute,
                                        ConnectionManager connectionManager,
                                        ConnectionAvailabilityFuture connectionAvailabilityFuture) {
        this.httpTraceLogEnabled = senderConfiguration.isHttpTraceLogEnabled();
        this.httpAccessLogEnabled = senderConfiguration.isHttpAccessLogEnabled();
        this.keepAliveConfig = senderConfiguration.getKeepAliveConfig();
        this.proxyServerConfiguration = senderConfiguration.getProxyServerConfiguration();
        this.http2ConnectionManager = connectionManager.getHttp2ConnectionManager();
        this.senderConfiguration = senderConfiguration;
        this.httpRoute = httpRoute;
        this.sslConfig = senderConfiguration.getClientSSLConfig();
        this.connectionAvailabilityFuture = connectionAvailabilityFuture;
        this.responseSizeValidationConfig = senderConfiguration.getMsgSizeValidationConfig();

        String httpVersion = senderConfiguration.getHttpVersion();
        if (Constants.HTTP_2_0.equals(httpVersion)) {
            http2 = true;
        }
        connection = new DefaultHttp2Connection(false);
        clientFrameListener = new ClientFrameListener();
        Http2FrameListener frameListener = new DelegatingDecompressorFrameListener(connection, clientFrameListener);

        Http2ConnectionHandlerBuilder connectionHandlerBuilder = new Http2ConnectionHandlerBuilder();
        if (httpTraceLogEnabled) {
            connectionHandlerBuilder.frameLogger(new FrameLogger(TRACE, Constants.TRACE_LOG_UPSTREAM));
        }
        connectionHandlerBuilder.initialSettings().initialWindowSize(senderConfiguration.getHttp2InitialWindowSize());
        http2ConnectionHandler = connectionHandlerBuilder.connection(connection).frameListener(frameListener).build();
        http2TargetHandler = new Http2TargetHandler(connection, http2ConnectionHandler.encoder());
        http2TargetHandler.setHttpClientChannelInitializer(this);
        if (sslConfig != null) {
            sslHandlerFactory = new SSLHandlerFactory(sslConfig);
        }
    }

    @Override
    protected void initChannel(SocketChannel socketChannel) throws Exception {
        // Add the generic handlers to the pipeline
        // e.g. SSL handler
        ChannelPipeline clientPipeline = socketChannel.pipeline();
        configureProxyServer(clientPipeline);
        targetHandler = new TargetHandler();
        targetHandler.setHttp2TargetHandler(http2TargetHandler);
        targetHandler.setKeepAliveConfig(getKeepAliveConfig());
        targetHandler.setHttpClientChannelInitializer(this);
        if (http2) {
            if (sslConfig != null) {
                configureSslForHttp2(socketChannel, clientPipeline, sslConfig);
            } else if (senderConfiguration.isForceHttp2()) {
                configureHttp2Pipeline(clientPipeline);
            } else {
                configureHttp2UpgradePipeline(clientPipeline, targetHandler);
            }
        } else {
            if (sslConfig != null) {
                connectionAvailabilityFuture.setSSLEnabled(true);
                SSLEngine sslEngine = Util
                        .configureHttpPipelineForSSL(socketChannel, httpRoute.getHost(), httpRoute.getPort(),
                                sslConfig);
                Util.setAlpnProtocols(sslEngine);
                clientPipeline.addLast(Constants.SSL_COMPLETION_HANDLER,
                        new SslHandshakeCompletionHandlerForClient(connectionAvailabilityFuture, this, targetHandler,
                                sslEngine));
            } else {
                configureHttpPipeline(clientPipeline, targetHandler);
            }
            clientPipeline.addLast(Constants.HTTP_EXCEPTION_HANDLER, new HttpExceptionHandler());
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        if (LOG.isWarnEnabled()) {
            LOG.warn("Failed to initialize a channel. Closing: " + ctx.channel(), cause);
        }
        connectionAvailabilityFuture.notifyFailure(cause);
        ctx.close();
    }

    // Use netty proxy handler only if scheme is https
    private void configureProxyServer(ChannelPipeline clientPipeline) {
        if (proxyServerConfiguration != null && sslConfig != null) {
            if (proxyServerConfiguration.getProxyUsername() != null
                    && proxyServerConfiguration.getProxyPassword() != null) {
                clientPipeline.addLast(Constants.PROXY_HANDLER,
                        new HttpProxyHandler(proxyServerConfiguration.getInetSocketAddress(),
                                proxyServerConfiguration.getProxyUsername(),
                                proxyServerConfiguration.getProxyPassword()));
            } else {
                clientPipeline.addLast(Constants.PROXY_HANDLER,
                        new HttpProxyHandler(proxyServerConfiguration.getInetSocketAddress()));
            }
        }
    }

    private void configureSslForHttp2(SocketChannel ch, ChannelPipeline clientPipeline, SSLConfig sslConfig)
            throws Exception {
        connectionAvailabilityFuture.setSSLEnabled(true);
        if (sslConfig.isOcspStaplingEnabled()) {
            ReferenceCountedOpenSslContext referenceCountedOpenSslContext =
                    (ReferenceCountedOpenSslContext) sslHandlerFactory.
                            createHttp2TLSContextForClient(sslConfig.isOcspStaplingEnabled());
            if (referenceCountedOpenSslContext != null) {
                SslHandler sslHandler = referenceCountedOpenSslContext.newHandler(ch.alloc());
                ReferenceCountedOpenSslEngine engine = (ReferenceCountedOpenSslEngine) sslHandler.engine();
                setSslHandshakeTimeOut(sslConfig, sslHandler);
                ch.pipeline().addLast(sslHandler);
                ch.pipeline().addLast(new OCSPStaplingHandler(engine));
            }
        } else if (sslConfig.isDisableSsl()) {
            SslContext sslCtx = Util.createInsecureSslEngineForHttp2(sslConfig);
            SslHandler sslHandler = sslCtx.newHandler(ch.alloc(), httpRoute.getHost(), httpRoute.getPort());
            clientPipeline.addLast(sslHandler);
        } else {
            sslHandlerFactory.createSSLContextFromKeystores(false);
            SslContext sslCtx = sslHandlerFactory.createHttp2TLSContextForClient(false);
            SslHandler sslHandler = sslCtx.newHandler(ch.alloc(), httpRoute.getHost(), httpRoute.getPort());
            SSLEngine sslEngine = sslHandler.engine();
            sslHandlerFactory.setSNIServerNames(sslEngine, httpRoute.getHost());
            if (sslConfig.isHostNameVerificationEnabled()) {
                setHostNameVerfication(sslEngine);
            }
            setSslHandshakeTimeOut(sslConfig, sslHandler);
            clientPipeline.addLast(sslHandler);
            if (sslConfig.isValidateCertEnabled()) {
                clientPipeline.addLast(Constants.HTTP_CERT_VALIDATION_HANDLER,
                        new CertificateValidationHandler(sslEngine, sslConfig.getCacheValidityPeriod(),
                                sslConfig.getCacheSize()));
            }
        }
        clientPipeline.addLast(
                new ALPNClientHandler(targetHandler, connectionAvailabilityFuture));
        clientPipeline
                .addLast(Constants.HTTP2_EXCEPTION_HANDLER, new Http2ExceptionHandler(http2ConnectionHandler));
    }

    public boolean isHttpAccessLogEnabled() {
        return httpAccessLogEnabled;
    }

    public TargetHandler getTargetHandler() {
        return targetHandler;
    }

    public Http2ConnectionManager getHttp2ConnectionManager() {
        return http2ConnectionManager;
    }

    public SSLConfig getSslConfig() {
        return sslConfig;
    }

    /**
     * Creates the pipeline for handing http2 upgrade.
     *
     * @param pipeline      the client channel pipeline
     * @param targetHandler the target handler
     */
    private void configureHttp2UpgradePipeline(ChannelPipeline pipeline, TargetHandler targetHandler) {
        HttpClientCodec sourceCodec = new HttpClientCodec(responseSizeValidationConfig.getMaxInitialLineLength(),
                                                          responseSizeValidationConfig.getMaxHeaderSize(),
                                                          responseSizeValidationConfig.getMaxChunkSize());
        pipeline.addLast(Constants.HTTP_CLIENT_CODEC, sourceCodec);
        addCommonHandlers(pipeline);
        Http2ClientUpgradeCodec upgradeCodec = new Http2ClientUpgradeCodec(http2ConnectionHandler);
        DefaultHttpClientUpgradeHandler upgradeHandler = new DefaultHttpClientUpgradeHandler(sourceCodec, upgradeCodec,
                                                                                             Integer.MAX_VALUE);
        pipeline.addLast(Constants.HTTP2_UPGRADE_HANDLER, upgradeHandler);
        addResponseLimitValidationHandlers(pipeline);
        pipeline.addLast(Constants.TARGET_HANDLER, targetHandler);
    }

    /**
     * Creates the pipeline for http2 requests which does not involve a connection upgrade.
     *
     * @param pipeline the client channel pipeline
     */
    private void configureHttp2Pipeline(ChannelPipeline pipeline) {
        Util.safelyRemoveHandlers(pipeline, Constants.HTTP2_EXCEPTION_HANDLER);
        pipeline.addLast(Constants.CONNECTION_HANDLER, http2ConnectionHandler);
        pipeline.addLast(Constants.HTTP2_TARGET_HANDLER, http2TargetHandler);
        pipeline.addLast(Constants.DECOMPRESSOR_HANDLER, new HttpContentDecompressor());
        pipeline.addLast(Constants.HTTP2_EXCEPTION_HANDLER, new Http2ExceptionHandler(http2ConnectionHandler));
    }

    /**
     * Creates pipeline for http requests.
     *
     * @param pipeline      the client channel pipeline
     * @param targetHandler the target handler
     */
    public void configureHttpPipeline(ChannelPipeline pipeline, TargetHandler targetHandler) {
        HttpClientCodec clientCodec = new HttpClientCodec(responseSizeValidationConfig.getMaxInitialLineLength(),
                                                          responseSizeValidationConfig.getMaxHeaderSize(),
                                                          responseSizeValidationConfig.getMaxChunkSize());
        pipeline.addLast(Constants.HTTP_CLIENT_CODEC, clientCodec);
        addCommonHandlers(pipeline);
        addResponseLimitValidationHandlers(pipeline);
        pipeline.addLast(Constants.BACK_PRESSURE_HANDLER, new BackPressureHandler());
        pipeline.addLast(Constants.TARGET_HANDLER, targetHandler);
    }

    private void addResponseLimitValidationHandlers(ChannelPipeline pipeline) {
        pipeline.addLast(Constants.STATUS_LINE_HEADER_LENGTH_VALIDATION_HANDLER,
                         new StatusLineAndHeaderLengthValidator());
        if (responseSizeValidationConfig.getMaxEntityBodySize() > -1) {
            pipeline.addLast(MAX_ENTITY_BODY_VALIDATION_HANDLER,
                             new ResponseEntityBodySizeValidator(responseSizeValidationConfig.getMaxEntityBodySize()));
        }
    }

    /**
     * Add common handlers used in both http2 and http.
     *
     * @param pipeline the client channel pipeline
     */
    private void addCommonHandlers(ChannelPipeline pipeline) {
        pipeline.addLast(Constants.DECOMPRESSOR_HANDLER, new HttpContentDecompressor());
        if (httpTraceLogEnabled) {
            pipeline.addLast(Constants.HTTP_TRACE_LOG_HANDLER,
                    new HttpTraceLoggingHandler(Constants.TRACE_LOG_UPSTREAM));
        }
    }

    /**
     * Gets the associated {@link Http2Connection}.
     *
     * @return the associated {@code Http2Connection}
     */
    public Http2Connection getConnection() {
        return connection;
    }

    public KeepAliveConfig getKeepAliveConfig() {
        return keepAliveConfig;
    }

    public void setHttp2ClientChannel(Http2ClientChannel http2ClientChannel) {
        http2TargetHandler.setHttp2ClientChannel(http2ClientChannel);
        clientFrameListener.setHttp2ClientChannel(http2ClientChannel);
    }

    /**
     * A handler to create the pipeline based on the ALPN negotiated protocol.
     */
    class ALPNClientHandler extends ApplicationProtocolNegotiationHandler {

        private TargetHandler targetHandler;
        private ConnectionAvailabilityFuture connectionAvailabilityFuture;

        public ALPNClientHandler(TargetHandler targetHandler,
                                 ConnectionAvailabilityFuture connectionAvailabilityFuture) {
            super(ApplicationProtocolNames.HTTP_1_1);
            this.targetHandler = targetHandler;
            this.connectionAvailabilityFuture = connectionAvailabilityFuture;
        }

        @Override
        public void channelInactive(ChannelHandlerContext ctx) throws Exception {
            connectionAvailabilityFuture.notifyFailure(new ClosedChannelException());
            ctx.close();
        }

        /**
         *  Configure pipeline after TLS handshake.
         */
        @Override
        protected void configurePipeline(ChannelHandlerContext ctx, String protocol) {
            if (ApplicationProtocolNames.HTTP_2.equals(protocol)) {
                configureHttp2Pipeline(ctx.pipeline());
                connectionAvailabilityFuture.notifySuccess(Constants.HTTP2_TLS_PROTOCOL);
            } else if (ApplicationProtocolNames.HTTP_1_1.equals(protocol)) {
                // handles pipeline for HTTP/1.x requests after SSL handshake
                configureHttpPipeline(ctx.pipeline(), targetHandler);
                connectionAvailabilityFuture.notifySuccess(Constants.HTTP1_TLS_PROTOCOL);
            } else {
                throw new IllegalStateException("Unknown protocol: " + protocol);
            }
        }

        @Override
        protected void handshakeFailure(ChannelHandlerContext ctx, Throwable cause) {
            if (cause.toString().contains(SSL) || cause.toString().contains(SECURITY)) {
                while (cause.getCause() != null && cause.getCause() != cause) {
                    cause = cause.getCause();
                }
            }
            connectionAvailabilityFuture.notifyFailure(cause);
            ctx.close();
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {

            if (ctx != null) {
                if (ctx.channel().isActive()) {
                    ctx.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
                } else {
                    connectionAvailabilityFuture.notifyFailure(cause);
                    ctx.close();
                }
            }
        }
    }
}
