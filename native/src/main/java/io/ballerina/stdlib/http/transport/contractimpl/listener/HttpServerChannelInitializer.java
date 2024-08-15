/*
 *  Copyright (c) 2017 WSO2 Inc. (http://wso2.com) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.InboundMsgSizeValidationConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.certificatevalidation.CertificateVerificationException;
import io.ballerina.stdlib.http.transport.contractimpl.common.http2.Http2ExceptionHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLHandlerFactory;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceConnectionHandlerBuilder;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2ToHttpFallbackHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2WithPriorKnowledgeHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.CertificateValidationHandler;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.handler.codec.http.HttpRequestDecoder;
import io.netty.handler.codec.http.HttpResponseEncoder;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.HttpServerUpgradeHandler;
import io.netty.handler.codec.http2.Http2CodecUtil;
import io.netty.handler.codec.http2.Http2ServerUpgradeCodec;
import io.netty.handler.ssl.ApplicationProtocolNames;
import io.netty.handler.ssl.ApplicationProtocolNegotiationHandler;
import io.netty.handler.ssl.OpenSsl;
import io.netty.handler.ssl.ReferenceCountedOpenSslContext;
import io.netty.handler.ssl.ReferenceCountedOpenSslEngine;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslHandler;
import io.netty.handler.stream.ChunkedWriteHandler;
import io.netty.handler.timeout.IdleStateHandler;
import io.netty.util.AsciiString;
import io.netty.util.concurrent.EventExecutorGroup;
import org.bouncycastle.cert.ocsp.OCSPResp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.security.KeyStoreException;
import java.security.cert.CertificateException;
import java.util.Objects;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_TRACE_LOG_HANDLER;
import static io.ballerina.stdlib.http.transport.contract.Constants.MAX_ENTITY_BODY_VALIDATION_HANDLER;
import static io.ballerina.stdlib.http.transport.contract.Constants.SECURITY;
import static io.ballerina.stdlib.http.transport.contract.Constants.SSL;
import static io.ballerina.stdlib.http.transport.contract.Constants.TRACE_LOG_DOWNSTREAM;
import static io.ballerina.stdlib.http.transport.contract.Constants.URI_HEADER_LENGTH_VALIDATION_HANDLER;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.setSslHandshakeTimeOut;

/**
 * A class that responsible for build server side channels.
 */
public class HttpServerChannelInitializer extends ChannelInitializer<SocketChannel> {

    private static final Logger LOG = LoggerFactory.getLogger(HttpServerChannelInitializer.class);

    private long socketIdleTimeout;
    private boolean httpTraceLogEnabled;
    private boolean httpAccessLogEnabled;
    private ChunkConfig chunkConfig;
    private KeepAliveConfig keepAliveConfig;
    private String interfaceId;
    private String serverName;
    private SSLConfig sslConfig;
    private SSLHandlerFactory sslHandlerFactory;
    private SSLContext keystoreSslContext;
    private SslContext keystoreHttp2SslContext;
    private SslContext certAndKeySslContext;
    private ServerConnectorFuture serverConnectorFuture;
    private InboundMsgSizeValidationConfig reqSizeValidationConfig;
    private boolean http2Enabled = false;
    private boolean validateCertEnabled;
    private int cacheDelay;
    private int cacheSize;
    private ChannelGroup allChannels;
    private ChannelGroup listenerChannels;
    private boolean ocspStaplingEnabled = false;
    private boolean pipeliningEnabled;
    private long pipeliningLimit;
    private EventExecutorGroup pipeliningGroup;
    private boolean webSocketCompressionEnabled;
    private int http2InitialWindowSize;
    private long minIdleTimeInStaleState;
    private long timeBetweenStaleEviction;
    private final BlockingQueue<Http2SourceHandler> http2StaleSourceHandlers = new LinkedBlockingQueue<>();
    Timer timer;

    @Override
    public void initChannel(SocketChannel ch) throws Exception {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Initializing source channel pipeline");
        }
        ChannelPipeline serverPipeline = ch.pipeline();

