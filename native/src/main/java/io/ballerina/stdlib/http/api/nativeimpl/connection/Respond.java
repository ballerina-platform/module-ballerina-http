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
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.client.caching.ResponseCacheControlObj;
import io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipelinedResponse;
import io.ballerina.stdlib.http.api.util.CacheUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_KEY_HTTP_STATUS_CODE;
import static io.ballerina.stdlib.http.api.HttpConstants.OBSERVABILITY_CONTEXT_PROPERTY;
import static io.ballerina.stdlib.http.api.HttpConstants.RESPONSE_CACHE_CONTROL_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.RESPONSE_STATUS_CODE_FIELD;
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

    public static Object nativeRespond(Environment env, BObject connectionObj, BObject outboundResponseObj) {
        HttpCarbonMessage inboundRequestMsg = HttpUtil.getCarbonMsg(connectionObj, null);
        DataContext dataContext = new DataContext(env, inboundRequestMsg);
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
            dataContext.getFuture().complete(e);
        } catch (Throwable e) {
            //Exception is already notified by http transport.
            String errorMessage = "Couldn't complete outbound response: " + e != null ? e.getMessage() : "";
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
}
