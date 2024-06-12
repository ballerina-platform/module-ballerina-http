/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipeliningHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.URITemplateException;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;

import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_RESOURCE_DISPATCHING_SERVER_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_RESOURCE_NOT_FOUND_ERROR;

/**
 * Resource level dispatchers handler for HTTP protocol.
 */
public class ResourceDispatcher {

    public static Resource findResource(Service service, HttpCarbonMessage inboundRequest) {

        String method = inboundRequest.getHttpMethod();
        String subPath = (String) inboundRequest.getProperty(HttpConstants.SUB_PATH);
        subPath = sanitizeSubPath(subPath);
        HttpResourceArguments resourceArgumentValues = new HttpResourceArguments();
        try {
            Resource resource = service.getUriTemplate().matches(subPath, resourceArgumentValues, inboundRequest);
            if (resource instanceof HttpIntrospectionResource) {
                handleIntrospectionRequest(inboundRequest, (HttpIntrospectionResource) resource);
                return null;
            }
            if (resource instanceof HttpSwaggerUiResource swaggerUiResource) {
                handleSwaggerUiRequest(inboundRequest, swaggerUiResource);
                return null;
            }
            if (resource != null) {
                inboundRequest.setProperty(HttpConstants.RESOURCE_ARGS, resourceArgumentValues);
                inboundRequest.setProperty(HttpConstants.RESOURCES_CORS, resource.getCorsHeaders());
                return resource;
            } else {
                if (method.equals(HttpConstants.HTTP_METHOD_OPTIONS)) {
                    handleOptionsRequest(inboundRequest, service);
                } else {
                    String message = "no matching resource found for path : " +
                            inboundRequest.getProperty(HttpConstants.TO) + " , method : " + method;
                    throw HttpUtil.createHttpStatusCodeError(INTERNAL_RESOURCE_NOT_FOUND_ERROR, message);
                }
                return null;
            }
        } catch (URITemplateException e) {
            throw HttpUtil.createHttpStatusCodeError(INTERNAL_RESOURCE_DISPATCHING_SERVER_ERROR, e.getMessage());
        }
    }

    private static String sanitizeSubPath(String subPath) {
        if ("/".equals(subPath)) {
            return subPath;
        }
        if (!subPath.startsWith("/")) {
            subPath = HttpConstants.DEFAULT_BASE_PATH + subPath;
        }
        subPath = subPath.endsWith("/") ? subPath.substring(0, subPath.length() - 1) : subPath;
        return subPath;
    }

    private static void handleOptionsRequest(HttpCarbonMessage cMsg, Service service) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        if (cMsg.getHeader(HttpHeaderNames.ALLOW.toString()) != null) {
            response.setHeader(HttpHeaderNames.ALLOW.toString(), cMsg.getHeader(HttpHeaderNames.ALLOW.toString()));
        } else if (service.getBasePath().equals(cMsg.getProperty(HttpConstants.TO))
                && !service.getAllAllowedMethods().isEmpty()) {
            response.setHeader(HttpHeaderNames.ALLOW.toString(),
                               DispatcherUtil.concatValues(service.getAllAllowedMethods(), false));
        } else {
            String message = "no matching resource found for path : " + cMsg.getProperty(HttpConstants.TO)
                    + " , method : OPTIONS";
            throw HttpUtil.createHttpStatusCodeError(INTERNAL_RESOURCE_NOT_FOUND_ERROR, message);
        }
        CorsHeaderGenerator.process(cMsg, response, false);
        String introspectionResourcePathHeaderValue = service.getIntrospectionResourcePathHeaderValue();
        if (introspectionResourcePathHeaderValue != null) {
            response.setHeader(HttpConstants.LINK_HEADER, introspectionResourcePathHeaderValue);
        }
        response.setHttpStatusCode(204);
        response.addHttpContent(new DefaultLastHttpContent());
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
        cMsg.waitAndReleaseAllEntities();
    }

    private static void handleIntrospectionRequest(HttpCarbonMessage cMsg, HttpIntrospectionResource resource) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        response.waitAndReleaseAllEntities();
        response.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(resource.getPayload())));
        response.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), HttpHeaderValues.APPLICATION_JSON.toString());
        response.setHttpStatusCode(200);
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
        cMsg.waitAndReleaseAllEntities();
    }

    private static void handleSwaggerUiRequest(HttpCarbonMessage cMsg, HttpSwaggerUiResource resource) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        response.waitAndReleaseAllEntities();
        response.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(resource.getPayload())));
        response.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), HttpHeaderValues.TEXT_HTML.toString());
        response.setHttpStatusCode(200);
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
        cMsg.waitAndReleaseAllEntities();
    }

    private ResourceDispatcher() {
    }
}
