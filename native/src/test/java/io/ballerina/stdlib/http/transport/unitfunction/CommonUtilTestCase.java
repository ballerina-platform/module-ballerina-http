/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.unitfunction;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contract.exceptions.ConfigurationException;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.DefaultHttpHeaders;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.Attribute;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.Map;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * A unit test class for common/Util functions.
 */
public class CommonUtilTestCase {

    @Test(description = "Test setting headers to Http request with duplicate header keys")
    public void testCreateHttpRequest() {
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.set("aaa", "123");
        headers.add("aaa", "xyz");
        HttpCarbonMessage outboundRequestMsg = new HttpCarbonMessage(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "", headers));
        outboundRequestMsg.setProperty(Constants.TO, "/hello");
        HttpRequest outboundNettyRequest = Util.createHttpRequest(outboundRequestMsg);

        Assert.assertEquals(outboundNettyRequest.method(), HttpMethod.POST);
        Assert.assertEquals(outboundNettyRequest.protocolVersion(), HttpVersion.HTTP_1_1);
        Assert.assertEquals(outboundNettyRequest.uri(), "/hello");
        Assert.assertEquals(outboundNettyRequest.headers().getAll("aaa").size(), 2);
        Assert.assertEquals(outboundNettyRequest.headers().getAll("aaa").get(0), "123");
        Assert.assertEquals(outboundNettyRequest.headers().getAll("aaa").get(1), "xyz");
    }

    @Test(description = "Test setting headers to Http response with duplicate header keys")
    public void testCreateHttpResponse() {
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.set("aaa", "123");
        headers.add("aaa", "xyz");
        HttpCarbonMessage outboundResponseMsg = new HttpCarbonMessage(
                new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK, headers));
        HttpResponse outboundNettyResponse = Util.createHttpResponse(outboundResponseMsg, "1.1", "test-server", true);

        Assert.assertEquals(outboundNettyResponse.protocolVersion(), HttpVersion.HTTP_1_1);
        Assert.assertEquals(outboundNettyResponse.status(), HttpResponseStatus.OK);
        Assert.assertEquals(outboundNettyResponse.headers().getAll("aaa").size(), 2);
        Assert.assertEquals(outboundNettyResponse.headers().getAll("aaa").get(0), "123");
        Assert.assertEquals(outboundNettyResponse.headers().getAll("aaa").get(1), "xyz");
    }

    @Test(description = "Test setting content length header to non entity body request")
    public void testCheckContentLengthHeaderAllowanceForGetRequest() {
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.set(HttpHeaderNames.CONTENT_LENGTH, 10);
        HttpCarbonMessage httpOutboundRequest = new HttpCarbonMessage(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/get", headers));
        httpOutboundRequest.setHttpMethod(HttpMethod.GET.toString());
        httpOutboundRequest.setProperty(Constants.NO_ENTITY_BODY, true);
        boolean allow = Util.checkContentLengthAndTransferEncodingHeaderAllowance(httpOutboundRequest);

        Assert.assertEquals(allow, false, "Content length header should not be updated");
        Assert.assertEquals(httpOutboundRequest.getHeader(HttpHeaderNames.CONTENT_LENGTH.toString()), null,
                            "Content length header should be removed");
    }

    @Test(description = "Test setting content length header to entity body request")
    public void testCheckContentLengthHeaderAllowanceForGetRequestWithBody() {
        HttpHeaders headers = new DefaultHttpHeaders();
        headers.set(HttpHeaderNames.CONTENT_LENGTH, 10);
        HttpCarbonMessage httpOutboundRequest = new HttpCarbonMessage(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/get", headers));
        httpOutboundRequest.setHttpMethod(HttpMethod.GET.toString());
        httpOutboundRequest.setProperty(Constants.NO_ENTITY_BODY, false);
        boolean allow = Util.checkContentLengthAndTransferEncodingHeaderAllowance(httpOutboundRequest);

        Assert.assertEquals(allow, true, "Content length header should be updated");
        Assert.assertEquals(httpOutboundRequest.getHeader(HttpHeaderNames.CONTENT_LENGTH.toString()), "10",
                            "Content length header is been removed");
    }

    @Test
    public void testGetIntProperty() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", 15);
        Assert.assertEquals(Util.getIntProperty(properties, "key", 10), 15);

        Assert.assertEquals(Util.getIntProperty(properties, "keyNew", 10), 10);

        Assert.assertEquals(Util.getIntProperty(null, "key", 10), 10);
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Property : key must be an integer")
    public void testGetIntPropertyIllegalArgument() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", "invalid");
        Util.getIntProperty(properties, "key", 10);
    }

    @Test
    public void testGetStringProperty() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", "value");
        Assert.assertEquals(Util.getStringProperty(properties, "key", "default"), "value");

        Assert.assertEquals(Util.getStringProperty(properties, "keyNew", "default"), "default");

        Assert.assertEquals(Util.getStringProperty(null, "key", "default"), "default");
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Property : key must be a string")
    public void testGetStringPropertyIllegalArgument() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", 10);
        Util.getStringProperty(properties, "key", "default");
    }

    @Test
    public void testGetBooleanProperty() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", false);
        Assert.assertFalse(Util.getBooleanProperty(properties, "key", true));

        Assert.assertTrue(Util.getBooleanProperty(properties, "keyNew", true));

        Assert.assertTrue(Util.getBooleanProperty(null, "key", true));
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Property : key must be a boolean")
    public void testGetBooleanPropertyIllegalArgument() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("key", "invalid");
        Util.getBooleanProperty(properties, "key", true);
    }

    @Test
    public void testGetLongProperty() {
        Map<String, Object> properties = new HashMap<>();
        long value = 5;
        long defaultVal = 10;
        properties.put("key", value);
        long returnVal = Util.getLongProperty(properties, "key", defaultVal);
        Assert.assertEquals(returnVal, value);

        returnVal = Util.getLongProperty(properties, "keyNew", defaultVal);
        Assert.assertEquals(returnVal, defaultVal);

        returnVal = Util.getLongProperty(null, "keyNew", defaultVal);
        Assert.assertEquals(returnVal, defaultVal);
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Property : key must be a long")
    public void testGetLongPropertyIllegalArgument() {
        Map<String, Object> properties = new HashMap<>();
        long defaultVal = 10;
        properties.put("key", "invalid");
        Util.getLongProperty(properties, "key", defaultVal);
    }

    @Test (expectedExceptions = RuntimeException.class,
            expectedExceptionsMessageRegExp = "System property carbon.home is not specified")
    public void testSubstituteVariablesWithUnspecifiedVariable() {
        Util.substituteVariables("${carbon.home} ");
    }

    @Test
    public void testResetChannelAttributes() {
        ChannelHandlerContext ctx = mock(ChannelHandlerContext.class);
        Channel channel = mock(Channel.class);
        when(ctx.channel()).thenReturn(channel);
        Attribute<HttpResponseFuture> attr1 = mock(Attribute.class);
        when(channel.attr(Constants.RESPONSE_FUTURE_OF_ORIGINAL_CHANNEL)).thenReturn(attr1);
        Attribute<HttpCarbonMessage> attr2 = mock(Attribute.class);
        when(channel.attr(Constants.ORIGINAL_REQUEST)).thenReturn(attr2);
        Attribute<Integer> attr3 = mock(Attribute.class);
        when(channel.attr(Constants.REDIRECT_COUNT)).thenReturn(attr3);
        Attribute<String> attr4 = mock(Attribute.class);
        when(channel.attr(Constants.RESOLVED_REQUESTED_URI_ATTR)).thenReturn(attr4);
        Attribute<Long> attr5 = mock(Attribute.class);
        when(channel.attr(Constants.ORIGINAL_CHANNEL_START_TIME)).thenReturn(attr5);
        Attribute<Integer> attr6 = mock(Attribute.class);
        when(channel.attr(Constants.ORIGINAL_CHANNEL_TIMEOUT)).thenReturn(attr6);

        Util.resetChannelAttributes(ctx);

        verify(attr1).set(null);
        verify(attr2).set(null);
        verify(attr3).set(null);
        verify(attr4).set(null);
        verify(attr5).set(null);
        verify(attr6).set(null);
    }

    @Test
    public void testIsKeepAlive() throws ConfigurationException {
        HttpCarbonMessage outboundRequestMsg = mock(HttpCarbonMessage.class);
        HttpCarbonMessage inboundRequestMsg = mock(HttpCarbonMessage.class);
        Assert.assertFalse(Util.isKeepAlive(KeepAliveConfig.NEVER, outboundRequestMsg, inboundRequestMsg));
    }

}
