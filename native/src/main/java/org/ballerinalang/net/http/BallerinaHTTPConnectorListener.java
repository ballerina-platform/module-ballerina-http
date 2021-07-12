/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 */
package org.ballerinalang.net.http;

import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.constants.RuntimeConstants;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObservabilityConstants;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import org.ballerinalang.net.http.nativeimpl.ModuleUtils;
import org.ballerinalang.net.transport.contract.HttpConnectorListener;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_TRACE_PROPERTIES;
import static io.ballerina.runtime.observability.ObservabilityConstants.SERVER_CONNECTOR_HTTP;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_METHOD;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_URL;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_PROTOCOL;
import static org.ballerinalang.net.http.HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY;

/**
 * HTTP connector listener for Ballerina.
 */
public class BallerinaHTTPConnectorListener implements HttpConnectorListener {

    private static final Logger log = LoggerFactory.getLogger(BallerinaHTTPConnectorListener.class);
    protected static final String HTTP_RESOURCE = "httpResource";

    private final HTTPServicesRegistry httpServicesRegistry;

    protected final BMap endpointConfig;

    public BallerinaHTTPConnectorListener(HTTPServicesRegistry httpServicesRegistry, BMap endpointConfig) {
        this.httpServicesRegistry = httpServicesRegistry;
        this.endpointConfig = endpointConfig;
    }

    @Override
    public void onMessage(HttpCarbonMessage inboundMessage) {
        try {
            HttpResource httpResource;
            if (accessed(inboundMessage)) {
                httpResource = (HttpResource) inboundMessage.getProperty(HTTP_RESOURCE);
                extractPropertiesAndStartResourceExecution(inboundMessage, httpResource);
                return;
            }
            httpResource = HttpDispatcher.findResource(httpServicesRegistry, inboundMessage);
            if (HttpDispatcher.shouldDiffer(httpResource)) {
                inboundMessage.setProperty(HTTP_RESOURCE, httpResource);
                //Removes inbound content listener since data binding waits for all contents to be received
                //before executing its logic.
                inboundMessage.removeInboundContentListener();
                return;
            }
            try {
                if (httpResource != null) {
                    extractPropertiesAndStartResourceExecution(inboundMessage, httpResource);
                }
            } catch (BallerinaConnectorException ex) {
                HttpUtil.handleFailure(inboundMessage, ex.getMessage());
            }
        } catch (Exception ex) {
            HttpUtil.handleFailure(inboundMessage, ex.getMessage());
        }
    }

    @Override
    public void onError(Throwable throwable) {
        log.warn("Error in HTTP server connector: {}", throwable.getMessage());
    }

    @SuppressWarnings("unchecked")
    protected void extractPropertiesAndStartResourceExecution(HttpCarbonMessage inboundMessage,
                                                              HttpResource httpResource) {
        boolean isTransactionInfectable = httpResource.isTransactionInfectable();
        Map<String, Object> properties = collectRequestProperties(inboundMessage, isTransactionInfectable);
        Object[] signatureParams = HttpDispatcher.getSignatureParameters(httpResource, inboundMessage, endpointConfig);

        if (ObserveUtils.isObservabilityEnabled()) {
            ObserverContext observerContext = new ObserverContext();
            observerContext.setManuallyClosed(true);
            observerContext.setObjectName(SERVER_CONNECTOR_HTTP);
            Map<String, String> httpHeaders = new HashMap<>();
            inboundMessage.getHeaders().forEach(entry -> httpHeaders.put(entry.getKey(), entry.getValue()));
            observerContext.addProperty(PROPERTY_TRACE_PROPERTIES, httpHeaders);
            observerContext.addTag(TAG_KEY_HTTP_METHOD, inboundMessage.getHttpMethod());
            observerContext.addTag(TAG_KEY_PROTOCOL, (String) inboundMessage.getProperty(HttpConstants.PROTOCOL));
            observerContext.addTag(TAG_KEY_HTTP_URL, inboundMessage.getRequestUrl());
            properties.put(ObservabilityConstants.KEY_OBSERVER_CONTEXT, observerContext);
            inboundMessage.setProperty(OBSERVABILITY_CONTEXT_PROPERTY, observerContext);
        }
        Callback callback = new HttpCallableUnitCallback(inboundMessage, httpServicesRegistry.getRuntime(),
                                                         httpResource.getReturnMediaType());
        BObject service = httpResource.getParentService().getBalService();
        httpServicesRegistry.getRuntime().invokeMethodAsync(service, httpResource.getName(), null,
                                                            ModuleUtils.getOnMessageMetaData(), callback,
                                                            properties, httpResource.getBalResource().getReturnType(),
                                                            signatureParams);
    }

    protected boolean accessed(HttpCarbonMessage inboundMessage) {
        return inboundMessage.getProperty(HTTP_RESOURCE) != null;
    }

    private Map<String, Object> collectRequestProperties(HttpCarbonMessage inboundMessage, boolean isInfectable) {
        Map<String, Object> properties = new HashMap<>();
        if (inboundMessage.getProperty(HttpConstants.SRC_HANDLER) != null) {
            Object srcHandler = inboundMessage.getProperty(HttpConstants.SRC_HANDLER);
            properties.put(HttpConstants.SRC_HANDLER, srcHandler);
        }
        String txnId = inboundMessage.getHeader(HttpConstants.HEADER_X_XID);
        String registerAtUrl = inboundMessage.getHeader(HttpConstants.HEADER_X_REGISTER_AT_URL);
        String trxInfo = inboundMessage.getHeader(HttpConstants.HEADER_X_INFO_RECORD);
        //Return 500 if txn context is received when transactionInfectable=false
        if (!isInfectable && txnId != null) {
            log.error("Infection attempt on resource with transactionInfectable=false, txnId:" + txnId);
            throw new BallerinaConnectorException("Cannot create transaction context: " +
                                                          "resource is not transactionInfectable");
        }
        if (isInfectable && txnId != null && registerAtUrl != null && trxInfo != null) {
            properties.put(RuntimeConstants.GLOBAL_TRANSACTION_ID, txnId);
            properties.put(RuntimeConstants.TRANSACTION_URL, registerAtUrl);
            properties.put(RuntimeConstants.TRANSACTION_INFO, trxInfo);
        }
        properties.put(HttpConstants.REMOTE_ADDRESS, inboundMessage.getProperty(HttpConstants.REMOTE_ADDRESS));
        properties.put(HttpConstants.ORIGIN_HOST, inboundMessage.getHeader(HttpConstants.ORIGIN_HOST));
        properties.put(HttpConstants.POOLED_BYTE_BUFFER_FACTORY,
                       inboundMessage.getHeader(HttpConstants.POOLED_BYTE_BUFFER_FACTORY));
        properties.put(HttpConstants.INBOUND_MESSAGE, inboundMessage);
        return properties;
    }
}
