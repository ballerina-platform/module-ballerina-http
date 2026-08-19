/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.api.logging.accesslog;

import org.testng.annotations.Test;

import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Unit tests for {@link HttpAccessLogFormatter}, which renders access log entries in either the flat or the
 * JSON format.
 */
public class HttpAccessLogFormatterTest {

    /**
     * Reads a string property out of the formatter's JSON output. Gson is an implementation-only dependency
     * here, so the assertions work on the rendered text rather than a parsed tree.
     */
    private static String jsonValue(String json, String key) {
        Matcher matcher = Pattern.compile("\\\"" + Pattern.quote(key) + "\\\"\\s*:\\s*\\\"([^\\\"]*)\\\"")
                .matcher(json);
        assertTrue(matcher.find(), "Property '" + key + "' not found in: " + json);
        return matcher.group(1);
    }

    private static boolean hasJsonKey(String json, String key) {
        return Pattern.compile("\\\"" + Pattern.quote(key) + "\\\"\\s*:").matcher(json).find();
    }

    private HttpAccessLogMessage inboundMessage() {
        HttpAccessLogMessage message = new HttpAccessLogMessage();
        Calendar dateTime = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        dateTime.set(2026, Calendar.JANUARY, 15, 10, 30, 45);
        dateTime.set(Calendar.MILLISECOND, 123);
        message.setDateTime(dateTime);
        message.setIp("192.168.1.10");
        message.setRequestMethod("GET");
        message.setRequestUri("/orders/42");
        message.setScheme("HTTP/1.1");
        message.setStatus(200);
        message.setRequestBodySize(120L);
        message.setResponseBodySize(2048L);
        message.setRequestTime(35L);
        message.setHttpReferrer("http://example.com/index.html");
        message.setHttpUserAgent("test-agent/1.0");
        message.setHttpXForwardedFor("203.0.113.7");
        return message;
    }

    @Test(description = "The flat format renders the default attributes, quoting the request and header values")
    public void testFlatFormatWithDefaultAttributes() {
        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.FLAT, List.of());

