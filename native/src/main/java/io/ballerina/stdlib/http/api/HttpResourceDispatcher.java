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
import io.ballerina.stdlib.http.uri.URITemplateException;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;

import java.nio.charset.StandardCharsets;

/**
 * Resource level dispatchers handler for HTTP protocol.
 */
public class HttpResourceDispatcher {

    public static HttpResource findResource(HttpService service, HttpCarbonMessage inboundRequest) {

        String method = inboundRequest.getHttpMethod();
        String subPath = (String) inboundRequest.getProperty(HttpConstants.SUB_PATH);
        subPath = sanitizeSubPath(subPath);
        HttpResourceArguments resourceArgumentValues = new HttpResourceArguments();
        try {
            HttpResource resource = service.getUriTemplate().matches(subPath, resourceArgumentValues, inboundRequest);
            if (resource instanceof HttpIntrospectionResource) {
                handleIntrospectionRequest(inboundRequest, (HttpIntrospectionResource) resource);
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
                    inboundRequest.setHttpStatusCode(404);
                    throw new BallerinaConnectorException("no matching resource found for path : "
                            + inboundRequest.getProperty(HttpConstants.TO) + " , method : " + method);
                }
                return null;
            }
        } catch (URITemplateException e) {
            throw new BallerinaConnectorException(e.getMessage());
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

    private static void handleOptionsRequest(HttpCarbonMessage cMsg, HttpService service) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        if (cMsg.getHeader(HttpHeaderNames.ALLOW.toString()) != null) {
            response.setHeader(HttpHeaderNames.ALLOW.toString(), cMsg.getHeader(HttpHeaderNames.ALLOW.toString()));
        } else {
            cMsg.setHttpStatusCode(404);
            throw new BallerinaConnectorException("no matching resource found for path : "
                    + cMsg.getProperty(HttpConstants.TO) + " , method : " + "OPTIONS");
        }
        CorsHeaderGenerator.process(cMsg, response, false);
        response.setHeader(HttpConstants.LINK_HEADER, service.getIntrospectionResourcePathHeaderValue());
        response.setHttpStatusCode(204);
        response.addHttpContent(new DefaultLastHttpContent());
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
        cMsg.waitAndReleaseAllEntities();
    }

    private static void handleIntrospectionRequest(HttpCarbonMessage cMsg, HttpIntrospectionResource resource) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        response.waitAndReleaseAllEntities();
        if (resource.getPayload() == null) {
            cMsg.setHttpStatusCode(500);
            throw new BallerinaConnectorException("Error retrieving OpenAPI doc: " + resource.getError());
        }
        response.setHttpStatusCode(200);
        byte[] byteArray = resource.getPayload().getBytes(StandardCharsets.UTF_8);
        response.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(byteArray)));
        response.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), HttpHeaderValues.APPLICATION_JSON.toString());
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
    }

    private HttpResourceDispatcher() {
    }
}
