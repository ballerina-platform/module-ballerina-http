/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.transport.http2.http2forwardedextension;

import io.netty.handler.codec.http.DefaultHttpHeaders;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.config.ForwardedExtensionConfig;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.util.Http2Util;
import org.ballerinalang.net.transport.util.TestUtil;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.testng.AssertJUnit.assertEquals;

/**
 * Test HTTP2 forwarded behaviour.
 */
public class Http2ForwardedEnableWithoutForceHttp2 extends Http2ForwardedTestUtil {

    @BeforeClass
    public void setUp() throws InterruptedException {
        super.setUp(Http2Util.getForwardSenderConfigs(ForwardedExtensionConfig.ENABLE, false));
    }

    @Test
    public void testSingleHeader() {
        try {
            HttpCarbonMessage response = send(new DefaultHttpHeaders());
            assertEquals(response.getHeader(Constants.FORWARDED), "by=127.0.0.1; proto=http");

            response = send(new DefaultHttpHeaders()
                    .set(Constants.FORWARDED, "for=192.0.2.43;by=203.0.113.60;proto=http;host=example.com"));
            assertEquals(response.getHeader(Constants.FORWARDED),
                    "for=192.0.2.43, for=203.0.113.60; by=127.0.0.1; host=example.com; proto=http");
        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running forwarded enable single header test", e);
        }
    }

    @Test
    public void testMultipleHeader() {
        try {
            HttpCarbonMessage response = send(TestUtil.getForwardedHeaderSet1());
            assertEquals(response.getHeader(Constants.FORWARDED),
                    "for=203.0.113.60; by=127.0.0.1; host=example.com; proto=http");
            assertEquals(response.getHeader(Constants.X_FORWARDED_FOR), "123.34.24.67");

        } catch (Exception e) {
            TestUtil.handleException("Exception occurred while running forwarded enable multiple header test", e);
        }
    }
}
