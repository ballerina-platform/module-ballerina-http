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

import io.netty.handler.codec.http.HttpMessage;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;

/**
 * A unit test class for Transport module DefaultFullHttpMessageFuture class functions.
 */
public class DefaultFullHttpMessageFutureTest {

    @Test
    public void testNotifyFailure() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage);
        FullHttpMessageListener messageListener = mock(FullHttpMessageListener.class);
        DefaultFullHttpMessageFuture defaultFullHttpMessageFuture = new DefaultFullHttpMessageFuture(httpCarbonMessage);
        defaultFullHttpMessageFuture.notifyFailure(new Exception());
        defaultFullHttpMessageFuture.addListener(messageListener);
    }

}
