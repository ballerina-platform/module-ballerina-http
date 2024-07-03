/*
 *  Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
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

package io.ballerina.stdlib.http.api.logging.accesslog;

import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.buffer.ByteBuf;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.Calendar;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.INBOUND_MESSAGE;
import static io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogUtil.getHttpAccessLogMessages;
import static io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogUtil.getTypedProperty;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_X_FORWARDED_FOR;
import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGE;
import static io.ballerina.stdlib.http.transport.contract.Constants.TO;

/**
 * Implements {@link HttpAccessLogger} for the sender side, focusing on updating and enriching
 * HTTP access log information for outbound requests and corresponding inbound responses.
 *
 * @since 2.11.3
 */
public class SenderHttpAccessLogger implements HttpAccessLogger {

    private static final Logger LOG = LoggerFactory.getLogger(SenderHttpAccessLogger.class);

    private Long contentLength = 0L;
    private final SocketAddress remoteAddress;

    public SenderHttpAccessLogger(SocketAddress remoteAddress) {
        this.remoteAddress = remoteAddress;
    }

    @Override
    public void logAccessInfo(HttpCarbonMessage requestMessage, HttpCarbonMessage responseMessage) {
        LOG.warn("logAccessInfo is not a dependant action of this logger");
    }

    @Override
    public void updateAccessLogInfo(HttpCarbonMessage outboundRequestMsg, HttpCarbonMessage inboundResponseMsg) {
        HttpAccessLogMessage outboundAccessLogMessage =
                getTypedProperty(outboundRequestMsg, OUTBOUND_ACCESS_LOG_MESSAGE, HttpAccessLogMessage.class);
        if (outboundAccessLogMessage == null) {
            return;
        }

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
        HttpHeaders headers = outboundRequestMsg.getHeaders();
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

        outboundAccessLogMessage.setRequestMethod(outboundRequestMsg.getHttpMethod());
        outboundAccessLogMessage.setRequestUri((String) outboundRequestMsg.getProperty(TO));
        HttpMessage inboundResponse = inboundResponseMsg.getNettyHttpResponse();
        if (inboundResponse != null) {
            outboundAccessLogMessage.setScheme(inboundResponse.protocolVersion().toString());
        } else {
            outboundAccessLogMessage.setScheme(inboundResponseMsg.getHttpVersion());
        }
        long requestBodySize;
        if (headers.contains(HttpHeaderNames.CONTENT_LENGTH)) {
            try {
                requestBodySize = Long.parseLong(headers.get(HttpHeaderNames.CONTENT_LENGTH));
            } catch (Exception ignored) {
                requestBodySize = 0L;
            }
        } else {
            requestBodySize = (long) outboundRequestMsg.getContentSize();
        }
        outboundAccessLogMessage.setRequestBodySize(requestBodySize);
        outboundAccessLogMessage.setStatus(inboundResponseMsg.getHttpStatusCode());
        outboundAccessLogMessage.setResponseBodySize(contentLength);
        long requestTime = Calendar.getInstance().getTimeInMillis() -
                outboundAccessLogMessage.getDateTime().getTimeInMillis();
        outboundAccessLogMessage.setRequestTime(requestTime);

        HttpCarbonMessage inboundReqMsg =
                getTypedProperty(outboundRequestMsg, INBOUND_MESSAGE, HttpCarbonMessage.class);

        if (inboundReqMsg != null) {
            List<HttpAccessLogMessage> outboundAccessLogMessages = getHttpAccessLogMessages(inboundReqMsg);
            outboundAccessLogMessages.add(outboundAccessLogMessage);
        }
    }

    public void updateContentLength(ByteBuf content) {
        contentLength += content.readableBytes();
    }
}
