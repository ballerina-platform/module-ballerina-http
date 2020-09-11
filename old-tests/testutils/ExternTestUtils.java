/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import org.ballerinalang.jvm.values.ObjectValue;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.testutils.client.HttpClient;
import org.wso2.transport.http.netty.contract.config.TransportsConfiguration;
import org.wso2.transport.http.netty.contract.config.YAMLTransportConfigurationBuilder;
//import org.testng.Assert;

import java.util.List;

/**
 * Contains utility functions used by mime test cases.
 *
 * @since slp4
 */
public class ExternTestUtils {

    public static void externTest100Continue(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest httpRequest = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/continue");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(Payloads.LARGE_ENTITY.getBytes()));

        httpRequest.headers().set(HttpHeaderNames.CONTENT_LENGTH, Payloads.LARGE_ENTITY.getBytes().length);
        httpRequest.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);
        httpRequest.headers().set("X-Status", "Positive");

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(httpRequest, reqPayload);

//        Assert.assertFalse(httpClient.waitForChannelClose());
//
//        // 100-continue response
//        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.CONTINUE);
//        Assert.assertEquals(Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH)), 0);
//
//        // Actual response
//        String responsePayload = Payloads.getEntityBodyFrom(responses.get(1));
//        Assert.assertEquals(responses.get(1).status(), HttpResponseStatus.OK);
//        Assert.assertEquals(responsePayload, Payloads.LARGE_ENTITY);
//        Assert.assertEquals(responsePayload.getBytes().length, Payloads.LARGE_ENTITY.getBytes().length);
//        Assert.assertEquals(Integer.parseInt(responses.get(1).headers().get(HttpHeaderNames.CONTENT_LENGTH)),
//                            Payloads.LARGE_ENTITY.getBytes().length);
    }

    private ExternTestUtils() {
    }
}
