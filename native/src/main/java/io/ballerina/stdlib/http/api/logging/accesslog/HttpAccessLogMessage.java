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

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

/**
 * Represents a single HTTP access log message, encapsulating all relevant data for a specific request-response cycle.
 * This class stores details such as IP address, date and time, request and response attributes, and custom headers.
 *
 * @since 2.12.0
 */
public class HttpAccessLogMessage {
    private String ip;
    private Calendar dateTime;
    private String requestMethod;
    private String requestUri;
    private String scheme;
    private int status;
    private long requestBodySize;
    private long responseBodySize;
    private long requestTime;
    private String httpReferrer;
    private String httpUserAgent;
    private String httpXForwardedFor;
    private String host;
    private int port;
    private Map<String, String> customHeaders;

    public HttpAccessLogMessage() {
        this.customHeaders = new HashMap<>();
    }

    public HttpAccessLogMessage(String ip, Calendar dateTime, String requestMethod, String requestUri, String scheme,
                                int status, long responseBodySize, String httpReferrer, String httpUserAgent) {
        this.ip = ip;
        this.dateTime = dateTime;
        this.requestMethod = requestMethod;
        this.requestUri = requestUri;
        this.scheme = scheme;
        this.status = status;
        this.responseBodySize = responseBodySize;
        this.httpReferrer = httpReferrer;
        this.httpUserAgent = httpUserAgent;
        this.customHeaders = new HashMap<>();
    }

    public Calendar getDateTime() {
        return dateTime;
    }

    public void setDateTime(Calendar dateTime) {
        this.dateTime = dateTime;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public String getRequestMethod() {
        return requestMethod;
    }

    public void setRequestMethod(String requestMethod) {
        this.requestMethod = requestMethod;
    }

    public String getRequestUri() {
        return requestUri;
    }

    public void setRequestUri(String requestUri) {
        this.requestUri = requestUri;
    }

    public String getScheme() {
        return scheme;
    }

    public void setScheme(String scheme) {
        this.scheme = scheme;
    }

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public long getRequestBodySize() {
        return requestBodySize;
    }

    public void setRequestBodySize(Long requestBodySize) {
        this.requestBodySize = requestBodySize;
    }

    public long getResponseBodySize() {
        return responseBodySize;
    }

    public void setResponseBodySize(Long responseBodySize) {
        this.responseBodySize = responseBodySize;
    }

    public long getRequestTime() {
        return requestTime;
    }

    public void setRequestTime(Long requestTime) {
        this.requestTime = requestTime;
    }

    public String getHttpUserAgent() {
        return httpUserAgent;
    }

    public String getHttpReferrer() {
        return httpReferrer;
    }

    public void setHttpReferrer(String httpReferrer) {
        this.httpReferrer = httpReferrer;
    }

    public void setHttpUserAgent(String httpUserAgent) {
        this.httpUserAgent = httpUserAgent;
    }

    public String getHttpXForwardedFor() {
        return httpXForwardedFor;
    }

    public void setHttpXForwardedFor(String httpXForwardedFor) {
        this.httpXForwardedFor = httpXForwardedFor;
    }

    public String getHost() {
        return this.host;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public int getPort() {
        return this.port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public Map<String, String> getCustomHeaders() {
        return customHeaders;
    }

    public void setCustomHeaders(Map<String, String> customHeaders) {
        this.customHeaders = customHeaders;
    }

    public void putCustomHeader(String headerKey, String headerValue) {
        this.customHeaders.put(headerKey, headerValue);
    }
}
