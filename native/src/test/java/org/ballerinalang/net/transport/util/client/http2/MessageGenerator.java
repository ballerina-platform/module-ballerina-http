/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
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

package org.ballerinalang.net.transport.util.client.http2;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpCarbonRequest;
import org.ballerinalang.net.transport.message.HttpCarbonResponse;
import org.ballerinalang.net.transport.util.TestUtil;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

import static org.ballerinalang.net.transport.util.TestUtil.HTTP_SCHEME;

/**
 * A utility class which generates HTTP/2.0 requests.
 */
public class MessageGenerator {
    public static HttpCarbonMessage generateRequest(HttpMethod httpMethod, String payload) {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonRequest(new DefaultHttpRequest(
                new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true), httpMethod,
                HTTP_SCHEME + TestUtil.TEST_HOST + ":" + TestUtil.HTTP_SERVER_PORT));
        return getHttpCarbonMessage(httpMethod, payload, httpCarbonMessage, TestUtil.HTTP_SERVER_PORT, true);
    }

    public static HttpCarbonMessage generateRequest(HttpMethod httpMethod, String payload, int port, String scheme) {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonRequest(new DefaultHttpRequest(
                new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true), httpMethod,
                scheme + TestUtil.TEST_HOST + ":" + port));
        return getHttpCarbonMessage(httpMethod, payload, httpCarbonMessage, port, true);
    }

    public static HttpCarbonMessage generateDelayedRequest(HttpMethod httpMethod) {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonRequest(new DefaultHttpRequest(
                new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true), httpMethod,
                HTTP_SCHEME + TestUtil.TEST_HOST + ":" + TestUtil.HTTP_SERVER_PORT));
        return getHttpCarbonMessage(httpMethod, null, httpCarbonMessage, TestUtil.HTTP_SERVER_PORT, false);
    }

    private static HttpCarbonMessage getHttpCarbonMessage(HttpMethod httpMethod, String payload,
                                                          HttpCarbonMessage httpCarbonMessage, int port,
                                                          boolean addLastHTTPContent) {
        httpCarbonMessage.setHttpMethod(httpMethod.toString());
        httpCarbonMessage.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        httpCarbonMessage.setProperty(Constants.HTTP_PORT, port);
        httpCarbonMessage.setHeader("Host", TestUtil.TEST_HOST + ":" + port);
        if (payload != null) {
            ByteBuffer byteBuffer = ByteBuffer.wrap(payload.getBytes(Charset.forName("UTF-8")));
            httpCarbonMessage.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(byteBuffer)));
        } else {
            if (addLastHTTPContent) {
                httpCarbonMessage.addHttpContent(new DefaultLastHttpContent());
            }
        }
        return httpCarbonMessage;
    }

    public static HttpCarbonMessage generateResponse(String response) {
        return generateResponse(response, null);
    }

    public static HttpCarbonMessage generateResponse(String response, HttpResponseStatus status) {
        if (status == null) {
            status = HttpResponseStatus.OK;
        }
        HttpCarbonMessage httpResponse = new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, status));
        httpResponse.setHeader(HttpHeaderNames.CONNECTION.toString(), HttpHeaderValues.KEEP_ALIVE.toString());
        httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
        httpResponse.setHttpStatusCode(status.code());

        if (response != null) {
            byte[] responseByteValues = response.getBytes(StandardCharsets.UTF_8);
            ByteBuffer responseValueByteBuffer = ByteBuffer.wrap(responseByteValues);
            httpResponse.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(responseValueByteBuffer)));
        } else {
            httpResponse.completeMessage();
        }
        return httpResponse;
    }
}