        if (http2Enabled) {
            if (sslHandlerFactory != null) {
                if (ocspStaplingEnabled) {
                    OCSPResp response = getOcspResponse();

                    ReferenceCountedOpenSslContext context = (ReferenceCountedOpenSslContext) keystoreHttp2SslContext;
                    SslHandler sslHandler = context.newHandler(ch.alloc());

                    ReferenceCountedOpenSslEngine engine = (ReferenceCountedOpenSslEngine) sslHandler.engine();
                    engine.setOcspResponse(response.getEncoded());
                    setSslHandshakeTimeOut(sslConfig, sslHandler);
                    ch.pipeline()
                            .addLast(sslHandler, new Http2PipelineConfiguratorForServer(this, sslHandler.engine()));
                } else {
                    SslHandler sslHandler = keystoreHttp2SslContext.newHandler(ch.alloc());
                    setSslHandshakeTimeOut(sslConfig, sslHandler);
                    serverPipeline
                            .addLast(sslHandler, new Http2PipelineConfiguratorForServer(this, sslHandler.engine()));
                    serverPipeline.addLast(Constants.HTTP2_EXCEPTION_HANDLER, new Http2ExceptionHandler());
                }
            } else {
                configureH2cPipeline(serverPipeline);
            }
            initiateHttp2ConnectionEvictionTask();
        } else {
            if (sslHandlerFactory != null) {
                configureSslForHttp(serverPipeline, ch);
            } else {
                configureHttpPipeline(serverPipeline, Constants.HTTP_SCHEME);
            }
        }
    }

    private OCSPResp getOcspResponse()
            throws IOException, KeyStoreException, CertificateVerificationException, CertificateException {
        OCSPResp response = OCSPResponseBuilder.generateOcspResponse(sslConfig, cacheSize, cacheDelay);
        if (!OpenSsl.isAvailable()) {
            throw new IllegalStateException("OpenSSL is not available!");
        }
        if (!OpenSsl.isOcspSupported()) {
            throw new IllegalStateException("OCSP is not supported!");
        }
        return response;
    }

    private void configureSslForHttp(ChannelPipeline serverPipeline, SocketChannel ch)
            throws CertificateVerificationException, KeyStoreException, IOException, CertificateException {
        SSLEngine sslEngine;
        SslHandler sslHandler;
        if (ocspStaplingEnabled) {
            OCSPResp response = getOcspResponse();

            ReferenceCountedOpenSslContext context = sslHandlerFactory
                    .getServerReferenceCountedOpenSslContext(ocspStaplingEnabled);
            sslHandler = context.newHandler(ch.alloc());
            sslEngine = sslHandler.engine();
            Util.setAlpnProtocols(sslEngine);

            ReferenceCountedOpenSslEngine engine = (ReferenceCountedOpenSslEngine) sslEngine;
            engine.setOcspResponse(response.getEncoded());
            setSslHandshakeTimeOut(sslConfig, sslHandler);
            ch.pipeline().addLast(sslHandler);
        } else {
            if (sslConfig.getServerKeyFile() != null) {
                sslHandler = certAndKeySslContext.newHandler(ch.alloc());
                sslEngine = sslHandler.engine();
                sslHandlerFactory.addCommonConfigs(sslEngine);
            } else {
                sslEngine = sslHandlerFactory.buildServerSSLEngine(keystoreSslContext);
            }
            Util.setAlpnProtocols(sslEngine);
            sslHandler = new SslHandler(sslEngine);
            setSslHandshakeTimeOut(sslConfig, sslHandler);
            serverPipeline.addLast(Constants.SSL_HANDLER, sslHandler);
            if (validateCertEnabled) {
                serverPipeline.addLast(Constants.HTTP_CERT_VALIDATION_HANDLER,
                        new CertificateValidationHandler(sslEngine, cacheDelay, cacheSize));
            }
        }
        serverPipeline.addLast(Constants.SSL_COMPLETION_HANDLER,
                new SslHandshakeCompletionHandlerForServer(this, serverPipeline, sslEngine));
    }

    /**
     * Configures HTTP/1.x pipeline.
     *
     * @param serverPipeline the channel pipeline
     * @param initialHttpScheme initial http scheme
     */
    public void configureHttpPipeline(ChannelPipeline serverPipeline, String initialHttpScheme) {

        if (initialHttpScheme.equals(Constants.HTTP_SCHEME)) {
            serverPipeline.addLast(Constants.HTTP_ENCODER, new HttpResponseEncoder());
            serverPipeline.addLast(Constants.HTTP_DECODER,
                                   new HttpRequestDecoder(reqSizeValidationConfig.getMaxInitialLineLength(),
                                                          reqSizeValidationConfig.getMaxHeaderSize(),
                                                          reqSizeValidationConfig.getMaxChunkSize()));

            serverPipeline.addLast(Constants.HTTP_COMPRESSOR, new CustomHttpContentCompressor());
            serverPipeline.addLast(Constants.HTTP_CHUNK_WRITER, new ChunkedWriteHandler());

            if (httpTraceLogEnabled) {
                serverPipeline.addLast(HTTP_TRACE_LOG_HANDLER, new HttpTraceLoggingHandler(TRACE_LOG_DOWNSTREAM));
            }
        }
        serverPipeline.addLast(URI_HEADER_LENGTH_VALIDATION_HANDLER, new UriAndHeaderLengthValidator(this.serverName));
        if (reqSizeValidationConfig.getMaxEntityBodySize() > -1) {
            serverPipeline.addLast(MAX_ENTITY_BODY_VALIDATION_HANDLER, new MaxEntityBodyValidator(this.serverName,
                    reqSizeValidationConfig.getMaxEntityBodySize()));
        }

        serverPipeline.addLast(Constants.WEBSOCKET_SERVER_HANDSHAKE_HANDLER,
                               new WebSocketServerHandshakeHandler(this.serverConnectorFuture,
                                                                   webSocketCompressionEnabled));
        serverPipeline.addLast(Constants.BACK_PRESSURE_HANDLER, new BackPressureHandler());
        serverPipeline.addLast(Constants.HTTP_SOURCE_HANDLER,
                               new SourceHandler(this.serverConnectorFuture, this, this.interfaceId, this.chunkConfig,
                                                 keepAliveConfig, this.serverName, this.allChannels,
                                                 this.listenerChannels, this.pipeliningEnabled, this.pipeliningLimit,
                                                 this.pipeliningGroup));
        if (socketIdleTimeout >= 0) {
            serverPipeline.addBefore(Constants.HTTP_SOURCE_HANDLER, Constants.IDLE_STATE_HANDLER,
                                     new IdleStateHandler(0, 0, socketIdleTimeout, TimeUnit.MILLISECONDS));
        }
        serverPipeline.addLast(Constants.HTTP_EXCEPTION_HANDLER, new HttpExceptionHandler());
    }

    /**
     * Configures HTTP/2 clear text pipeline.
     *
     * @param pipeline the channel pipeline
     */
    private void configureH2cPipeline(ChannelPipeline pipeline) {
        // Add handler to handle http2 requests without an upgrade
        pipeline.addLast(new Http2WithPriorKnowledgeHandler(
                interfaceId, serverName, serverConnectorFuture, this, allChannels, listenerChannels,
                reqSizeValidationConfig.getMaxHeaderSize(), http2InitialWindowSize));
        // Add http2 upgrade decoder and upgrade handler
        final HttpServerCodec sourceCodec = new HttpServerCodec(reqSizeValidationConfig.getMaxInitialLineLength(),
                                                                reqSizeValidationConfig.getMaxHeaderSize(),
                                                                reqSizeValidationConfig.getMaxChunkSize());

        pipeline.addLast(Constants.HTTP_SERVER_CODEC, sourceCodec);
        pipeline.addLast(Constants.HTTP_COMPRESSOR, new CustomHttpContentCompressor());
        if (httpTraceLogEnabled) {
            pipeline.addLast(HTTP_TRACE_LOG_HANDLER,
                             new HttpTraceLoggingHandler(TRACE_LOG_DOWNSTREAM));
        }

        final HttpServerUpgradeHandler.UpgradeCodecFactory upgradeCodecFactory = protocol -> {
            if (AsciiString.contentEquals(Http2CodecUtil.HTTP_UPGRADE_PROTOCOL_NAME, protocol)) {
                return new Http2ServerUpgradeCodec(
                        Constants.HTTP2_SOURCE_CONNECTION_HANDLER,
                        new Http2SourceConnectionHandlerBuilder(
                                interfaceId, serverConnectorFuture, serverName, this,
                                this.allChannels, this.listenerChannels, reqSizeValidationConfig.getMaxHeaderSize(),
                                this.http2InitialWindowSize).build());
            } else {
                return null;
            }
        };
        /* Max size of the upgrade request is limited to 2GB. Need to see whether there is a better approach to handle
           large upgrade requests. Requests will be propagated to next handlers if no upgrade has been attempted */
        pipeline.addLast(Constants.HTTP2_UPGRADE_HANDLER,
                         new HttpServerUpgradeHandler(sourceCodec, upgradeCodecFactory, Integer.MAX_VALUE));

        pipeline.addLast(Constants.HTTP2_TO_HTTP_FALLBACK_HANDLER,
                         new Http2ToHttpFallbackHandler(this));
    }

    public void setServerConnectorFuture(ServerConnectorFuture serverConnectorFuture) {
        this.serverConnectorFuture = serverConnectorFuture;
    }

    void setIdleTimeout(long idleTimeout) {
        this.socketIdleTimeout = idleTimeout;
    }

    public long getSocketIdleTimeout() {
        return socketIdleTimeout;
    }

    void setHttpTraceLogEnabled(boolean httpTraceLogEnabled) {
        this.httpTraceLogEnabled = httpTraceLogEnabled;
    }

    void setHttpAccessLogEnabled(boolean httpAccessLogEnabled) {
        this.httpAccessLogEnabled = httpAccessLogEnabled;
    }

    public boolean isHttpTraceLogEnabled() {
        return httpTraceLogEnabled;
    }

    public boolean isHttpAccessLogEnabled() {
        return httpAccessLogEnabled;
    }

    void setInterfaceId(String interfaceId) {
        this.interfaceId = interfaceId;
    }

    void setSslConfig(SSLConfig sslConfig) {
        this.sslConfig = sslConfig;
    }

    void setSslHandlerFactory(SSLHandlerFactory sslHandlerFactory) {
        this.sslHandlerFactory = sslHandlerFactory;
    }

    void setKeystoreSslContext(SSLContext sslContext) {
        this.keystoreSslContext = sslContext;
    }

    void setHttp2SslContext(SslContext sslContext) {
        this.keystoreHttp2SslContext = sslContext;
    }

    void setCertandKeySslContext(SslContext sslContext) {
        this.certAndKeySslContext = sslContext;
    }

    void setReqSizeValidationConfig(InboundMsgSizeValidationConfig reqSizeValidationConfig) {
        this.reqSizeValidationConfig = reqSizeValidationConfig;
    }

    void setHttp2InitialWindowSize(int http2InitialWindowSize) {
        this.http2InitialWindowSize = http2InitialWindowSize;
    }

    void setTimeBetweenStaleEviction(long timeBetweenStaleEviction) {
        this.timeBetweenStaleEviction = timeBetweenStaleEviction;
    }

    void setMinIdleTimeInStaleState(long minIdleTimeInStaleState) {
        this.minIdleTimeInStaleState = minIdleTimeInStaleState;
    }

    public void setChunkingConfig(ChunkConfig chunkConfig) {
        this.chunkConfig = chunkConfig;
    }

    void setKeepAliveConfig(KeepAliveConfig keepAliveConfig) {
        this.keepAliveConfig = keepAliveConfig;
    }

    void setValidateCertEnabled(boolean validateCertEnabled) {
        this.validateCertEnabled = validateCertEnabled;
    }

    void setCacheDelay(int cacheDelay) {
        this.cacheDelay = cacheDelay;
    }

    void setCacheSize(int cacheSize) {
        this.cacheSize = cacheSize;
    }

    void setServerName(String serverName) {
        this.serverName = serverName;
    }

    void setOcspStaplingEnabled(boolean ocspStaplingEnabled) {
        this.ocspStaplingEnabled = ocspStaplingEnabled;
    }

    /**
     * Sets whether HTTP/2.0 is enabled for the connection.
     *
     * @param http2Enabled whether HTTP/2.0 is enabled
     */
    void setHttp2Enabled(boolean http2Enabled) {
        this.http2Enabled = http2Enabled;
    }

    void setPipeliningEnabled(boolean pipeliningEnabled) {
        this.pipeliningEnabled = pipeliningEnabled;
    }

    public void setPipeliningLimit(long pipeliningLimit) {
        this.pipeliningLimit = pipeliningLimit;
    }

    public void setPipeliningThreadGroup(EventExecutorGroup pipeliningGroup) {
        this.pipeliningGroup = pipeliningGroup;
    }

    public void setWebSocketCompressionEnabled(boolean webSocketCompressionEnabled) {
        this.webSocketCompressionEnabled = webSocketCompressionEnabled;
    }

    public void addToStaleChannels(Http2SourceHandler http2SourceHandler) {
        this.http2StaleSourceHandlers.add(http2SourceHandler);
    }

    /**
     * Handler which handles ALPN.
     */
    class Http2PipelineConfiguratorForServer extends ApplicationProtocolNegotiationHandler {

        private HttpServerChannelInitializer channelInitializer;
        private SSLEngine sslEngine;

        Http2PipelineConfiguratorForServer(HttpServerChannelInitializer channelInitializer, SSLEngine sslEngine) {
            super(ApplicationProtocolNames.HTTP_1_1);
            this.channelInitializer = channelInitializer;
            this.sslEngine = sslEngine;
        }

        /**
         *  Configure pipeline after SSL handshake.
         */
        @Override
        protected void configurePipeline(ChannelHandlerContext ctx, String protocol) {
            Util.setMutualSslStatus(ctx, sslEngine);
            if (ApplicationProtocolNames.HTTP_2.equals(protocol)) {
                // handles pipeline for HTTP/2 requests after SSL handshake
                ctx.pipeline().addLast(
                        Constants.HTTP2_SOURCE_CONNECTION_HANDLER,
                        new Http2SourceConnectionHandlerBuilder(
                                interfaceId, serverConnectorFuture, serverName, channelInitializer,
                                allChannels, listenerChannels, reqSizeValidationConfig.getMaxHeaderSize(),
                                http2InitialWindowSize).build());
            } else if (ApplicationProtocolNames.HTTP_1_1.equals(protocol)) {
                // handles pipeline for HTTP/1.x requests after SSL handshake
                configureHttpPipeline(ctx.pipeline(), Constants.HTTP_SCHEME);
                ctx.pipeline().fireChannelActive();
            } else {
                throw new IllegalStateException("unknown protocol: " + protocol);
            }
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {

            if (ctx != null) {
                if (ctx.channel().isActive()) {
                    ctx.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
                } else {
                    super.exceptionCaught(ctx, cause);
                }
            }
        }

        @Override
        protected void handshakeFailure(ChannelHandlerContext ctx, Throwable cause) {
            if (cause.toString().contains(SSL) || cause.toString().contains(SECURITY)) {
                while (cause.getCause() != null && cause.getCause() != cause) {
                    cause = cause.getCause();
                }
            }
            LOG.warn("{} TLS handshake failed: {}", ctx.channel(), cause.getMessage());
        }
    }

    void setAllChannels(ChannelGroup allChannels, ChannelGroup listenerChannels) {
        this.allChannels = allChannels;
        this.listenerChannels = listenerChannels;
    }

    private void initiateHttp2ConnectionEvictionTask() {
        if (Objects.nonNull(timer)) {
            return;
        }
        timer = new Timer(true);
        TimerTask timerTask = new TimerTask() {
            @Override
            public void run() {
                http2StaleSourceHandlers.forEach(http2SourceHandler -> {
                    if (minIdleTimeInStaleState == -1) {
                        if (http2SourceHandler.getStreamIdRequestMap().isEmpty()) {
                            removeChannelAndEvict(http2SourceHandler);
                        }
                    } else if ((System.currentTimeMillis() - http2SourceHandler.getTimeSinceMarkedAsStale()) >
                            minIdleTimeInStaleState) {
                        removeChannelAndEvict(http2SourceHandler);
                    }
                });
            }

            public void removeChannelAndEvict(Http2SourceHandler http2SourceHandler) {
                http2StaleSourceHandlers.remove(http2SourceHandler);
                http2SourceHandler.closeChannelAfterBecomingStale();
            }
        };
        timer.schedule(timerTask, timeBetweenStaleEviction, timeBetweenStaleEviction);
    }

    public void cancelStaleEvictionTask() {
        if (Objects.nonNull(timer)) {
            timer.cancel();
        }
    }
}
