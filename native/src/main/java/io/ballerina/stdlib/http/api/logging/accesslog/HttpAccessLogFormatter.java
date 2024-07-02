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

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_DATE_TIME;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_REFERRER;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_USER_AGENT;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_X_FORWARDED_FOR;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_IP;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_REQUEST;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_REQUEST_BODY_SIZE;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_REQUEST_METHOD;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_REQUEST_TIME;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_REQUEST_URI;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_RESPONSE_BODY_SIZE;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_SCHEME;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_STATUS;

public class HttpAccessLogFormatter {

    private HttpAccessLogFormatter() {}

    public static String formatAccessLogMessage(HttpAccessLogMessage inboundMessage,
                                                List<HttpAccessLogMessage> outboundMessages, HttpAccessLogFormat format,
                                                List<String> attributes) {

        Map<String, String> inboundMap = mapAccessLogMessage(inboundMessage, format, attributes);
        if (format == HttpAccessLogFormat.FLAT) {
            String inboundFormatted = inboundMap.values().stream()
                    .filter(Objects::nonNull)
                    .collect(Collectors.joining(" "));

            if (!outboundMessages.isEmpty()) {
                String outboundFormatted = outboundMessages.stream()
                        .map(outboundMsg -> mapAccessLogMessage(outboundMsg, format, attributes))
                        .map(outboundMap -> outboundMap.values().stream()
                                .filter(Objects::nonNull)
                                .collect(Collectors.joining(" ")))
                        .collect(Collectors.joining(" "));

                return inboundFormatted + " \"~\" " + outboundFormatted;
            } else {
                return inboundFormatted;
            }
        } else {
            Gson gson = new Gson();
            JsonObject jsonObject = new JsonObject();

            inboundMap.forEach(jsonObject::addProperty);

            if (!outboundMessages.isEmpty()) {
                JsonArray upstreamArray = new JsonArray();
                for (HttpAccessLogMessage outboundMessage : outboundMessages) {
                    Map<String, String> outboundMap = mapAccessLogMessage(outboundMessage, format, attributes);
                    JsonObject outboundJson = gson.toJsonTree(outboundMap).getAsJsonObject();
                    upstreamArray.add(outboundJson);
                }
                jsonObject.add("upstream", upstreamArray);
            }
            return gson.toJson(jsonObject);
        }
    }

    private static Map<String, String> mapAccessLogMessage(HttpAccessLogMessage httpAccessLogMessage,
                                                           HttpAccessLogFormat format, List<String> attributes) {
        List<String> allAttributes = List.of(ATTRIBUTE_IP, ATTRIBUTE_DATE_TIME, ATTRIBUTE_REQUEST,
                ATTRIBUTE_REQUEST_METHOD, ATTRIBUTE_REQUEST_URI, ATTRIBUTE_SCHEME, ATTRIBUTE_STATUS,
                ATTRIBUTE_REQUEST_BODY_SIZE, ATTRIBUTE_RESPONSE_BODY_SIZE, ATTRIBUTE_REQUEST_TIME,
                ATTRIBUTE_HTTP_REFERRER, ATTRIBUTE_HTTP_USER_AGENT, ATTRIBUTE_HTTP_X_FORWARDED_FOR);
        List<String> defaultAttributes = List.of(ATTRIBUTE_IP, ATTRIBUTE_DATE_TIME, ATTRIBUTE_REQUEST, ATTRIBUTE_STATUS,
                ATTRIBUTE_RESPONSE_BODY_SIZE, ATTRIBUTE_HTTP_REFERRER, ATTRIBUTE_HTTP_USER_AGENT);

        Map<String, String> attributeValues = new LinkedHashMap<>();
        allAttributes.forEach(attr -> attributeValues.put(attr, null));

        if (!attributes.isEmpty()) {
            attributes.forEach(attr -> {
                attributeValues.put(attr, formatAccessLogAttribute(httpAccessLogMessage, format, attr));
            });
        } else {
            defaultAttributes.forEach(attr ->
                    attributeValues.put(attr, formatAccessLogAttribute(httpAccessLogMessage, format, attr)));
        }
        return attributeValues;
    }

    private static String formatAccessLogAttribute(HttpAccessLogMessage httpAccessLogMessage,
                                                   HttpAccessLogFormat format, String attribute) {
        return switch (attribute) {
            case ATTRIBUTE_IP -> httpAccessLogMessage.getIp();
            case ATTRIBUTE_DATE_TIME -> String.format(format == HttpAccessLogFormat.FLAT ?
                    "[%1$td/%1$tb/%1$tY:%1$tT.%1$tL %1$tz]" : "%1$td/%1$tb/%1$tY:%1$tT.%1$tL %1$tz",
                    httpAccessLogMessage.getDateTime());
            case ATTRIBUTE_REQUEST_METHOD -> httpAccessLogMessage.getRequestMethod();
            case ATTRIBUTE_REQUEST_URI -> httpAccessLogMessage.getRequestUri();
            case ATTRIBUTE_SCHEME -> httpAccessLogMessage.getScheme();
            case ATTRIBUTE_REQUEST -> String.format(format == HttpAccessLogFormat.FLAT ?
                    "\"%1$s %2$s %3$s\"" : "%1$s %2$s %3$s", httpAccessLogMessage.getRequestMethod(),
                    httpAccessLogMessage.getRequestUri(), httpAccessLogMessage.getScheme());
            case ATTRIBUTE_STATUS -> String.valueOf(httpAccessLogMessage.getStatus());
            case ATTRIBUTE_REQUEST_BODY_SIZE -> String.valueOf(httpAccessLogMessage.getRequestBodySize());
            case ATTRIBUTE_RESPONSE_BODY_SIZE -> String.valueOf(httpAccessLogMessage.getResponseBodySize());
            case ATTRIBUTE_REQUEST_TIME -> String.valueOf(httpAccessLogMessage.getRequestTime());
            case ATTRIBUTE_HTTP_REFERRER -> String.format(format == HttpAccessLogFormat.FLAT ?
                    "\"%1$s\"" : "%1$s", getHyphenForNull(httpAccessLogMessage.getHttpReferrer()));
            case ATTRIBUTE_HTTP_USER_AGENT -> String.format(format == HttpAccessLogFormat.FLAT ?
                    "\"%1$s\"" : "%1$s", getHyphenForNull(httpAccessLogMessage.getHttpUserAgent()));
            case ATTRIBUTE_HTTP_X_FORWARDED_FOR -> String.format(format == HttpAccessLogFormat.FLAT ?
                    "\"%1$s\"" : "%1$s", getHyphenForNull(httpAccessLogMessage.getHttpXForwardedFor()));
            default -> getCustomHeaderValueForAttribute(httpAccessLogMessage, format, attribute);
        };
    }

    private static String getCustomHeaderValueForAttribute(HttpAccessLogMessage httpAccessLogMessage,
                                                           HttpAccessLogFormat format, String attribute) {
        Map<String, String> customHeaders = httpAccessLogMessage.getCustomHeaders();
        if (attribute.startsWith("http_")) {
            String customHeaderKey = attribute.substring(5);
            for (Map.Entry<String, String> entry : customHeaders.entrySet()) {
                if (entry.getKey().equalsIgnoreCase(customHeaderKey)) {
                    String value = entry.getValue();
                    return format == HttpAccessLogFormat.FLAT ? String.format("\"%s\"", value) : value;
                }
            }
            return format == HttpAccessLogFormat.FLAT ? "\"-\"" : "-";
        }
        return null;
    }

    private static String getHyphenForNull(String value) {
        return value == null ? "-" : value;
    }
}
