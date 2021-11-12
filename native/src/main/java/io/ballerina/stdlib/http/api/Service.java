/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.URITemplate;
import io.ballerina.stdlib.http.uri.URITemplateException;

import java.util.List;

/**
 * Interface for HTTP Service classes.
 */
public interface Service {
    BMap<BString, Object> getCompressionConfig();

    String getChunkingConfig();

    String getMediaTypeSubtypePrefix();

    URITemplate<Resource, HttpCarbonMessage> getUriTemplate() throws URITemplateException;

    String getBasePath();

    List<String> getAllAllowedMethods();

    String getIntrospectionResourcePathHeaderValue();
}
