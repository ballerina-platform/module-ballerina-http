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

import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.netty.handler.codec.http.DefaultHttpHeaders;
import io.netty.handler.codec.http.HttpHeaders;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.Map;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_ATTRIBUTES;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;

/**
 * Unit tests for {@link HttpAccessLogUtil#populateCustomHeaders}, which copies the headers configured as custom
 * access log attributes into an access log message.
 */
public class HttpAccessLogUtilTest {

    @AfterMethod
    public void resetAccessLogConfig() {
        HttpAccessLogConfig.getInstance().initializeHttpAccessLogConfig(null);
    }

    private static void configureAttributes(String... attributes) {
        BArray attributeArray = mock(BArray.class);
        when(attributeArray.getStringArray()).thenReturn(attributes);
        BMap accessLogConfig = mock(BMap.class);
        when(accessLogConfig.getArrayValue(HTTP_LOG_ATTRIBUTES)).thenReturn(attributeArray);
        HttpAccessLogConfig.getInstance().initializeHttpAccessLogConfig(accessLogConfig);
    }

    @Test(description = "A configured custom header is copied from the headers, matching its name case insensitively")
    public void testConfiguredHeaderIsCopied() {
        configureAttributes("ip", "request", "status", "http_x-request-id");
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.add("X-Request-ID", "abc123");
        HttpAccessLogMessage message = new HttpAccessLogMessage();

        HttpAccessLogUtil.populateCustomHeaders(message, headers);

        assertEquals(message.getCustomHeaders(), Map.of("x-request-id", "abc123"));
    }

    @Test(description = "The values of a custom header that is sent more than once are joined with commas")
    public void testRepeatedHeaderValuesAreJoined() {
        configureAttributes("http_x-request-id");
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.add("X-Request-ID", "id-1");
        headers.add("X-Request-ID", "id-2");
        HttpAccessLogMessage message = new HttpAccessLogMessage();

        HttpAccessLogUtil.populateCustomHeaders(message, headers);

        assertEquals(message.getCustomHeaders(), Map.of("x-request-id", "id-1,id-2"));
    }

    @Test(description = "A configured custom header that the headers do not have is left out of the message")
    public void testMissingHeaderIsLeftOut() {
        configureAttributes("http_x-request-id", "http_x-correlation-id");
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.add("X-Correlation-ID", "corr-1");
        HttpAccessLogMessage message = new HttpAccessLogMessage();

        HttpAccessLogUtil.populateCustomHeaders(message, headers);

        assertEquals(message.getCustomHeaders(), Map.of("x-correlation-id", "corr-1"));
    }

    @Test(description = "Nothing is copied when no custom header attribute is configured")
    public void testNoCustomHeaderAttributes() {
        configureAttributes("ip", "http_user_agent", "http_x_forwarded_for");
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.add("User-Agent", "curl/8.7.1");
        headers.add("X-Forwarded-For", "10.0.0.1");
        HttpAccessLogMessage message = new HttpAccessLogMessage();

        HttpAccessLogUtil.populateCustomHeaders(message, headers);

        assertTrue(message.getCustomHeaders().isEmpty());
    }
}
