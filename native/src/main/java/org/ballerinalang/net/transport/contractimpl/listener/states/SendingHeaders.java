/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.contractimpl.listener.states;

import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contract.ServerConnectorFuture;
import org.ballerinalang.net.transport.contract.config.ChunkConfig;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.HttpOutboundRespListener;
import org.ballerinalang.net.transport.contractimpl.common.states.StateUtil;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.ballerinalang.net.transport.contract.Constants.CHUNKING_CONFIG;
import static org.ballerinalang.net.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static org.ballerinalang.net.transport.contractimpl.common.Util.createHttpResponse;
import static org.ballerinalang.net.transport.contractimpl.common.Util.isLastHttpContent;
import static org.ballerinalang.net.transport.contractimpl.common.Util.setupChunkedRequest;
import static org.ballerinalang.net.transport.contractimpl.common.states.StateUtil.ILLEGAL_STATE_ERROR;
import static org.ballerinalang.net.transport.contractimpl.common.states.StateUtil.checkChunkingCompatibility;
import static org.ballerinalang.net.transport.contractimpl.common.states.StateUtil.notifyIfHeaderWriteFailure;

/**
 * State between start and end of outbound response headers write.
 */
public class SendingHeaders implements ListenerState {

    private static final Logger LOG = LoggerFactory.getLogger(SendingHeaders.class);

    private final HttpOutboundRespListener outboundResponseListener;
    boolean keepAlive;
    private final ListenerReqRespStateManager listenerReqRespStateManager;
    ChunkConfig chunkConfig;
    HttpResponseFuture outboundRespStatusFuture;

    public SendingHeaders(ListenerReqRespStateManager listenerReqRespStateManager,
                          HttpOutboundRespListener outboundResponseListener) {
        this.listenerReqRespStateManager = listenerReqRespStateManager;
        this.outboundResponseListener = outboundResponseListener;
        this.chunkConfig = outboundResponseListener.getChunkConfig();
        this.keepAlive = outboundResponseListener.isKeepAlive();
    }

    @Override
    public void readInboundRequestHeaders(HttpCarbonMessage inboundRequestMsg, HttpRequest inboundRequestHeaders) {
        LOG.warn("readInboundRequestHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void readInboundRequestBody(Object inboundRequestEntityBody) throws ServerConnectorException {
        LOG.warn("readInboundRequestBody {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void writeOutboundResponseBody(HttpOutboundRespListener outboundResponseListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        LOG.warn("writeOutboundResponseBody {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {
        // OutboundResponseStatusFuture will be notified asynchronously via OutboundResponseListener.
        LOG.error(REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
    }

    @Override
    public ChannelFuture handleIdleTimeoutConnectionClosure(ServerConnectorFuture serverConnectorFuture,
                                                            ChannelHandlerContext ctx) {
        // OutboundResponseStatusFuture will be notified asynchronously via OutboundResponseListener.
        LOG.error(IDLE_TIMEOUT_TRIGGERED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS);
        return null;
    }

    @Override
    public void writeOutboundResponseHeaders(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent) {
        ChunkConfig responseChunkConfig = outboundResponseMsg.getProperty(CHUNKING_CONFIG) != null ?
                (ChunkConfig) outboundResponseMsg.getProperty(CHUNKING_CONFIG) : null;
        if (responseChunkConfig != null) {
            this.setChunkConfig(responseChunkConfig);
        }
        outboundRespStatusFuture = outboundResponseListener.getInboundRequestMsg().getHttpOutboundRespStatusFuture();
        String httpVersion = outboundResponseListener.getRequestDataHolder().getHttpVersion();

        if (isLastHttpContent(httpContent)) {
            if (chunkConfig == ChunkConfig.ALWAYS && checkChunkingCompatibility(httpVersion, chunkConfig)) {
                writeHeaders(outboundResponseMsg, keepAlive, outboundRespStatusFuture);
                writeResponse(outboundResponseMsg, httpContent, true);
                return;
            }
        } else {
            if ((chunkConfig == ChunkConfig.ALWAYS || chunkConfig == ChunkConfig.AUTO) && (
                    checkChunkingCompatibility(httpVersion, chunkConfig))) {
                writeHeaders(outboundResponseMsg, keepAlive, outboundRespStatusFuture);
                writeResponse(outboundResponseMsg, httpContent, true);
                return;
            }
        }
        writeResponse(outboundResponseMsg, httpContent, false);
    }

    private void writeResponse(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent, boolean headersWritten) {
        listenerReqRespStateManager.state
                = new SendingEntityBody(listenerReqRespStateManager, outboundRespStatusFuture, headersWritten);
        listenerReqRespStateManager.writeOutboundResponseBody(outboundResponseListener, outboundResponseMsg,
                                                                         httpContent);
    }

    private void writeHeaders(HttpCarbonMessage outboundResponseMsg, boolean keepAlive,
                              HttpResponseFuture outboundRespStatusFuture) {
        setupChunkedRequest(outboundResponseMsg);
        StateUtil.addTrailerHeaderIfPresent(outboundResponseMsg);
        ChannelFuture outboundHeaderFuture = writeResponseHeaders(outboundResponseMsg, keepAlive);
        notifyIfHeaderWriteFailure(outboundRespStatusFuture, outboundHeaderFuture,
                                   REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE);
    }

    void setChunkConfig(ChunkConfig chunkConfig) {
        this.chunkConfig = chunkConfig;
    }

    ChannelFuture writeResponseHeaders(HttpCarbonMessage outboundResponseMsg, boolean keepAlive) {
        HttpResponse response = createHttpResponse(outboundResponseMsg,
                                                   outboundResponseListener.getRequestDataHolder().getHttpVersion(),
                                                   outboundResponseListener.getServerName(), keepAlive);
        return outboundResponseListener.getSourceContext().write(response);
    }
}
