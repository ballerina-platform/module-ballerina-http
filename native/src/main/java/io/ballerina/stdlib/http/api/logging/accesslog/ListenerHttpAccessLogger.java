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

import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.util.internal.logging.InternalLogLevel;
import io.netty.util.internal.logging.InternalLogger;
import io.netty.util.internal.logging.InternalLoggerFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Calendar;
import java.util.List;

import static io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogFormatter.formatAccessLogMessage;
import static io.ballerina.stdlib.http.api.logging.accesslog.HttpAccessLogUtil.getHttpAccessLogMessages;
import static io.ballerina.stdlib.http.transport.contract.Constants.ACCESS_LOG;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_X_FORWARDED_FOR;

/**
 * Implements {@link HttpAccessLogger} to log detailed HTTP access information for incoming requests
 * and their corresponding responses.
 *
 * @since 2.11.3
 */
public class ListenerHttpAccessLogger implements HttpAccessLogger {

    private static final Logger LOG = LoggerFactory.getLogger(ListenerHttpAccessLogger.class);
    private static final InternalLogger ACCESS_LOGGER = InternalLoggerFactory.getInstance(ACCESS_LOG);

    private final Calendar inboundRequestArrivalTime;
    private Long contentLength = 0L;
    private String remoteAddress;

    public ListenerHttpAccessLogger(Calendar inboundRequestArrivalTime, String remoteAddress) {
        this.inboundRequestArrivalTime = inboundRequestArrivalTime;
        this.remoteAddress = remoteAddress;
    }

    public ListenerHttpAccessLogger(Calendar inboundRequestArrivalTime, Long contentLength, String remoteAddress) {
        this.inboundRequestArrivalTime = inboundRequestArrivalTime;
        this.contentLength = contentLength;
        this.remoteAddress = remoteAddress;
    }

    @Override
    public void logAccessInfo(HttpCarbonMessage inboundRequestMsg, HttpCarbonMessage outboundResponseMsg) {
        HttpHeaders headers = inboundRequestMsg.getHeaders();
        if (headers.contains(HTTP_X_FORWARDED_FOR)) {
            String forwardedHops = headers.get(HTTP_X_FORWARDED_FOR);
            // If multiple IPs available, the first ip is the client
            int firstCommaIndex = forwardedHops.indexOf(',');
            remoteAddress = firstCommaIndex != -1 ? forwardedHops.substring(0, firstCommaIndex) : forwardedHops;
        }

        // Populate request parameters
        String userAgent = "-";
        if (headers.contains(HttpHeaderNames.USER_AGENT)) {
            userAgent = headers.get(HttpHeaderNames.USER_AGENT);
        }
        String referrer = "-";
        if (headers.contains(HttpHeaderNames.REFERER)) {
            referrer = headers.get(HttpHeaderNames.REFERER);
        }
        String method = inboundRequestMsg.getHttpMethod();
        String uri = inboundRequestMsg.getRequestUrl();
        HttpMessage request = inboundRequestMsg.getNettyHttpRequest();
        String protocol;
        if (request != null) {
            protocol = request.protocolVersion().toString();
        } else {
            protocol = inboundRequestMsg.getHttpVersion();
        }
        long requestBodySize;
        if (headers.contains(HttpHeaderNames.CONTENT_LENGTH)) {
            try {
                requestBodySize = Long.parseLong(headers.get(HttpHeaderNames.CONTENT_LENGTH));
            } catch (Exception ignored) {
                requestBodySize = 0L;
            }
        } else {
            requestBodySize = (long) inboundRequestMsg.getContentSize();
        }

        // Populate response parameters
        int statusCode = Util.getHttpResponseStatus(outboundResponseMsg).code();

        long requestTime = Calendar.getInstance().getTimeInMillis() - inboundRequestArrivalTime.getTimeInMillis();
        HttpAccessLogMessage inboundMessage = new HttpAccessLogMessage(remoteAddress,
                inboundRequestArrivalTime, method, uri, protocol, statusCode, contentLength, referrer, userAgent);
        inboundMessage.setRequestBodySize(requestBodySize);
        inboundMessage.setRequestTime(requestTime);

        List<HttpAccessLogMessage> outboundMessages = getHttpAccessLogMessages(inboundRequestMsg);

        String formattedAccessLogMessage = formatAccessLogMessage(inboundMessage, outboundMessages,
                HttpAccessLogConfig.getInstance().getAccessLogFormat(),
                HttpAccessLogConfig.getInstance().getAccessLogAttributes());
        ACCESS_LOGGER.log(InternalLogLevel.INFO, formattedAccessLogMessage);
    }

    @Override
    public void updateAccessLogInfo(HttpCarbonMessage requestMessage, HttpCarbonMessage responseMessage) {
        LOG.warn("updateAccessLogInfo is not a dependant action of this logger");
    }

    public void updateContentLength(HttpContent httpContent) {
        contentLength += httpContent.content().readableBytes();
    }
}
