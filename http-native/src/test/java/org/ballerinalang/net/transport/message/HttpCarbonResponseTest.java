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

import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

/**
 * A unit test class for Transport module HttpCarbonResponse class functions.
 */
public class HttpCarbonResponseTest {

    @Test
    public void testSetStatus() {
        HttpResponse httpResponse = mock(HttpResponse.class);
        HttpCarbonResponse httpCarbonRequest = new HttpCarbonResponse(httpResponse);
        HttpResponseStatus status = new HttpResponseStatus(HttpResponseStatus.OK.code(),
                HttpResponseStatus.OK.reasonPhrase());
        httpCarbonRequest.setStatus(status);
        verify(httpCarbonRequest, times(1)).setStatus(status);
    }

}
