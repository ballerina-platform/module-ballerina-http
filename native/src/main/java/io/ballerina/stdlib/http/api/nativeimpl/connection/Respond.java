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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.nativeimpl.connection;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HTTPInterceptorServicesRegistry;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpDispatcher;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpResponseInterceptorUnitCallback;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.InterceptorService;
import io.ballerina.stdlib.http.api.client.caching.ResponseCacheControlObj;
import io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipelinedResponse;
import io.ballerina.stdlib.http.api.util.CacheUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.CompletableFuture;

import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_KEY_HTTP_STATUS_CODE;
import static io.ballerina.stdlib.http.api.HttpConstants.INTERCEPTOR_SERVICES_REGISTRIES;
import static io.ballerina.stdlib.http.api.HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY;
import static io.ballerina.stdlib.http.api.HttpConstants.RESPONSE_CACHE_CONTROL_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.RESPONSE_STATUS_CODE_FIELD;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;
import static io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipeliningHandler.executePipeliningLogic;
import static io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipeliningHandler.pipeliningRequired;
import static io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipeliningHandler.setPipeliningListener;

/**
 * Extern function to respond back the caller with outbound response.
 *
 * @since 0.96
 */
public class Respond extends ConnectionAction {

    private static final Logger log = LoggerFactory.getLogger(Respond.class);

