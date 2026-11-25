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
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGES;

/**
 * Provides utility methods for accessing and manipulating properties related to HTTP access logging
 * from HttpCarbonMessage objects. This class includes type-safe property retrieval and handling specific
 * logging data structures.
 *
 * @since 2.12.0
 */
public class HttpAccessLogUtil {
    public static <T> T getTypedProperty(HttpCarbonMessage carbonMessage, String propertyName, Class<T> type) {
        Object property = carbonMessage.getProperty(propertyName);
        if (type.isInstance(property)) {
            return type.cast(property);
        }
        return null;
    }

    public static List<HttpAccessLogMessage> getHttpAccessLogMessages(HttpCarbonMessage carbonMessage) {
        Object outboundAccessLogMessagesObject = carbonMessage.getProperty(OUTBOUND_ACCESS_LOG_MESSAGES);
        if (outboundAccessLogMessagesObject instanceof List<?> rawList) {
            @SuppressWarnings("unchecked")
            List<HttpAccessLogMessage> outboundAccessLogMessages = (List<HttpAccessLogMessage>) rawList;
            return outboundAccessLogMessages;
        }
        return new ArrayList<>();
    }

    /**
     * Copies the headers configured as custom access log attributes ({@code http_<header-name>}) from the given
     * headers into the access log message. The values of a header that is sent more than once are joined with commas.
     * A header that is not present is left out, and the formatter renders it as {@code -}.
     *
     * @param message the access log message to populate
     * @param headers the headers of the request being logged
     */
    public static void populateCustomHeaders(HttpAccessLogMessage message, HttpHeaders headers) {
        for (String customHeader : HttpAccessLogConfig.getInstance().getCustomHeaders()) {
            if (headers.contains(customHeader)) {
                message.putCustomHeader(customHeader, String.join(",", headers.getAll(customHeader)));
            }
        }
    }
}