        assertTrue(formatted.contains("192.168.1.10"), "IP is missing");
        assertTrue(formatted.contains("\"GET /orders/42 HTTP/1.1\""), "Quoted request line is missing");
        assertTrue(formatted.contains("200"), "Status is missing");
        assertTrue(formatted.contains("2048"), "Response body size is missing");
        assertTrue(formatted.contains("\"http://example.com/index.html\""), "Quoted referrer is missing");
        assertTrue(formatted.contains("\"test-agent/1.0\""), "Quoted user agent is missing");
        // The date_time attribute is bracketed in the flat format.
        assertTrue(formatted.contains("[15/Jan/2026:"), "Bracketed date time is missing: " + formatted);
        // Not a default attribute, so it must not appear.
        assertFalse(formatted.contains("203.0.113.7"), "x_forwarded_for is not a default attribute");
    }

    @Test(description = "The JSON format emits the default attributes as properties without the flat quoting")
    public void testJsonFormatWithDefaultAttributes() {
        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.JSON, List.of());

        assertEquals(jsonValue(formatted, ATTRIBUTE_IP), "192.168.1.10", "IP property is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_REQUEST), "GET /orders/42 HTTP/1.1",
                     "Request property should not be quoted in JSON");
        assertEquals(jsonValue(formatted, ATTRIBUTE_STATUS), "200", "Status property is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_RESPONSE_BODY_SIZE), "2048",
                     "Response body size property is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_HTTP_USER_AGENT), "test-agent/1.0",
                     "User agent property should not be quoted in JSON");
        assertFalse(hasJsonKey(formatted, "upstream"), "No upstream array is expected without outbound messages");
    }

    @Test(description = "An explicit attribute list replaces the defaults, including ones they leave out")
    public void testExplicitAttributeSelection() {
        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.JSON,
                List.of(ATTRIBUTE_REQUEST_METHOD, ATTRIBUTE_REQUEST_URI, ATTRIBUTE_SCHEME,
                        ATTRIBUTE_REQUEST_BODY_SIZE, ATTRIBUTE_REQUEST_TIME, ATTRIBUTE_HTTP_X_FORWARDED_FOR));

        assertEquals(jsonValue(formatted, ATTRIBUTE_REQUEST_METHOD), "GET", "Request method is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_REQUEST_URI), "/orders/42", "Request URI is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_SCHEME), "HTTP/1.1", "Scheme is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_REQUEST_BODY_SIZE), "120", "Request body size is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_REQUEST_TIME), "35", "Request time is wrong");
        assertEquals(jsonValue(formatted, ATTRIBUTE_HTTP_X_FORWARDED_FOR), "203.0.113.7",
                     "x_forwarded_for is wrong");
        assertFalse(hasJsonKey(formatted, ATTRIBUTE_IP), "IP was not requested and should be absent");
    }

    @Test(description = "Null referrer and user agent are rendered as a hyphen rather than the literal null")
    public void testNullHeaderValuesBecomeHyphen() {
        HttpAccessLogMessage message = inboundMessage();
        message.setHttpReferrer(null);
        message.setHttpUserAgent(null);
        message.setHttpXForwardedFor(null);

        String flat = HttpAccessLogFormatter.formatAccessLogMessage(
                message, List.of(), HttpAccessLogFormat.FLAT,
                List.of(ATTRIBUTE_HTTP_REFERRER, ATTRIBUTE_HTTP_USER_AGENT, ATTRIBUTE_HTTP_X_FORWARDED_FOR));
        assertEquals(flat, "\"-\" \"-\" \"-\"", "Null header values were not rendered as quoted hyphens");

        String json = HttpAccessLogFormatter.formatAccessLogMessage(
                message, List.of(), HttpAccessLogFormat.JSON,
                List.of(ATTRIBUTE_HTTP_REFERRER, ATTRIBUTE_HTTP_USER_AGENT, ATTRIBUTE_HTTP_X_FORWARDED_FOR));
        assertEquals(jsonValue(json, ATTRIBUTE_HTTP_REFERRER), "-", "Null referrer should be a hyphen");
        assertEquals(jsonValue(json, ATTRIBUTE_HTTP_USER_AGENT), "-", "Null user agent should be a hyphen");
    }

    @Test(description = "A custom http_ attribute is resolved from the message's custom headers, case insensitively")
    public void testCustomHeaderAttribute() {
        HttpAccessLogMessage message = inboundMessage();
        message.putCustomHeader("X-Correlation-Id", "abc-123");

        String flat = HttpAccessLogFormatter.formatAccessLogMessage(
                message, List.of(), HttpAccessLogFormat.FLAT, List.of("http_x-correlation-id"));
        assertEquals(flat, "\"abc-123\"", "Custom header was not resolved case insensitively in flat format");

        String json = HttpAccessLogFormatter.formatAccessLogMessage(
                message, List.of(), HttpAccessLogFormat.JSON, List.of("http_x-correlation-id"));
        assertEquals(jsonValue(json, "http_x-correlation-id"), "abc-123",
                     "Custom header was not resolved in JSON format");
    }

    @Test(description = "A requested custom header that the message does not carry renders as a hyphen")
    public void testMissingCustomHeaderBecomesHyphen() {
        String flat = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.FLAT, List.of("http_x-absent"));
        assertEquals(flat, "\"-\"", "An absent custom header should render as a quoted hyphen");

        String json = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.JSON, List.of("http_x-absent"));
        assertEquals(jsonValue(json, "http_x-absent"), "-",
                     "An absent custom header should render as a hyphen in JSON");
    }

    @Test(description = "An unrecognised attribute that is not an http_ header is dropped entirely")
    public void testUnknownAttributeIsOmitted() {
        String flat = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.FLAT, List.of("not_an_attribute"));
        assertEquals(flat, "", "An unknown attribute should contribute nothing to the flat output");
    }

    @Test(description = "Outbound messages are appended after a separator in the flat format")
    public void testFlatFormatWithOutboundMessages() {
        HttpAccessLogMessage outbound = inboundMessage();
        outbound.setRequestUri("/upstream/service");
        outbound.setStatus(201);

        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(outbound), HttpAccessLogFormat.FLAT, List.of());

        assertTrue(formatted.contains(" \"~\" "), "Outbound entries should be separated by the ~ marker");
        assertTrue(formatted.contains("/orders/42"), "Inbound request is missing");
        assertTrue(formatted.contains("/upstream/service"), "Outbound request is missing");
        assertTrue(formatted.contains("201"), "Outbound status is missing");
    }

    @Test(description = "Outbound messages become an upstream array in the JSON format")
    public void testJsonFormatWithOutboundMessages() {
        HttpAccessLogMessage first = inboundMessage();
        first.setRequestUri("/upstream/one");
        HttpAccessLogMessage second = inboundMessage();
        second.setRequestUri("/upstream/two");

        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(first, second), HttpAccessLogFormat.JSON, List.of());

        assertTrue(hasJsonKey(formatted, "upstream"), "Outbound messages should be nested under upstream");
        assertEquals(formatted.split("/upstream/", -1).length - 1, 2,
                     "Both outbound messages should be present in the upstream array");
        assertTrue(formatted.contains("/upstream/one"), "First outbound request is missing");
        assertTrue(formatted.contains("/upstream/two"), "Second outbound request is missing");
    }

    @Test(description = "Attribute order in the flat output follows the canonical attribute order, not the "
            + "order the caller listed them in")
    public void testFlatOutputUsesCanonicalAttributeOrder() {
        String formatted = HttpAccessLogFormatter.formatAccessLogMessage(
                inboundMessage(), List.of(), HttpAccessLogFormat.FLAT,
                List.of(ATTRIBUTE_STATUS, ATTRIBUTE_IP));
        // ip precedes status in the canonical ordering, so it must come first regardless of the request order.
        assertEquals(formatted, "192.168.1.10 200", "Flat output did not use the canonical attribute order");
    }
}
