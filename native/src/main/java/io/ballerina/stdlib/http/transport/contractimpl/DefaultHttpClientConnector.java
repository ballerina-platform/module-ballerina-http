/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogMessage;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.ForwardedExtensionConfig;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.listener.SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http2.Http2SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.ConnectionAvailabilityListener;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.BootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.TargetChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientTimeoutHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.OutboundMsgHolder;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.RequestWriteStarter;
import io.ballerina.stdlib.http.transport.contractimpl.sender.states.SendingHeaders;
import io.ballerina.stdlib.http.transport.message.ClientRemoteFlowControlListener;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.Http2Reset;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.EventLoopGroup;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http2.Http2CodecUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.Calendar;
import java.util.NoSuchElementException;

import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGE;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_OUTBOUND_REQUEST;

/**
 * Implementation of the client connector.
 */
public class DefaultHttpClientConnector implements HttpClientConnector {

    private static final Logger LOG = LoggerFactory.getLogger(HttpClientConnector.class);

    private ConnectionManager connectionManager;
    private Http2ConnectionManager http2ConnectionManager;
    private SenderConfiguration senderConfiguration;
    private SSLConfig sslConfig;
    private int socketIdleTimeout;
    private String httpVersion;
    private ChunkConfig chunkConfig;
    private boolean http2;
    private ForwardedExtensionConfig forwardedExtensionConfig;
    private EventLoopGroup clientEventGroup;
    private BootstrapConfiguration bootstrapConfig;
    private int configHashCode;

    public DefaultHttpClientConnector(ConnectionManager connectionManager, SenderConfiguration senderConfiguration,
                                      BootstrapConfiguration bootstrapConfig, EventLoopGroup clientEventGroup,
                                      int configHashCode) {
        this.connectionManager = connectionManager;
        this.http2ConnectionManager = connectionManager.getHttp2ConnectionManager();
        this.senderConfiguration = senderConfiguration;
        initTargetChannelProperties(senderConfiguration);
        if (Constants.HTTP_2_0.equals(senderConfiguration.getHttpVersion())) {
            http2 = true;
        }
        this.clientEventGroup = clientEventGroup;
        this.bootstrapConfig = bootstrapConfig;
        this.configHashCode = configHashCode;
    }

    @Override
    public HttpResponseFuture connect() {
        return null;
    }

    @Override
    public HttpResponseFuture getResponse(ResponseHandle responseHandle) {
        return responseHandle.getOutboundMsgHolder().getResponseFuture();
    }

    @Override
    public HttpResponseFuture getNextPushPromise(ResponseHandle responseHandle) {
        return responseHandle.getOutboundMsgHolder().getResponseFuture();
    }

    @Override
    public HttpResponseFuture hasPushPromise(ResponseHandle responseHandle) {
        return responseHandle.getOutboundMsgHolder().getResponseFuture();
    }

    @Override
    public void rejectPushResponse(Http2PushPromise pushPromise) {
        Http2Reset http2Reset = new Http2Reset(pushPromise.getPromisedStreamId());
        OutboundMsgHolder outboundMsgHolder = pushPromise.getOutboundMsgHolder();
        pushPromise.reject();
        outboundMsgHolder.getHttp2ClientChannel().getChannel().write(http2Reset);
    }

    @Override
    public HttpResponseFuture getPushResponse(Http2PushPromise pushPromise) {
        OutboundMsgHolder outboundMsgHolder = pushPromise.getOutboundMsgHolder();
        if (pushPromise.isRejected()) {
            outboundMsgHolder.getResponseFuture().
                    notifyPushResponse(pushPromise.getPromisedStreamId(),
                                       new ClientConnectorException("Cannot fetch a response for an rejected promise",
                                                                    HttpResponseStatus.BAD_REQUEST.code()));
        }
        return outboundMsgHolder.getResponseFuture();
    }

    @Override
    public boolean close() {
        return false;
    }

    @Override
    public HttpResponseFuture send(HttpCarbonMessage httpOutboundRequest) {
        OutboundMsgHolder outboundMsgHolder = new OutboundMsgHolder(httpOutboundRequest);
        return send(outboundMsgHolder, httpOutboundRequest);
    }

