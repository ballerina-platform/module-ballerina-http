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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Objects;

import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;

/**
 * {@code HttpIntrospectionResource} is the resource which respond the service Open API JSON specification.
 *
 * @since SL beta 3
 */
public class HttpIntrospectionResource extends HttpResource {

    private static final String RESOURCE_NAME = "openapi-doc-dygixywsw";
    private static final String RESOURCE_METHOD = "$get$";
    private static final String REL_PARAM = "rel=\"service-desc\"";
    private static final String ERROR_PREFIX = "Error retrieving OpenAPI spec: ";
    private final String filePath;

    protected HttpIntrospectionResource(HttpService httpService, String filePath) {
        String path = (httpService.getBasePath() + SINGLE_SLASH + RESOURCE_NAME).replaceAll("/+", SINGLE_SLASH);
        httpService.setIntrospectionResourcePathHeaderValue("<" + path + ">;" + REL_PARAM);
        this.filePath = filePath;
    }

    public String getName() {
        return RESOURCE_METHOD + RESOURCE_NAME;
    }

    public String getPath() {
        return SINGLE_SLASH + RESOURCE_NAME;
    }

    public byte[] getPayload() {
        ByteArrayOutputStream result;
        try (InputStream inputStream = HttpIntrospectionResource.class.getClassLoader().getResourceAsStream(filePath)) {
            Objects.requireNonNull(inputStream, ERROR_PREFIX + "generated doc does not exist");

            result = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                result.write(buffer, 0, length);
            }
        } catch (IOException e) {
            throw HttpUtil.createHttpError(ERROR_PREFIX + e.getMessage(), HttpErrorType.GENERIC_LISTENER_ERROR);
        }
        return result.toByteArray();
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

    public static String getIntrospectionResourceId() {
        return RESOURCE_METHOD + RESOURCE_NAME;
    }
}
