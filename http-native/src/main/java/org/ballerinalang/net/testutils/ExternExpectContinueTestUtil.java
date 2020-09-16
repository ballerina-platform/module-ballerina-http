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

package org.ballerinalang.net.testutils;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;

import org.ballerinalang.net.testutils.client.HttpClient;
import org.ballerinalang.net.testutils.client.HttpUrlClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Contains utility functions used for verifying the server-side 100-continue behaviour.
 */
public class ExternExpectContinueTestUtil {

    private static final Logger log = LoggerFactory.getLogger(ExternExpectContinueTestUtil.class);

    //Test 100 continue response and for request with expect:100-continue header
    public static boolean externTest100Continue(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest httpRequest = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/continue");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(Utils.LARGE_ENTITY.getBytes()));

        httpRequest.headers().set(HttpHeaderNames.CONTENT_LENGTH, Utils.LARGE_ENTITY.getBytes().length);
        httpRequest.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);
        httpRequest.headers().set("X-Status", "Positive");

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(httpRequest, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 100-continue response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.CONTINUE);
        Assert.assertEquals(Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH)), 0);

        // Actual response
        String responsePayload = Utils.getEntityBodyFrom(responses.get(1));
        Assert.assertEquals(responses.get(1).status(), HttpResponseStatus.OK);
        Assert.assertEquals(responsePayload, Utils.LARGE_ENTITY);
        Assert.assertEquals(responsePayload.getBytes().length, Utils.LARGE_ENTITY.getBytes().length);
        Assert.assertEquals(Integer.parseInt(responses.get(1).headers().get(HttpHeaderNames.CONTENT_LENGTH)),
                            Utils.LARGE_ENTITY.getBytes().length);
        return true;
    }

    //Test ignoring inbound payload with a 417 response for request with expect:100-continue header")
    public static boolean externTest100ContinueNegative(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest httpRequest = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/continue");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(Utils.LARGE_ENTITY.getBytes()));

        httpRequest.headers().set(HttpHeaderNames.CONTENT_LENGTH, Utils.LARGE_ENTITY.getBytes().length);
        httpRequest.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(httpRequest, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 417 Expectation Failed response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.EXPECTATION_FAILED, "Response code mismatch");
        int length = Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH));
        Assert.assertEquals(length, 26, "Content length mismatched");
        String payload = responses.get(0).content().readCharSequence(length, Charset.defaultCharset()).toString();
        Assert.assertEquals(payload, "Do not send me any payload", "Entity body mismatched");
        // Actual response
        Assert.assertEquals(responses.size(), 1,
                            "Multiple responses received when only a 417 response was expected");
        return true;
    }

    //Test multipart form data request with expect:100-continue header
    public static boolean externTestMultipartWith100ContinueHeader(int servicePort) {
        Map<String, String> headers = new HashMap<>();
        headers.put(HttpHeaderNames.EXPECT.toString(), HttpHeaderValues.CONTINUE.toString());

        Map<String, String> formData = new HashMap<>();
        formData.put("person", "engineer");
        formData.put("team", "ballerina");

        HttpResponse response = null;
        try {
            response = HttpUrlClient.doMultipartFormData(
                    HttpUrlClient.getServiceURLHttp(servicePort, "continue/getFormParam"), headers, formData);
        } catch (IOException e) {
            log.error("Error in processing multipart HTTP request" + e.getMessage());
            return false;
        }
        Assert.assertNotNull(response);
        Assert.assertEquals(response.getResponseCode(), 200, "Response code mismatched");
        Assert.assertEquals(response.getData(), "Result = Key:person Value: engineer Key:team Value: ballerina");
        return true;
    }

    public static boolean externTest100ContinuePassthrough(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest reqHeaders = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST,
                                                               "/continue/testPassthrough");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(Utils.LARGE_ENTITY.getBytes()));

        reqHeaders.headers().set(HttpHeaderNames.CONTENT_LENGTH, Utils.LARGE_ENTITY.getBytes().length);
        reqHeaders.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(reqHeaders, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 100-continue response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.CONTINUE);
        Assert.assertEquals(Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH)), 0);

        // Actual response
        String responsePayload = Utils.getEntityBodyFrom(responses.get(1));
        Assert.assertEquals(responses.get(1).status(), HttpResponseStatus.OK);
        Assert.assertEquals(responsePayload, Utils.LARGE_ENTITY);
        Assert.assertEquals(responsePayload.getBytes().length, Utils.LARGE_ENTITY.getBytes().length);
        Assert.assertEquals(Integer.parseInt(responses.get(1).headers().get(HttpHeaderNames.CONTENT_LENGTH)),
                            Utils.LARGE_ENTITY.getBytes().length);
        return true;
    }

    private ExternExpectContinueTestUtil() {
    }
}
