/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
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
    private static final String REL_PARAM = "rel=\"service-desc\"";

    protected HttpIntrospectionResource(HttpService httpService) {
        String path = (httpService.getBasePath() + SINGLE_SLASH + RESOURCE_NAME).replaceAll("/+", SINGLE_SLASH);
        httpService.setIntrospectionResourcePathHeaderValue("<" + path + ">;" + REL_PARAM);
    }

    public String getName() {
        return "$default$" + RESOURCE_NAME;
    }

    public String getPath() {
        return SINGLE_SLASH + RESOURCE_NAME;
    }

    public String getPayload() {
        String USER_DIR = System.getProperty("user.dir");
        Paths.get(USER_DIR, "src", "test", "resources", "config_files");
        InputStream resourceAsStream = HttpIntrospectionResource.class.getResourceAsStream("/META-INF/doc.yaml");
        Objects.requireNonNull(resourceAsStream, "Properties file open failed.");
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int length = 0;
        while (true) {
            try {
                if (!((length = resourceAsStream.read(buffer)) != -1)) break;
            } catch (IOException e) {
                e.printStackTrace();
            }
            result.write(buffer, 0, length);
        }
        try {
            System.out.println(result.toString(StandardCharsets.UTF_8.name()));
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }

        return "{\"name\": \"chamil\"}";
    }

    public String getError() {
        return null;
    }

    public List<String> getMethods() {
        return null;
    }

    public List<String> getConsumes() {
        return null;
    }

    public List<String> getProduces() {
        return null;
    }

    public List<String> getProducesSubTypes() {
        return null;
    }
}
