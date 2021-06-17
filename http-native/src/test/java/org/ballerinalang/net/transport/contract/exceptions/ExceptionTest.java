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

package org.ballerinalang.net.transport.contract.exceptions;

import io.netty.handler.codec.http.HttpResponseStatus;
import org.ballerinalang.net.transport.contract.websocket.WebSocketConnectorException;
import org.ballerinalang.net.transport.contractimpl.common.certificatevalidation.CertificateVerificationException;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * A unit test class for transport module Exception class.
 */
public class ExceptionTest {

    @Test
    public void testClientClosedConnectionException() {
        ClientClosedConnectionException exception = new ClientClosedConnectionException("error");
        Assert.assertEquals(exception.getMessage(), "error");
    }

    @Test
    public void testClientClosedConnectionExceptionWithException() {
        Exception inputException = new Exception("error");
        ClientClosedConnectionException exception = new ClientClosedConnectionException(inputException);
        Assert.assertEquals(exception.getMessage(), "java.lang.Exception: error");

        exception = new ClientClosedConnectionException("error_new", inputException);
        Assert.assertEquals(exception.getMessage(), "error_new");
    }

    @Test
    public void testClientConnectorException() {
        ClientConnectorException exception = new ClientConnectorException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testConfigurationException() {
        ConfigurationException exception = new ConfigurationException("error");
        Assert.assertEquals(exception.getMessage(), "error");
    }

    @Test
    public void testConnectionTimedOutException() {
        ConnectionTimedOutException exception = new ConnectionTimedOutException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testEndpointTimeOutException() {
        EndpointTimeOutException exception = new EndpointTimeOutException("id", "error");
        Assert.assertEquals(exception.getOutboundChannelID(), "id");
        Assert.assertEquals(exception.getMessage(), "error");
    }

    @Test
    public void testInvalidProtocolException() {
        InvalidProtocolException exception = new InvalidProtocolException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testPromiseRejectedException() {
        PromiseRejectedException exception = new PromiseRejectedException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testRequestCancelledException() {
        RequestCancelledException exception = new RequestCancelledException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testUnresolvedHostException() {
        UnresolvedHostException exception = new UnresolvedHostException("error",
                HttpResponseStatus.BAD_REQUEST.code());
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getHttpStatusCode(), HttpResponseStatus.BAD_REQUEST.code());
    }

    @Test
    public void testWebSocketConnectorException() {
        WebSocketConnectorException exception = new WebSocketConnectorException("error");
        Assert.assertEquals(exception.getMessage(), "error");
    }

    @Test
    public void testCertificateVerificationException() {
        CertificateVerificationException exception = new CertificateVerificationException("error");
        Assert.assertEquals(exception.getMessage(), "error");

        Throwable throwable = new Throwable("This is a throwable");
        exception = new CertificateVerificationException(throwable);
        Assert.assertEquals(exception.getCause().getMessage(), "This is a throwable");

        exception = new CertificateVerificationException("error", throwable);
        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getCause().getMessage(), "This is a throwable");
    }


}