    public HttpResponseFuture send(OutboundMsgHolder outboundMsgHolder, HttpCarbonMessage httpOutboundRequest) {
        if (senderConfiguration.isHttpAccessLogEnabled()) {
            HttpAccessLogMessage outboundAccessLogMessage = new HttpAccessLogMessage();
            outboundAccessLogMessage.setDateTime(Calendar.getInstance());
            httpOutboundRequest.setProperty(OUTBOUND_ACCESS_LOG_MESSAGE, outboundAccessLogMessage);
        }

        final HttpResponseFuture httpResponseFuture;

        Object sourceHandlerObject = httpOutboundRequest.getProperty(Constants.SRC_HANDLER);
        SourceHandler srcHandler = null;
        Http2SourceHandler http2SourceHandler = null;

        if (sourceHandlerObject != null) {
            if (sourceHandlerObject instanceof SourceHandler) {
                srcHandler = (SourceHandler) sourceHandlerObject;
            } else if (sourceHandlerObject instanceof Http2SourceHandler) {
                http2SourceHandler = (Http2SourceHandler) sourceHandlerObject;
            }
        }

        //Cannot directly assign srcHandler and http2SourceHandler to inner class ConnectionAvailabilityListener hence
        //need two new separate variables
        final SourceHandler http1xSrcHandler = srcHandler;
        final Http2SourceHandler http2SrcHandler = http2SourceHandler;

        if (srcHandler == null && http2SourceHandler == null && LOG.isDebugEnabled()) {
            LOG.debug(Constants.SRC_HANDLER + " property not found in the message."
                              + " Message is not originated from the HTTP Server connector");
        }

        try {
            /*
             * First try to get a channel from the http2 connection manager. If it is not available
             * get the channel from the http connection manager. Http2 connection manager never create new channels,
             * rather http connection manager create new connections and handover to the http2 connection manager
             * in case of the connection get upgraded to a HTTP/2 connection.
             */
            final HttpRoute route = getTargetRoute(senderConfiguration.getScheme(), httpOutboundRequest,
                                                   this.configHashCode);
            if (http2) {
                // See whether an already upgraded HTTP/2 connection is available
                Http2ClientChannel activeHttp2ClientChannel = http2ConnectionManager.fetchChannel(route);

                if (activeHttp2ClientChannel != null) {
                    outboundMsgHolder.setHttp2ClientChannel(activeHttp2ClientChannel);
                    setHttp2ForwardedExtension(outboundMsgHolder);
                    new RequestWriteStarter(outboundMsgHolder, activeHttp2ClientChannel).startWritingContent();
                    httpResponseFuture = outboundMsgHolder.getResponseFuture();
                    httpResponseFuture.notifyResponseHandle(new ResponseHandle(outboundMsgHolder));
                    return httpResponseFuture;
                }
            }

            // Look for the connection from http connection manager
            TargetChannel targetChannel = connectionManager.borrowTargetChannel(route, srcHandler, http2SourceHandler,
                                                                                senderConfiguration,
                                                                                bootstrapConfig, clientEventGroup);
            Http2ClientChannel freshHttp2ClientChannel = targetChannel.getHttp2ClientChannel();
            outboundMsgHolder.setHttp2ClientChannel(freshHttp2ClientChannel);
            httpResponseFuture = outboundMsgHolder.getResponseFuture();

            targetChannel.getConnectionReadyFuture().setListener(new ConnectionAvailabilityListener() {
                @Override
                public void onSuccess(String protocol, ChannelFuture channelFuture) {
                    if (LOG.isDebugEnabled()) {
                        LOG.debug("Created the connection to address: {}",
                                  route + " Original Channel ID is : " + channelFuture.channel().id());
                    }

                    if (isH1c(protocol)) {
                        switchEventLoopForH1c(channelFuture).addListener(future ->
                                        startExecutingOutboundRequest(protocol, channelFuture));

                    } else if (isH2c(protocol)) {
                        switchEventLoopForH2c(channelFuture).addListener(future ->
                                        startExecutingOutboundRequest(protocol, channelFuture));
                    } else {
                        startExecutingOutboundRequest(protocol, channelFuture);
                    }
                }

                private void startExecutingOutboundRequest(String protocol, ChannelFuture channelFuture) {
                    if (protocol.equalsIgnoreCase(Constants.HTTP2_CLEARTEXT_PROTOCOL)
                            || protocol.equalsIgnoreCase(Constants.HTTP2_TLS_PROTOCOL)) {
                        prepareTargetChannelForHttp2();
                    } else {
                        // Response for the upgrade request will arrive in stream 1,
                        // so use 1 as the stream id.
                        if (protocol.equalsIgnoreCase(Constants.HTTP1_TLS_PROTOCOL)) {
                            connectionManager.getHttp2ConnectionManager().releasePerRoutePoolLatch(targetChannel
                                    .getHttpRoute());
                            http2 = false;
                        }
                        prepareTargetChannelForHttp(channelFuture);
                        if ((protocol.equalsIgnoreCase(Constants.HTTP1_CLEARTEXT_PROTOCOL) ||
                                protocol.equalsIgnoreCase(Constants.HTTP1_TLS_PROTOCOL)) &&
                                senderConfiguration.getProxyServerConfiguration() != null) {
                            httpOutboundRequest.setProperty(Constants.IS_PROXY_ENABLED, true);
                        }
                        targetChannel.writeContent(httpOutboundRequest);
                    }
                }

                private void prepareTargetChannelForHttp2() {
                    freshHttp2ClientChannel.setSocketIdleTimeout(socketIdleTimeout);
                    connectionManager.getHttp2ConnectionManager().addHttp2ClientChannel(route, freshHttp2ClientChannel);
                    freshHttp2ClientChannel.getConnection().remote().flowController().listener(
                            new ClientRemoteFlowControlListener(freshHttp2ClientChannel));
                    freshHttp2ClientChannel.addDataEventListener(
                            Constants.IDLE_STATE_HANDLER,
                            new Http2ClientTimeoutHandler(socketIdleTimeout, freshHttp2ClientChannel));
                    setHttp2ForwardedExtension(outboundMsgHolder);
                    new RequestWriteStarter(outboundMsgHolder, freshHttp2ClientChannel).startWritingContent();
                    httpResponseFuture.notifyResponseHandle(new ResponseHandle(outboundMsgHolder));
                }

                private void prepareTargetChannelForHttp(ChannelFuture channelFuture) {
                    // Response for the upgrade request will arrive in stream 1,
                    // so use 1 as the stream id.
                    freshHttp2ClientChannel.putInFlightMessage(Http2CodecUtil.HTTP_UPGRADE_STREAM_ID,
                            outboundMsgHolder);
                    httpResponseFuture.notifyResponseHandle(new ResponseHandle(outboundMsgHolder));
                    targetChannel.getHttp2ClientChannel().setSocketIdleTimeout(socketIdleTimeout);

                    Channel targetNettyChannel = channelFuture.channel();

                    initializeSenderReqRespStateMgr(targetNettyChannel);

                    targetChannel.setChannel(targetNettyChannel);
                    targetChannel.configTargetHandler(httpOutboundRequest, httpResponseFuture);
                    httpResponseFuture.setBackPressureObservable(targetChannel.getBackPressureObservable());
                    Util.setCorrelationIdForLogging(targetNettyChannel.pipeline(), targetChannel.getCorrelatedSource());

                    Util.handleOutboundConnectionHeader(senderConfiguration, httpOutboundRequest);
                    String localAddress =
                            ((InetSocketAddress) targetNettyChannel.localAddress()).getAddress().getHostAddress();
                    Util.setForwardedExtension(forwardedExtensionConfig, localAddress, httpOutboundRequest);
                }

                private void initializeSenderReqRespStateMgr(Channel targetNettyChannel) {
                    SenderReqRespStateManager senderReqRespStateManager =
                            new SenderReqRespStateManager(targetNettyChannel, socketIdleTimeout);
                    senderReqRespStateManager.state =
                            new SendingHeaders(senderReqRespStateManager, targetChannel, httpVersion,
                                               chunkConfig, httpResponseFuture);
                    targetChannel.senderReqRespStateManager = senderReqRespStateManager;
                }

                // Switching is done to make sure, inbound request/response and the outbound request/response
                // are handle on the same thread and thereby avoid the need for locks
                private ChannelFuture switchEventLoopForH1c(ChannelFuture channelFuture) {
                    return channelFuture.channel().deregister()
                            .addListener(future -> http1xSrcHandler.getEventLoop().register(channelFuture.channel()));
                }

                private ChannelFuture switchEventLoopForH2c(ChannelFuture channelFuture) {
                    return channelFuture.channel().deregister().addListener(future ->
                            http2SrcHandler.getChannelHandlerContext().channel().eventLoop()
                                    .register(channelFuture.channel()));
                }

                private boolean isH1c(String protocol) {
                    return Constants.HTTP_SCHEME.equalsIgnoreCase(protocol) && http1xSrcHandler != null;
                }

                private boolean isH2c(String protocol) {
                    return Constants.HTTP_SCHEME.equalsIgnoreCase(protocol) && http2SrcHandler != null;
                }

                @Override
                public void onFailure(ClientConnectorException cause) {
                    httpResponseFuture.notifyHttpListener(cause);
                    httpOutboundRequest
                            .setIoException(new IOException(REMOTE_SERVER_CLOSED_BEFORE_INITIATING_OUTBOUND_REQUEST));
                    connectionManager.getHttp2ConnectionManager().releasePerRoutePoolLatch(route);
                }
            });
        } catch (NoSuchElementException failedCause) {
            if ("Timeout waiting for idle object".equals(failedCause.getMessage())) {
                failedCause = new NoSuchElementException(Constants.MAXIMUM_WAIT_TIME_EXCEED);
            }
            return notifyListenerAndGetErrorResponseFuture(failedCause);
        } catch (Exception failedCause) {
            return notifyListenerAndGetErrorResponseFuture(failedCause);
        }
        return httpResponseFuture;
    }

