/*
 *  Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.http2.trailer;

import io.ballerina.stdlib.http.transport.contentaware.listeners.TrailerHeaderListener;
import io.ballerina.stdlib.http.transport.trailer.TrailerHeaderTestTemplate;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import io.ballerina.stdlib.http.transport.util.Http2Util;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Test case for H2 trailer headers come along with inbound push response.
 *
 * @since 6.3.0
 */
public class H2ListenerPushResponseTrailerHeaderTestCase extends TrailerHeaderTestTemplate {
    private HttpClientConnector h2ClientWithPriorKnowledge;

    @BeforeClass
    public void setup() {
        ListenerConfiguration listenerConfiguration = Http2Util.getH2CListenerConfiguration();
        HttpHeaders trailers = new DefaultLastHttpContent().trailingHeaders();
        trailers.add("foo", "bar;q=0.8");
        trailers.add("jkl", "ballerina");
        super.setup(listenerConfiguration, trailers, TrailerHeaderListener.MessageType.PUSH_RESPONSE);

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = Http2Util.getH2CSenderConfiguration();
        h2ClientWithPriorKnowledge = new DefaultHttpWsConnectorFactory().createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test
    public void testHttp2ServerPush() {
        String expectedResource = "/main";
        String promisedPath = "/resource1";

        MessageSender msgSender = new MessageSender(h2ClientWithPriorKnowledge);
        HttpCarbonMessage request = MessageGenerator.generateRequest(HttpMethod.POST, expectedResource);
        // Submit a request and get the handle
        ResponseHandle handle = msgSender.submitMessage(request);
        assertNotNull(handle, "Response handle not found");

        // Look for promise
        assertTrue(msgSender.checkPromiseAvailability(handle), "Promise not available");
        // Get the promise
        Http2PushPromise promise = msgSender.getNextPromise(handle);
        assertNotNull(promise, "Promise not available");
        assertEquals(promise.getPath(), promisedPath, "Invalid Promise received");

        // Get the promised response
        HttpCarbonMessage promisedResponse = msgSender.getPushResponse(promise);
        assertNotNull(promisedResponse);
        String result = TestUtil.getStringFromInputStream(
                new HttpMessageDataStreamer(promisedResponse).getInputStream());
        assertTrue(result.contains(promisedPath), "Promised response not received");
        assertEquals(promisedResponse.getHeaders().get("Trailer"), "foo, jkl");
        assertEquals(promisedResponse.getTrailerHeaders().get("foo"), "bar;q=0.8");
        assertEquals(promisedResponse.getTrailerHeaders().get("jkl"), "ballerina");
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        super.cleanUp();
    }
}