    public static Object nativeRespondError(Environment env, BObject connectionObj, BObject outboundResponseObj,
                                            BError error) {
        HttpCarbonMessage inboundRequest = HttpUtil.getCarbonMsg(connectionObj, null);
        inboundRequest.setProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR, error);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            nativeRespondWithDataCtx(env, connectionObj, outboundResponseObj, new DataContext(env, balFuture,
                    inboundRequest));
            return getResult(balFuture);
        });
    }

    public static Object nativeRespond(Environment env, BObject connectionObj, BObject outboundResponseObj) {
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            nativeRespondWithDataCtx(env, connectionObj, outboundResponseObj, new DataContext(env,
                    balFuture, HttpUtil.getCarbonMsg(connectionObj, null)));
            return getResult(balFuture);
        });
    }

    public static Object nativeRespondWithDataCtx(Environment env, BObject connectionObj, BObject outboundResponseObj,
                                                  DataContext dataContext) {
        HttpCarbonMessage inboundRequestMsg = HttpUtil.getCarbonMsg(connectionObj, null);
        if (invokeResponseInterceptor(env, inboundRequestMsg, outboundResponseObj, connectionObj, dataContext)) {
            return null;
        }
        if (isDirtyResponse(outboundResponseObj)) {
            String errorMessage = "Couldn't complete the respond operation as the response has been already used.";
            HttpUtil.sendOutboundResponse(inboundRequestMsg, HttpUtil.createErrorMessage(errorMessage, 500));
            if (log.isDebugEnabled()) {
                log.debug("Couldn't complete the respond operation for the sequence id of the request: {} " +
                                  "as the response has been already used.", inboundRequestMsg.getSequenceId());
            }
            BError httpError = HttpUtil.createHttpError(errorMessage, HttpErrorType.GENERIC_LISTENER_ERROR);
            dataContext.getFuture().complete(httpError);
            return null;
        }
        outboundResponseObj.addNativeData(HttpConstants.DIRTY_RESPONSE, true);
        HttpCarbonMessage outboundResponseMsg = HttpUtil.getCarbonMsg(outboundResponseObj, HttpUtil.
                    createHttpCarbonMessage(false));
        outboundResponseMsg.setPipeliningEnabled(inboundRequestMsg.isPipeliningEnabled());
        outboundResponseMsg.setSequenceId(inboundRequestMsg.getSequenceId());
        setCacheControlHeader(outboundResponseObj, outboundResponseMsg);
        HttpUtil.prepareOutboundResponse(connectionObj, inboundRequestMsg, outboundResponseMsg, outboundResponseObj);

        try {
            HttpUtil.checkFunctionValidity(inboundRequestMsg, outboundResponseMsg);
        } catch (BError e) {
            log.debug(e.getPrintableStackTrace(), e);
            dataContext.getFuture().complete(e);
            return null;
        }

        // Based on https://tools.ietf.org/html/rfc7232#section-4.1
        if (CacheUtils.isValidCachedResponse(outboundResponseMsg, inboundRequestMsg)) {
            outboundResponseMsg.setHttpStatusCode(HttpResponseStatus.NOT_MODIFIED.code());
            outboundResponseMsg.setProperty(HttpConstants.HTTP_REASON_PHRASE,
                                            HttpResponseStatus.NOT_MODIFIED.reasonPhrase());
            outboundResponseMsg.removeHeader(HttpHeaderNames.CONTENT_LENGTH.toString());
            outboundResponseMsg.removeHeader(HttpHeaderNames.CONTENT_TYPE.toString());
            outboundResponseMsg.waitAndReleaseAllEntities();
            outboundResponseMsg.completeMessage();
        }

        if (ObserveUtils.isObservabilityEnabled()) {
            int statusCode = (int) outboundResponseObj.getIntValue(RESPONSE_STATUS_CODE_FIELD);
            ObserverContext observerContext = ObserveUtils.getObserverContextOfCurrentFrame(env);
            // setting the status-code in the observability context for the current strand
            // this is done for the `caller->respond()`
            if (observerContext != null) {
                observerContext.addProperty(PROPERTY_KEY_HTTP_STATUS_CODE, statusCode);
            }
            // setting the status-code in the observability context for the resource span
            observerContext = (ObserverContext) inboundRequestMsg.getProperty(OBSERVABILITY_CONTEXT_PROPERTY);
            if (observerContext != null) {
                observerContext.addProperty(PROPERTY_KEY_HTTP_STATUS_CODE, statusCode);
            }
        }
        try {
            if (pipeliningRequired(inboundRequestMsg)) {
                if (log.isDebugEnabled()) {
                    log.debug("Pipelining is required. Sequence id of the request: {}",
                            inboundRequestMsg.getSequenceId());
                }
                PipelinedResponse pipelinedResponse = new PipelinedResponse(inboundRequestMsg, outboundResponseMsg,
                                                                            dataContext, outboundResponseObj);
                setPipeliningListener(outboundResponseMsg);
                executePipeliningLogic(inboundRequestMsg.getSourceContext(), pipelinedResponse);
            } else {
                sendOutboundResponseRobust(dataContext, inboundRequestMsg, outboundResponseObj, outboundResponseMsg);
            }
        } catch (BError e) {
            log.debug(e.getPrintableStackTrace(), e);
            dataContext.getFuture().complete(
                    HttpUtil.createHttpError(e.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR));
        } catch (Throwable e) {
            //Exception is already notified by http transport.
            String errorMessage = "Couldn't complete outbound response: " + e.getMessage();
            log.debug(errorMessage, e);
            dataContext.getFuture().complete(
                    HttpUtil.createHttpError(errorMessage, HttpErrorType.GENERIC_LISTENER_ERROR));
        }
        return null;
    }

    private static void setCacheControlHeader(BObject outboundRespObj, HttpCarbonMessage outboundResponse) {
        BObject cacheControl = (BObject) outboundRespObj.get(RESPONSE_CACHE_CONTROL_FIELD);
        if (cacheControl != null &&
                outboundResponse.getHeader(HttpHeaderNames.CACHE_CONTROL.toString()) == null) {
            ResponseCacheControlObj respCC = new ResponseCacheControlObj(cacheControl);
            outboundResponse.setHeader(HttpHeaderNames.CACHE_CONTROL.toString(), respCC.buildCacheControlDirectives());
        }
    }

    private static boolean isDirtyResponse(BObject outboundResponseObj) {
        return outboundResponseObj.get(RESPONSE_CACHE_CONTROL_FIELD) == null && outboundResponseObj.
                getNativeData(HttpConstants.DIRTY_RESPONSE) != null;
    }

    private Respond() {}

    public static boolean invokeResponseInterceptor(Environment env, HttpCarbonMessage inboundMessage,
                                                    BObject outboundResponseObj, BObject callerObj,
                                                    DataContext dataContext) {
        List<HTTPInterceptorServicesRegistry> interceptorServicesRegistries =
                (List<HTTPInterceptorServicesRegistry>) inboundMessage.getProperty(INTERCEPTOR_SERVICES_REGISTRIES);
        if (interceptorServicesRegistries.isEmpty()) {
            return false;
        }
        int interceptorServiceIndex = getResponseInterceptorIndex(inboundMessage, interceptorServicesRegistries.size());
        while (interceptorServiceIndex >= 0) {
            HTTPInterceptorServicesRegistry interceptorServicesRegistry = interceptorServicesRegistries.
                    get(interceptorServiceIndex);

            if (!interceptorServicesRegistry.getServicesType().equals(
                    inboundMessage.getResponseInterceptorServiceState())) {
                interceptorServiceIndex -= 1;
                inboundMessage.setProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorServiceIndex);
                continue;
            }

            try {
                InterceptorService service = HttpDispatcher.findInterceptorService(interceptorServicesRegistry,
                                             inboundMessage, true);
                if (service == null) {
                    throw new BallerinaConnectorException("no Interceptor Service found to handle the response");
                }

                if (interceptorServiceIndex == 0 && inboundMessage.isInterceptorInternalError()) {
                    BError bError = (BError) inboundMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
                    bError.printStackTrace();
                }

                interceptorServiceIndex -= 1;
                inboundMessage.setProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorServiceIndex);
                startInterceptResponseMethod(inboundMessage, outboundResponseObj, callerObj, service, env,
                        interceptorServicesRegistry, dataContext);
                return true;
            } catch (Exception e) {
                throw HttpUtil.createHttpError(e.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR);
            }
        }
        // Handling error panics
        if (inboundMessage.isInterceptorError()) {
            HttpResponseInterceptorUnitCallback callback = new HttpResponseInterceptorUnitCallback(inboundMessage,
                    callerObj, outboundResponseObj, env, dataContext, null, false);
            callback.sendFailureResponse((BError) inboundMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR));
        }
        return false;
    }

    private static int getResponseInterceptorIndex(HttpCarbonMessage inboundMessage, int interceptorsCount) {
        if (inboundMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX) != null) {
            return (int) inboundMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX);
        } else if (inboundMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX) != null) {
            return (int) inboundMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX) - 1;
        } else {
            return interceptorsCount - 1;
        }
    }

    private static void startInterceptResponseMethod(HttpCarbonMessage inboundMessage, BObject outboundResponseObj,
                                                     BObject callerObj, InterceptorService service, Environment env,
                                                     HTTPInterceptorServicesRegistry interceptorServicesRegistry,
                                                     DataContext dataContext) {
        BObject serviceObj = service.getBalService();
        Runtime runtime = interceptorServicesRegistry.getRuntime();
        Object[] signatureParams = HttpDispatcher.getRemoteSignatureParameters(service, outboundResponseObj, callerObj,
                                   inboundMessage, runtime);
        HttpResponseInterceptorUnitCallback callback = new HttpResponseInterceptorUnitCallback(inboundMessage,
                callerObj, outboundResponseObj,
                env, dataContext, runtime, interceptorServicesRegistry.isPossibleLastInterceptor());

        inboundMessage.removeProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
        String methodName = service.getServiceType().equals(HttpConstants.RESPONSE_ERROR_INTERCEPTOR)
                            ? HttpConstants.INTERCEPT_RESPONSE_ERROR : HttpConstants.INTERCEPT_RESPONSE;
        try {
            Object result = runtime.call(serviceObj, methodName, signatureParams);
            callback.handleResult(result);
        } catch (BError bError) {
            callback.handlePanic(bError);
        }
    }
}
