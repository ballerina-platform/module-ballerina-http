/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
package io.ballerina.stdlib.http.api;

import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;

/**
 * {@code HttpOASResource} is the super class for the service introspection resources.
 *
 * @since v2.11.2
 */
public abstract class HttpOASResource extends HttpResource {
    protected static final String RESOURCE_METHOD = "$get$";

    public HttpOASResource(HttpService httpService, String rel, String resourcePath) {
        String path = (httpService.getBasePath() + SINGLE_SLASH + resourcePath).replaceAll("/+", SINGLE_SLASH);
        httpService.addOasResourceLink("<" + path + ">;" + rel);
    }

    public String getName() {
        return String.format("%s%s", RESOURCE_METHOD, getResourceName());
    }

    public String getPath() {
        return String.format("%s%s", SINGLE_SLASH, getResourceName());
    }

    public List<String> getMethods() {
        return List.of(HttpConstants.HTTP_METHOD_GET);
    }

    public List<String> getConsumes() {
        return null;
    }

    public List<String> getProduces() {
        return null;
    }

    protected abstract String getResourceName();

    public abstract byte[] getPayload();

    public abstract String getContentType();
}
