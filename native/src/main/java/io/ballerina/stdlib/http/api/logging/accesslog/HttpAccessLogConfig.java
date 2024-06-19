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

import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_REFERRER;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_USER_AGENT;
import static io.ballerina.stdlib.http.api.HttpConstants.ATTRIBUTE_HTTP_X_FORWARDED_FOR;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_ATTRIBUTES;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_LOG_FORMAT_JSON;

public class HttpAccessLogConfig {

    private static final HttpAccessLogConfig instance = new HttpAccessLogConfig();

    private final Set<String> excludedAttributes = new HashSet<>(List.of(
            ATTRIBUTE_HTTP_REFERRER, ATTRIBUTE_HTTP_USER_AGENT, ATTRIBUTE_HTTP_X_FORWARDED_FOR
    ));
    private BMap accessLogConfig;

    private HttpAccessLogConfig() {}

    public static HttpAccessLogConfig getInstance() {
        return instance;
    }

    public void initializeHttpAccessLogConfig(BMap accessLogConfig) {
        this.accessLogConfig = accessLogConfig;
    }

    public List<String> getCustomHeaders() {
        List<String> attributes = getAccessLogAttributes();
        if (attributes == null) {
            return Collections.emptyList();
        }

        return attributes.stream()
                .filter(attr -> attr.startsWith("http_") && !excludedAttributes.contains(attr))
                .map(attr -> attr.substring(5))
                .collect(Collectors.toList());
    }

    public HttpAccessLogFormat getAccessLogFormat() {
        if (accessLogConfig != null) {
            BString logFormat = accessLogConfig.getStringValue(HTTP_LOG_FORMAT);
            if (logFormat.getValue().equals(HTTP_LOG_FORMAT_JSON)) {
                return HttpAccessLogFormat.JSON;
            }
        }
        return HttpAccessLogFormat.FLAT;
    }

    public List<String> getAccessLogAttributes() {
        if (accessLogConfig != null) {
            BArray logAttributes = accessLogConfig.getArrayValue(HTTP_LOG_ATTRIBUTES);
            if (logAttributes != null) {
                return Arrays.stream(logAttributes.getStringArray())
                        .collect(Collectors.toList());
            }
        }
        return null;
    }
}