    private void setHttp2ForwardedExtension(OutboundMsgHolder outboundMsgHolder) {
        String localAddress = ((InetSocketAddress) outboundMsgHolder.getHttp2ClientChannel().getChannel()
                .localAddress()).getAddress().getHostAddress();
        Util.setForwardedExtension(this.forwardedExtensionConfig, localAddress,
                outboundMsgHolder.getRequest());
    }

    private HttpResponseFuture notifyListenerAndGetErrorResponseFuture(Exception failedCause) {
        HttpResponseFuture errorResponseFuture = new DefaultHttpResponseFuture();
        errorResponseFuture.notifyHttpListener(failedCause);
        return errorResponseFuture;
    }

    private HttpRoute getTargetRoute(String scheme, HttpCarbonMessage httpCarbonMessage, int configHashCode) {
        String host = fetchHost(httpCarbonMessage);
        int port = fetchPort(httpCarbonMessage);

        return new HttpRoute(scheme, host, port, configHashCode);
    }

    private int fetchPort(HttpCarbonMessage httpCarbonMessage) {
        int port;
        Object intProperty = httpCarbonMessage.getProperty(Constants.HTTP_PORT);
        if (intProperty instanceof Integer) {
            port = (int) intProperty;
        } else {
            port = sslConfig != null ? Constants.DEFAULT_HTTPS_PORT : Constants.DEFAULT_HTTP_PORT;
            httpCarbonMessage.setProperty(Constants.HTTP_PORT, port);
            LOG.debug("Cannot find property PORT of type integer, hence using {}", port);
        }
        return port;
    }

    private String fetchHost(HttpCarbonMessage httpCarbonMessage) {
        String host;
        Object hostProperty = httpCarbonMessage.getProperty(Constants.HTTP_HOST);
        if (hostProperty instanceof String) {
            host = (String) hostProperty;
        } else {
            host = Constants.LOCALHOST;
            httpCarbonMessage.setProperty(Constants.HTTP_HOST, Constants.LOCALHOST);
            LOG.debug("Cannot find property HOST of type string, hence using localhost as the host");
        }
        return host;
    }

    private void initTargetChannelProperties(SenderConfiguration senderConfiguration) {
        this.httpVersion = senderConfiguration.getHttpVersion();
        this.chunkConfig = senderConfiguration.getChunkingConfig();
        this.socketIdleTimeout = senderConfiguration.getSocketIdleTimeout(Constants.ENDPOINT_TIMEOUT);
        this.sslConfig = senderConfiguration.getClientSSLConfig();
        this.forwardedExtensionConfig = senderConfiguration.getForwardedExtensionConfig();
    }
}
