/*
 *  Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import java.util.List;

import static io.ballerina.stdlib.http.transport.contract.Constants.OUTBOUND_ACCESS_LOG_MESSAGES;

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
