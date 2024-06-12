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

import io.netty.util.CharsetUtil;

import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.SINGLE_SLASH;

/**
 * {@code HttpIntrospectionResource} is the resource which respond the service Open API JSON specification.
 *
 * @since v2.11.2
 */
public class HttpSwaggerUiResource extends HttpResource {

    private static final String STATIC_HTML_PAGE = """
                    <!DOCTYPE html>
                    <html lang="en">
                    <head>
                      <meta charset="utf-8" />
                      <meta name="viewport" content="width=device-width, initial-scale=1" />
                      <meta name="description" content="SwaggerUI" />
                      <title>SwaggerUI</title>
                      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
                    </head>
                    <body>
                    <div id="swagger-ui"></div>
                    <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js" crossorigin></script>
                    <script>
                      window.onload = () => {
                        window.ui = SwaggerUIBundle({
                          spec: OPEN_API_SPEC,
                          dom_id: '#swagger-ui',
                        });
                      };
                    </script>
                    </body>
                    </html>
            """;
    private static final String RESOURCE_NAME = "swagger-ui-dygixywsw";
    private static final String RESOURCE_METHOD = "$get$";
    private static final String REL_PARAM = "rel=\"service-desc\"";

    private final byte[] payload;

    public HttpSwaggerUiResource(HttpService httpService, byte[] payload) {
//        String path = (httpService.getBasePath() + SINGLE_SLASH + RESOURCE_NAME).replaceAll("/+", SINGLE_SLASH);
//        httpService.setIntrospectionResourcePathHeaderValue("<" + path + ">;" + REL_PARAM);
        String oasSpec = new String(payload.clone(), CharsetUtil.UTF_8);
        String content = STATIC_HTML_PAGE.replace("OPEN_API_SPEC", oasSpec);
        this.payload = content.getBytes(CharsetUtil.UTF_8);
    }

    public String getName() {
        return RESOURCE_METHOD + RESOURCE_NAME;
    }

    public String getPath() {
        return SINGLE_SLASH + RESOURCE_NAME;
    }

    public byte[] getPayload() {
        return this.payload.clone();
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
