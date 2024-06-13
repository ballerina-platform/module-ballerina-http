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

import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.util.CharsetUtil;

/**
 * {@code HttpSwaggerUiResource} is the resource which respond the Swagger-UI for the generated Open API specification.
 *
 * @since v2.11.2
 */
public class HttpSwaggerUiResource extends HttpOASResource {

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
                          spec: OPENAPI_SPEC,
                          dom_id: '#swagger-ui',
                        });
                      };
                    </script>
                    </body>
                    </html>
            """;
    private static final String RESOURCE_NAME = "swagger-ui-dygixywsw";
    private static final String OAS_PLACEHOLDER = "OPENAPI_SPEC";
    private final byte[] payload;

    public HttpSwaggerUiResource(HttpService httpService, byte[] payload) {
        super(httpService, RESOURCE_NAME);
        String oasSpec = new String(payload.clone(), CharsetUtil.UTF_8);
        String content = STATIC_HTML_PAGE.replace(OAS_PLACEHOLDER, oasSpec);
        this.payload = content.getBytes(CharsetUtil.UTF_8);
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
        return HttpHeaderValues.TEXT_HTML.toString();
    }

    public static String getSwaggerUiResourceId() {
        return RESOURCE_METHOD + RESOURCE_NAME;
    }
}
