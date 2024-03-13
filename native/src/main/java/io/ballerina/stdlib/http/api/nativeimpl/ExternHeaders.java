/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.mime.util.MimeUtil;
import io.netty.handler.codec.http.DefaultHttpHeaders;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_HEADERS;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_TRAILER_HEADERS;
import static io.ballerina.stdlib.http.api.HttpConstants.LEADING_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.SET_HOST_HEADER;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_NOT_FOUND_ERROR;
import static io.ballerina.stdlib.mime.util.MimeConstants.INVALID_HEADER_OPERATION_ERROR;

/**
 * Utilities related to HTTP request/response headers.
 *
 * @since 1.1.0
 */
public class ExternHeaders {

    public static void addHeader(BObject messageObj, BString headerName, BString headerValue, Object position) {
        try {
            getOrCreateHeadersBasedOnPosition(messageObj, position).add(headerName.getValue(), headerValue.getValue());
        } catch (IllegalArgumentException ex) {
            throw MimeUtil.createError(INVALID_HEADER_OPERATION_ERROR, ex.getMessage());
        }
    }

    public static Object getHeader(BObject messageObj, BString headerName, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders == null) {
            return HttpUtil.createHttpError("Http header does not exist", HEADER_NOT_FOUND_ERROR);
        }
        if (httpHeaders.get(headerName.getValue()) != null) {
            return StringUtils.fromString(httpHeaders.get(headerName.getValue()));
        } else {
            return HttpUtil.createHttpError("Http header does not exist", HEADER_NOT_FOUND_ERROR);
        }
    }

    public static BArray getHeaderNames(BObject messageObj, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders == null || httpHeaders.isEmpty()) {
            return StringUtils.fromStringArray(new String[0]);
        }
        Set<String> distinctNames = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        distinctNames.addAll(httpHeaders.names());
        return StringUtils.fromStringArray(distinctNames.toArray(new String[0]));
    }

    public static Object getHeaders(BObject messageObj, BString headerName, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders == null) {
            return HttpUtil.createHttpError("Http header does not exist", HEADER_NOT_FOUND_ERROR);
        }
        List<String> headerValueList = httpHeaders.getAll(headerName.getValue());
        if (headerValueList == null || headerValueList.isEmpty()) {
            return HttpUtil.createHttpError("Http header does not exist", HEADER_NOT_FOUND_ERROR);
        }
        return StringUtils.fromStringArray(headerValueList.toArray(new String[0]));
    }

    public static boolean hasHeader(BObject messageObj, BString headerName, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders == null) {
            return false;
        }
        List<String> headerValueList = httpHeaders.getAll(headerName.getValue());
        return headerValueList != null && !headerValueList.isEmpty();
    }

    public static void removeAllHeaders(BObject messageObj, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders != null) {
            httpHeaders.clear();
        }
    }

    public static void removeHeader(BObject messageObj, BString headerName, Object position) {
        HttpHeaders httpHeaders = getHeadersBasedOnPosition(messageObj, position);
        if (httpHeaders != null) {
            httpHeaders.remove(headerName.getValue());
        }
    }

    public static void setHeader(BObject messageObj, BString headerName, BString headerValue, Object position) {
        if (headerName == null || headerValue == null) {
            return;
        }
        try {
            getOrCreateHeadersBasedOnPosition(messageObj, position).set(headerName.getValue(), headerValue.getValue());
            if (headerName.getValue().equalsIgnoreCase(HttpHeaderNames.HOST.toString())) {
                messageObj.addNativeData(SET_HOST_HEADER, true);
            }
        } catch (IllegalArgumentException ex) {
            throw MimeUtil.createError(INVALID_HEADER_OPERATION_ERROR, ex.getMessage());
        }
    }

    private static HttpHeaders getHeadersBasedOnPosition(BObject messageObj, Object position) {
        return position.equals(StringUtils.fromString(LEADING_HEADER)) ?
                (HttpHeaders) messageObj.getNativeData(HTTP_HEADERS) :
                (HttpHeaders) messageObj.getNativeData(HTTP_TRAILER_HEADERS);
    }

    private static HttpHeaders getOrCreateHeadersBasedOnPosition(BObject messageObj, Object position) {
        return position.equals(StringUtils.fromString(LEADING_HEADER)) ?
                getHeaders(messageObj) : getTrailerHeaders(messageObj);
    }

    private static HttpHeaders getHeaders(BObject messageObj) {
        HttpHeaders httpHeaders;
        if (messageObj.getNativeData(HTTP_HEADERS) != null) {
            httpHeaders = (HttpHeaders) messageObj.getNativeData(HTTP_HEADERS);
        } else {
            httpHeaders = new DefaultHttpHeaders();
            messageObj.addNativeData(HTTP_HEADERS, httpHeaders);
        }
        return httpHeaders;
    }

    private static HttpHeaders getTrailerHeaders(BObject messageObj) {
        HttpHeaders httpTrailerHeaders;
        if (messageObj.getNativeData(HTTP_TRAILER_HEADERS) != null) {
            httpTrailerHeaders = (HttpHeaders) messageObj.getNativeData(HTTP_TRAILER_HEADERS);
        } else {
            httpTrailerHeaders = new DefaultLastHttpContent().trailingHeaders();
            messageObj.addNativeData(HTTP_TRAILER_HEADERS, httpTrailerHeaders);
        }
        return httpTrailerHeaders;
    }

    public static Object getAuthorizationHeader(Environment env) {
        HttpCarbonMessage inboundMessage = (HttpCarbonMessage) env.getStrandLocal(HttpConstants.INBOUND_MESSAGE);
        String authorizationHeader = inboundMessage.getHeader(HttpHeaderNames.AUTHORIZATION.toString());
        if (authorizationHeader == null) {
            return HttpUtil.createHttpError("Http header does not exist", HEADER_NOT_FOUND_ERROR);
        }
        return StringUtils.fromString(authorizationHeader);
    }

    private ExternHeaders() {}
}
