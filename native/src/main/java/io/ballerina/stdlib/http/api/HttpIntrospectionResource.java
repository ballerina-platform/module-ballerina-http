/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.api;

import io.netty.handler.codec.http.HttpHeaderValues;

/**
 * {@code HttpIntrospectionResource} is the resource which respond the service Open API JSON specification.
 *
 * @since SL beta 3
 */
public class HttpIntrospectionResource extends HttpOASResource {

    private static final String RESOURCE_NAME = "openapi-doc-dygixywsw";
    private static final String REL_PARAM = "rel=\"service-desc\"";
    private final byte[] payload;

    public HttpIntrospectionResource(HttpService httpService, byte[] payload) {
        super(httpService, REL_PARAM, RESOURCE_NAME);
        this.payload = payload;
    }

    @Override
    public byte[] getPayload() {
        return this.payload.clone();
    }

    @Override
    protected String getResourceName() {
        return RESOURCE_NAME;
    }

    @Override
    public String getContentType() {
        return HttpHeaderValues.APPLICATION_JSON.toString();
    }

    public static String getResourceId() {
        return String.format("%s%s", RESOURCE_METHOD, RESOURCE_NAME);
    }
}
