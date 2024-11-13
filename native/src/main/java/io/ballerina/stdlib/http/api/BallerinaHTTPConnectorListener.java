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
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.concurrent.StrandMetadata;
import io.ballerina.runtime.api.constants.RuntimeConstants;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObservabilityConstants;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_TRACE_PROPERTIES;
import static io.ballerina.runtime.observability.ObservabilityConstants.SERVER_CONNECTOR_HTTP;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_METHOD;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_URL;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_PROTOCOL;
import static io.ballerina.stdlib.http.api.HttpConstants.INTERCEPTORS;
import static io.ballerina.stdlib.http.api.HttpConstants.INTERCEPTOR_SERVICES_REGISTRIES;

/**
 * HTTP connector listener for Ballerina.
 */
public class BallerinaHTTPConnectorListener implements HttpConnectorListener {

    private static final Logger log = LoggerFactory.getLogger(BallerinaHTTPConnectorListener.class);
    protected static final String HTTP_RESOURCE = "httpResource";

    protected final HTTPServicesRegistry httpServicesRegistry;
    protected final List<HTTPInterceptorServicesRegistry> httpInterceptorServicesRegistries;

    protected final BMap endpointConfig;
    protected final Object listenerLevelInterceptors;

    public BallerinaHTTPConnectorListener(HTTPServicesRegistry httpServicesRegistry,
                                          List<HTTPInterceptorServicesRegistry> httpInterceptorServicesRegistries,
                                          BMap endpointConfig, Object interceptors) {
        this.httpInterceptorServicesRegistries = httpInterceptorServicesRegistries;
        this.httpServicesRegistry = httpServicesRegistry;
        this.endpointConfig = endpointConfig;
        this.listenerLevelInterceptors = interceptors;
    }

