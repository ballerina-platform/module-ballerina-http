/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.transport.message;

import io.netty.handler.codec.http.HttpHeaderNames;
import org.ballerinalang.net.transport.util.client.http2.MessageGenerator;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.io.InputStream;
import java.util.zip.InflaterInputStream;

/**
 * A unit test class for Transport module HttpMessageDataStreamer class functions.
 */
public class HttpMessageDataStreamerTest {

    @Test
    public void testGetInputStreamWithContentEncoding() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateResponse("testResponse");
        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "gzip");
        HttpMessageDataStreamer httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "deflate");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        InputStream returnVal = httpMessageDataStreamer.getInputStream();
        Assert.assertTrue(returnVal instanceof InflaterInputStream);
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "identity");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "test");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

    }

}
