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

package io.ballerina.stdlib.http.transport.contractimpl.sender.states;

import io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogConfig;
import io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogMessage;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.LastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.Calendar;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.INBOUND_MESSAGE;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_X_FORWARDED_FOR;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_STATE_HANDLER;
import static io.ballerina.stdlib.http.transport.contract.Constants.IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGE;
import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGES;
import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static io.ballerina.stdlib.http.transport.contract.Constants.TO;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isKeepAlive;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.safelyRemoveHandlers;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.ILLEGAL_STATE_ERROR;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil.handleIncompleteInboundMessage;

/**
 * State between start and end of inbound response entity body read.
 */
public class ReceivingEntityBody implements SenderState {

    private static final Logger LOG = LoggerFactory.getLogger(ReceivingEntityBody.class);

    private final SenderReqRespStateManager senderReqRespStateManager;
    private final TargetHandler targetHandler;
    private Long contentLength = 0L;

    ReceivingEntityBody(SenderReqRespStateManager senderReqRespStateManager, TargetHandler targetHandler) {
        this.senderReqRespStateManager = senderReqRespStateManager;
        this.targetHandler = targetHandler;
    }

    @Override
    public void writeOutboundRequestHeaders(HttpCarbonMessage httpOutboundRequest) {
        LOG.warn("writeOutboundRequestHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void writeOutboundRequestEntity(HttpCarbonMessage httpOutboundRequest, HttpContent httpContent) {
        LOG.warn("writeOutboundRequestEntity {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void readInboundResponseHeaders(TargetHandler targetHandler, HttpResponse httpInboundResponse) {
        LOG.warn("readInboundResponseHeaders {}", ILLEGAL_STATE_ERROR);
    }

    @Override
    public void readInboundResponseEntityBody(ChannelHandlerContext ctx, HttpContent httpContent,
                                              HttpCarbonMessage inboundResponseMsg) throws Exception {

        if (httpContent instanceof LastHttpContent) {
            StateUtil.setInboundTrailersToNewMessage(((LastHttpContent) httpContent).trailingHeaders(),
                                                     inboundResponseMsg);
            inboundResponseMsg.addHttpContent(httpContent);
            contentLength += httpContent.content().readableBytes();
            inboundResponseMsg.setLastHttpContentArrived();
            targetHandler.resetInboundMsg();
            safelyRemoveHandlers(targetHandler.getTargetChannel().getChannel().pipeline(), IDLE_STATE_HANDLER);
            if (targetHandler.getHttpClientChannelInitializer().isHttpAccessLogEnabled()) {
                updateAccessLogInfo(targetHandler, inboundResponseMsg);
            }
            senderReqRespStateManager.state = new EntityBodyReceived(senderReqRespStateManager);

            if (!isKeepAlive(targetHandler.getKeepAliveConfig(),
                    targetHandler.getOutboundRequestMsg(), inboundResponseMsg)) {
                targetHandler.closeChannel(ctx);
            }
            targetHandler.getConnectionManager().returnChannel(targetHandler.getTargetChannel());
        } else {
            inboundResponseMsg.addHttpContent(httpContent);
            contentLength += httpContent.content().readableBytes();
        }
    }

    @Override
    public void handleAbruptChannelClosure(TargetHandler targetHandler, HttpResponseFuture httpResponseFuture) {
        handleIncompleteInboundMessage(targetHandler.getInboundResponseMsg(),
                                       REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    @Override
    public void handleIdleTimeoutConnectionClosure(TargetHandler targetHandler,
                                                   HttpResponseFuture httpResponseFuture, String channelID) {
        senderReqRespStateManager.nettyTargetChannel.pipeline().remove(IDLE_STATE_HANDLER);
        senderReqRespStateManager.nettyTargetChannel.close();
        handleIncompleteInboundMessage(targetHandler.getInboundResponseMsg(),
                                       IDLE_TIMEOUT_TRIGGERED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    private void updateAccessLogInfo(TargetHandler targetHandler,
                                     HttpCarbonMessage inboundResponseMsg) {
        HttpCarbonMessage httpOutboundRequest = targetHandler.getOutboundRequestMsg();
        HttpAccessLogMessage outboundAccessLogMessage =
                getTypedProperty(httpOutboundRequest, OUTBOUND_ACCESS_LOG_MESSAGE, HttpAccessLogMessage.class);
        if (outboundAccessLogMessage == null) {
            return;
        }

        SocketAddress remoteAddress = targetHandler.getTargetChannel().getChannel().remoteAddress();
        if (remoteAddress instanceof InetSocketAddress inetSocketAddress) {
            InetAddress inetAddress = inetSocketAddress.getAddress();
            outboundAccessLogMessage.setIp(inetAddress.getHostAddress());
            outboundAccessLogMessage.setHost(inetAddress.getHostName());
            outboundAccessLogMessage.setPort(inetSocketAddress.getPort());
        }
        if (outboundAccessLogMessage.getIp().startsWith("/")) {
            outboundAccessLogMessage.setIp(outboundAccessLogMessage.getIp().substring(1));
        }

        // Populate with header parameters
        HttpHeaders headers = httpOutboundRequest.getHeaders();
        if (headers.contains(HTTP_X_FORWARDED_FOR)) {
            String forwardedHops = headers.get(HTTP_X_FORWARDED_FOR);
            outboundAccessLogMessage.setHttpXForwardedFor(forwardedHops);
            // If multiple IPs available, the first ip is the client
            int firstCommaIndex = forwardedHops.indexOf(',');
            outboundAccessLogMessage.setIp(firstCommaIndex != -1 ?
                    forwardedHops.substring(0, firstCommaIndex) : forwardedHops);
        }
        if (headers.contains(HttpHeaderNames.USER_AGENT)) {
            outboundAccessLogMessage.setHttpUserAgent(headers.get(HttpHeaderNames.USER_AGENT));
        }
        if (headers.contains(HttpHeaderNames.REFERER)) {
            outboundAccessLogMessage.setHttpReferrer(headers.get(HttpHeaderNames.REFERER));
        }
        HttpAccessLogConfig.getInstance().getCustomHeaders().forEach(customHeader ->
                outboundAccessLogMessage.putCustomHeader(customHeader, headers.contains(customHeader) ?
                        headers.get(customHeader) : "-"));

        outboundAccessLogMessage.setRequestMethod(httpOutboundRequest.getHttpMethod());
        outboundAccessLogMessage.setRequestUri((String) httpOutboundRequest.getProperty(TO));
        HttpMessage inboundResponse = inboundResponseMsg.getNettyHttpResponse();
        if (inboundResponse != null) {
            outboundAccessLogMessage.setScheme(inboundResponse.protocolVersion().toString());
        } else {
            outboundAccessLogMessage.setScheme(inboundResponseMsg.getHttpVersion());
        }
        outboundAccessLogMessage.setRequestBodySize((long) httpOutboundRequest.getContentSize());
        outboundAccessLogMessage.setStatus(inboundResponseMsg.getHttpStatusCode());
        outboundAccessLogMessage.setResponseBodySize(contentLength);
        long requestTime = Calendar.getInstance().getTimeInMillis() -
                outboundAccessLogMessage.getDateTime().getTimeInMillis();
        outboundAccessLogMessage.setRequestTime(requestTime);

        HttpCarbonMessage inboundReqMsg =
                getTypedProperty(httpOutboundRequest, INBOUND_MESSAGE, HttpCarbonMessage.class);

        if (inboundReqMsg != null) {
            List<HttpAccessLogMessage> outboundAccessLogMessages = getHttpAccessLogMessages(inboundReqMsg);
            if (outboundAccessLogMessages != null) {
                outboundAccessLogMessages.add(outboundAccessLogMessage);
            }
        }
    }

    private <T> T getTypedProperty(HttpCarbonMessage request, String propertyName, Class<T> type) {
        Object property = request.getProperty(propertyName);
        if (type.isInstance(property)) {
            return type.cast(property);
        }
        return null;
    }

    private List<HttpAccessLogMessage> getHttpAccessLogMessages(HttpCarbonMessage request) {
        Object outboundAccessLogMessagesObject = request.getProperty(OUTBOUND_ACCESS_LOG_MESSAGES);
        if (outboundAccessLogMessagesObject instanceof List<?> rawList) {
            for (Object item : rawList) {
                if (!(item instanceof HttpAccessLogMessage)) {
                    return null;
                }
            }
            @SuppressWarnings("unchecked")
            List<HttpAccessLogMessage> outboundAccessLogMessages = (List<HttpAccessLogMessage>) rawList;
            return outboundAccessLogMessages;
        }
        return null;
    }
}