    @Override
    public void onMessage(HttpCarbonMessage inboundMessage) {
        if (Objects.isNull(inboundMessage.getProperty(INTERCEPTOR_SERVICES_REGISTRIES))) {
            setTargetServiceToInboundMsg(inboundMessage);
        }

        List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries =
                (List<HTTPInterceptorServicesRegistry>) inboundMessage.getProperty(INTERCEPTOR_SERVICES_REGISTRIES);

        try {
            if (executeInterceptorServices(interceptorServicesRegistries, inboundMessage)) {
                return;
            }
        } catch (Exception ex) {
            HttpRequestInterceptorUnitCallback callback = new HttpRequestInterceptorUnitCallback(inboundMessage,
                    httpServicesRegistry.getRuntime(), this);
            callback.invokeErrorInterceptors(HttpUtil.createError(ex), true);
            return;
        }

        if (inboundMessage.isInterceptorError()) {
            HttpRequestInterceptorUnitCallback callback = new HttpRequestInterceptorUnitCallback(inboundMessage,
                                                          httpServicesRegistry.getRuntime(), this);
            callback.returnErrorResponse(inboundMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR));
        } else {
            try {
                executeMainResourceOnMessage(inboundMessage);
            } catch (Exception ex) {
                HttpCallableUnitCallback callback = new HttpCallableUnitCallback(inboundMessage,
                        httpServicesRegistry.getRuntime());
                callback.invokeErrorInterceptors(HttpUtil.createError(ex), true);
            }
        }
    }

    private boolean executeInterceptorServices(List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries,
                                               HttpCarbonMessage inboundMessage) {
        int interceptorServiceIndex = inboundMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX)
                == null ? 0 : (int)  inboundMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX);
        while (interceptorServiceIndex < interceptorServicesRegistries.size()) {
            InterceptorResource interceptorResource;
            HTTPInterceptorServicesRegistry interceptorServicesRegistry = interceptorServicesRegistries.
                    get(interceptorServiceIndex);

            if (!interceptorServicesRegistry.getServicesType().
                                        equals(inboundMessage.getRequestInterceptorServiceState())) {
                interceptorServiceIndex += 1;
                continue;
            }

            interceptorResource = findInterceptorResource(interceptorServicesRegistry, inboundMessage);

            if (checkForInterceptorDataBinding(inboundMessage, interceptorServiceIndex, interceptorResource)) {
                return true;
            }

            interceptorServiceIndex += 1;

            if (interceptorResource != null) {
                inboundMessage.removeProperty(HttpConstants.WAIT_FOR_FULL_REQUEST);
                inboundMessage.setProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorServiceIndex);
                inboundMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE, true);
                extractPropertiesAndStartInterceptorResourceExecution(inboundMessage, interceptorResource,
                        interceptorServicesRegistry);
                return true;
            }
        }
        inboundMessage.removeProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX);
        return false;
    }

    private boolean checkForInterceptorDataBinding(HttpCarbonMessage inboundMessage, int interceptorServiceIndex,
                                                   InterceptorResource interceptorResource) {
        if (!inboundMessage.isLastHttpContentArrived() && HttpDispatcher.shouldDiffer(interceptorResource) &&
                inboundMessage.isAccessedInNonInterceptorService()) {
            inboundMessage.setProperty(HttpConstants.WAIT_FOR_FULL_REQUEST, true);
            inboundMessage.setProperty(HttpConstants.INTERCEPTOR_SERVICE, true);
            inboundMessage.setProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorServiceIndex);
            inboundMessage.removeInboundContentListener();
            return true;
        }
        return false;
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

        Object[] signatureParams = HttpDispatcher.getSignatureParameters(httpResource, inboundMessage, endpointConfig,
                httpServicesRegistry.getRuntime());

        if (ObserveUtils.isObservabilityEnabled()) {
            ObserverContext observerContext = new ObserverContext();
            observerContext.setManuallyClosed(true);
            observerContext.setObjectName(SERVER_CONNECTOR_HTTP);
            Map<String, String> httpHeaders = new HashMap<>();
            inboundMessage.getHeaders().forEach(entry -> httpHeaders.put(entry.getKey(), entry.getValue()));
            observerContext.addProperty(PROPERTY_TRACE_PROPERTIES, httpHeaders);
            observerContext.addTag(TAG_KEY_HTTP_METHOD, inboundMessage.getHttpMethod());
            observerContext.addTag(TAG_KEY_PROTOCOL, (String) inboundMessage.getProperty(HttpConstants.PROTOCOL));
            observerContext.addTag(TAG_KEY_HTTP_URL, httpResource.getAbsoluteResourcePath());
            properties.put(ObservabilityConstants.KEY_OBSERVER_CONTEXT, observerContext);
            inboundMessage.setProperty(HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY, observerContext);
        }
        Runtime runtime = httpServicesRegistry.getRuntime();
        HttpCallableUnitCallback callback = new HttpCallableUnitCallback(inboundMessage, runtime, httpResource,
                httpServicesRegistry.isPossibleLastService());
        BObject service = httpResource.getParentService().getBalService();
        String resourceName = httpResource.getName();
        ObjectType serviceType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(service));
        Thread.startVirtualThread(() -> {
            Object result;
            boolean isIsolated = serviceType.isIsolated() && serviceType.isIsolated(resourceName);
            StrandMetadata metaData = new StrandMetadata(isIsolated, properties);
            try {
                result = runtime.callMethod(service, resourceName, metaData, signatureParams);
                callback.handleResult(result);
            } catch (BError error) {
                callback.handlePanic(error);
            }
        });
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

    protected void extractPropertiesAndStartInterceptorResourceExecution(HttpCarbonMessage inboundMessage,
                                                                         InterceptorResource resource,
                                                                         HTTPInterceptorServicesRegistry registry) {

        Map<String, Object> properties = collectRequestProperties(inboundMessage, true);
        Runtime runtime = registry.getRuntime();
        Object[] signatureParams = HttpDispatcher.getSignatureParameters(resource, inboundMessage, endpointConfig,
                registry.getRuntime());
        HttpRequestInterceptorUnitCallback callback = new HttpRequestInterceptorUnitCallback(inboundMessage, runtime,
                this);
        BObject service = resource.getParentService().getBalService();
        String resourceName = resource.getName();

        inboundMessage.removeProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);

        ObjectType serviceType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(service));
        Thread.startVirtualThread(() -> {
            boolean isIsolated = serviceType.isIsolated() && serviceType.isIsolated(resourceName);
            StrandMetadata metaData = new StrandMetadata(isIsolated, properties);
            try {
                Object result = runtime.callMethod(service, resourceName, metaData, signatureParams);
                callback.handleResult(result);
            } catch (BError error) {
                callback.handlePanic(error);
            }
        });
    }

    protected void executeMainResourceOnMessage(HttpCarbonMessage inboundMessage) {
        HttpResource httpResource;
        if (accessed(inboundMessage)) {
            inboundMessage.removeProperty(HttpConstants.WAIT_FOR_FULL_REQUEST);
            httpResource = (HttpResource) inboundMessage.getProperty(HTTP_RESOURCE);
            extractPropertiesAndStartResourceExecution(inboundMessage, httpResource);
            return;
        }
        httpResource = HttpDispatcher.findResource(httpServicesRegistry, inboundMessage);
        // Checking whether main resource has data-binding and if we already executed an interceptor resource
        // we skip getting the full request
        if (!inboundMessage.isLastHttpContentArrived() && HttpDispatcher.shouldDiffer(httpResource) &&
                inboundMessage.isAccessedInNonInterceptorService()) {
            inboundMessage.setProperty(HTTP_RESOURCE, httpResource);
            inboundMessage.setProperty(HttpConstants.WAIT_FOR_FULL_REQUEST, true);
            //Removes inbound content listener since data binding waits for all contents to be received
            //before executing its logic.
            inboundMessage.removeInboundContentListener();
            return;
        }
        try {
            if (httpResource != null) {
                inboundMessage.removeProperty(HttpConstants.INTERCEPTOR_SERVICE);
                extractPropertiesAndStartResourceExecution(inboundMessage, httpResource);
            }
        } catch (BallerinaConnectorException ex) {
            HttpCallableUnitCallback callback = new HttpCallableUnitCallback(inboundMessage,
                    httpServicesRegistry.getRuntime());
            callback.invokeErrorInterceptors(HttpUtil.createError(ex), true);
        }
    }

    private InterceptorResource findInterceptorResource(HTTPInterceptorServicesRegistry interceptorServicesRegistry,
                                                                HttpCarbonMessage inboundMessage) {
        try {
            return HttpDispatcher.findInterceptorResource(interceptorServicesRegistry, inboundMessage);
        } catch (Exception e) {
            // Return null to continue interception when there is no matching service, resource or resource method found
            if (e.getMessage().startsWith("no matching resource found for path")
                    || e.getMessage().startsWith("Method not allowed") ||
                    e.getMessage().startsWith("no matching service found for path")) {
                return null;
            } else {
                throw e;
            }
        }
    }

    private void setTargetServiceToInboundMsg(HttpCarbonMessage inboundMessage) {
        inboundMessage.setProperty(INTERCEPTOR_SERVICES_REGISTRIES, httpInterceptorServicesRegistries);
        inboundMessage.setProperty(INTERCEPTORS, listenerLevelInterceptors);
        try {
            HttpService targetService = HttpDispatcher.findService(httpServicesRegistry, inboundMessage, true);
            inboundMessage.setProperty(HttpConstants.TARGET_SERVICE, targetService.getBalService());
            if (targetService.hasInterceptors()) {
                inboundMessage.setProperty(INTERCEPTORS, targetService.getBalInterceptorServicesArray());
                inboundMessage.setProperty(INTERCEPTOR_SERVICES_REGISTRIES,
                                           targetService.getInterceptorServicesRegistries());
            }
        } catch (Exception e) {
            if (((BArray) listenerLevelInterceptors).size() == 1 &&
                    e instanceof BError && ((BError) e).getType().getName()
                    .equals(HttpErrorType.INTERNAL_SERVICE_NOT_FOUND_ERROR.getErrorName())) {
                HttpService singleService = HttpDispatcher.findSingleService(httpServicesRegistry);
                if (singleService != null && singleService.hasInterceptors()) {
                    inboundMessage.setProperty(INTERCEPTORS, singleService.getBalInterceptorServicesArray());
                    inboundMessage.setProperty(INTERCEPTOR_SERVICES_REGISTRIES,
                            singleService.getInterceptorServicesRegistries());
                }
            }
            inboundMessage.setProperty(HttpConstants.TARGET_SERVICE, HttpUtil.createError(e));
        }
    }
}
