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

import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contract.Constants;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

/**
 * A unit test class for Transport module HttpCarbonRequest class functions.
 */
public class HttpCarbonRequestTest {

    @Test
    public void testSetHttpVersion() {
        HttpRequest httpRequest = mock(HttpRequest.class);
        HttpCarbonRequest httpCarbonRequest = new HttpCarbonRequest(httpRequest);
        HttpVersion version = new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true);
        httpCarbonRequest.setHttpVersion(version);
        verify(httpRequest).setProtocolVersion(version);
    }

    @Test
    public void testSetHttpMethod() {
        HttpRequest httpRequest = mock(HttpRequest.class);
        HttpCarbonRequest httpCarbonRequest = new HttpCarbonRequest(httpRequest);
        HttpMethod method = new HttpMethod(Constants.HTTP_GET_METHOD);
        httpCarbonRequest.setHttpMethod(method);
        verify(httpRequest).setMethod(method);
    }

    @Test
    public void testSetURI() {
        HttpRequest httpRequest = mock(HttpRequest.class);
        HttpCarbonRequest httpCarbonRequest = new HttpCarbonRequest(httpRequest);
        String uri = "testURI";
        httpCarbonRequest.setUri(uri);
        verify(httpRequest).setUri(uri);
    }

}
